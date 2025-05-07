require 'net/http'
require 'uri'
require 'json'

class AemetApiClient
  BASE_URL = 'https://opendata.aemet.es/opendata/api'
  TOKEN = ENV['AEMET_API_KEY']

  def initialize
    raise "AEMET_API_KEY is missing. Please set it in .env or your environment." unless TOKEN
    @headers = { 'Authorization' => "Bearer #{TOKEN}" }
  end

  # Public method to start fetching stations
  def fetch_weather_stations
    puts "[AEMET] Fetching station metadata..."
    url = URI("#{BASE_URL}/valores/climatologicos/inventarioestaciones/todasestaciones")

    response = nil
    retries ||= 0

    begin
      response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
        http.get(url, @headers)
      end
    rescue EOFError, OpenSSL::SSL::SSLError => e
      if (retries += 1) <= 3
        puts "[AEMET] Conexión interrumpida. Reintentando (#{retries})..."
        sleep 1
        retry
      else
        puts "[AEMET] Falló tras varios intentos: #{e.message}"
        return
      end
    end

    unless response.is_a?(Net::HTTPSuccess)
      puts "[AEMET] ERROR #{response.code}: #{response.message}"
      return
    end

    datos_url = JSON.parse(response.body)['datos']
    stations_json = Net::HTTP.get(URI(datos_url))
    stations = JSON.parse(stations_json)

    import_stations(stations)
  end

  def fetch_historical_laspalmas_group(group_index = 0)
    group_size = 20
    puts "[AEMET] Iniciando grupo ##{group_index + 1} (estaciones #{group_size * group_index} a #{group_size * (group_index + 1) - 1})..."

    all_stations = Station.where(province: 'LAS PALMAS').order(:id)
                                 .offset(group_index * group_size).limit(group_size)

    station_dates = {}
    all_stations.each do |station|
      last_date = WeatherObservation.where(station: station).maximum(:date)
      station_dates[station.code] = last_date || Date.parse('1995-05-01') - 1
    end

    end_date = Date.parse('2025-04-30')
    overall_start_date = station_dates.values.min + 1

    while overall_start_date <= end_date
      block_end = [overall_start_date + 179, end_date].min

      eligible_codes = station_dates.select { |_code, last| last < block_end }.keys
      break if eligible_codes.empty?

      start_str = "#{overall_start_date.iso8601}T00:00:00UTC"
      end_str   = "#{block_end.iso8601}T00:00:00UTC"
      codes     = eligible_codes.join(',')

      puts "⬇️  Descargando del #{overall_start_date} al #{block_end} para estaciones: #{codes}"

      begin
        puts "🔍 1. Construyendo URI..."
        url = URI("#{BASE_URL}/valores/climatologicos/diarios/datos/fechaini/#{start_str}/fechafin/#{end_str}/estacion/#{codes}")
        puts "✅ URI construida: #{url}"

        puts "🔍 2. Realizando GET inicial..."
        response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          http.get(url, @headers)
        end
        puts "✅ GET ejecutado"

        puts "🔍 3. Parseando JSON..."
        parsed = JSON.parse(response.body)
        puts "✅ JSON parseado"

        puts "🔍 4. Comprobando estado..."
        if parsed['estado'].to_i != 200 || parsed['datos'].blank?
          puts "⚠️  Respuesta inesperada de AEMET: #{parsed.inspect}"
          sleep 60
          overall_start_date = block_end + 1
          next
        end

        puts "🔍 5. Descargando datos desde #{parsed['datos']}..."
        data_url = parsed['datos']
        # Esto evita que la conexión quede colgada o se cierre abruptamente sin gestión:
        uri = URI(data_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 10  # segundos
        http.read_timeout = 30  # segundos

        raw_response = http.get(uri.request_uri, @headers)
        body = raw_response.body

        puts "🔍 6. Verificando contenido..."
        if body.is_a?(String) && body.strip.start_with?('[', '{')
          observations = JSON.parse(body)
          import_observations(observations)
        else
          puts "⚠️  Contenido inesperado recibido: #{body.to_s[0..150]}..."
        end
      rescue => e
        puts "❌ Error real atrapado: #{e.class} - #{e.message}"
        puts e.backtrace.first(5) # opcional: primeras 5 líneas del stacktrace
      end

      overall_start_date = block_end + 1
      puts "⏱️  Esperando 60s para respetar los límites de AEMET..."
      sleep 60
    end

    puts "[AEMET] Grupo ##{group_index + 1} finalizado."
  end

  def detailed_coverage_report(province: 'LAS PALMAS', min_coverage: nil)
    start_date = Date.new(1995, 5, 1)
    end_date   = Date.new(2025, 4, 30)
    total_days = (start_date..end_date).count

    fields = %i[
    avg_temp precipitation min_temp min_temp_time max_temp max_temp_time
    wind_direction avg_wind_speed wind_gust wind_gust_time
    avg_humidity max_humidity max_humidity_time
    min_humidity min_humidity_time
  ]

    stations = Station.where(province: province).order(:id)

    puts "📊 Cobertura por campo (#{province}):\n\n"

    header = ['Code', 'Name', 'Total'] + fields.map(&:to_s)
    puts header.join("\t")

    stations.each do |station|
      observations = WeatherObservation.where(station: station)
      total = observations.count

      next if min_coverage && (total.to_f / total_days * 100) < min_coverage

      row = [station.code, station.name.tr("\n", " "), "#{total}"]

      fields.each do |field|
        count = observations.where.not(field => nil).count
        percentage = (count.to_f / total_days * 100).round(1)
        row << "#{percentage}%"
      end

      puts row.join("\t")
    end
  end

  def fill_gaps_by_station(station, start_date: nil, end_date: Date.new(2025, 4, 30))
    puts "🔎 Buscando huecos para estación #{station.code} (#{station.name})..."

    existing_dates = WeatherObservation.where(station: station).pluck(:date).uniq.sort

    if existing_dates.empty?
      puts "⚠️  Estación sin datos registrados. Posible estación nueva o inactiva."
      return
    end

    # Determinar el rango de fechas real de observación
    start_date ||= existing_dates.first
    expected_dates = (start_date..end_date).to_a
    missing_dates = expected_dates - existing_dates

    if missing_dates.empty?
      puts "✅ Sin huecos. Todo completo."
      return
    end

    missing_ranges = missing_dates.chunk_while { |a, b| b == a + 1 }
                                  .map { |chunk| chunk.first..chunk.last }

    missing_ranges.each_with_index do |range, idx|
      range.each_slice(180).with_index do |slice, subidx|
        from = slice.first
        to   = slice.last

        puts "⬇️  Rellenando bloque #{idx + 1}.#{subidx + 1}: #{from} → #{to}"
        fetch_and_import_observations(station.code, start_date: from, end_date: to)

        puts "⏱️  Esperando 60s para respetar límite AEMET..."
        sleep 60
      end
    end
  end

  def find_date_gaps_for_station(station, start_date: Date.new(1995, 5, 1), end_date: Date.new(2025, 4, 30))
    expected_dates = (start_date..end_date).to_a
    existing_dates = WeatherObservation.where(station: station).pluck(:date).uniq.sort
    missing_dates = expected_dates - existing_dates
    return [] if missing_dates.empty?

    # Agrupar fechas consecutivas en rangos
    missing_ranges = missing_dates.chunk_while { |a, b| b == a + 1 }
      .map { |chunk| chunk.first..chunk.last }

    missing_ranges
  end

  def fetch_and_import_observations(code, start_date:, end_date:)
    start_str = "#{start_date.iso8601}T00:00:00UTC"
    end_str   = "#{end_date.iso8601}T00:00:00UTC"
    url = URI("#{BASE_URL}/valores/climatologicos/diarios/datos/fechaini/#{start_str}/fechafin/#{end_str}/estacion/#{code}")

    retries ||= 0

    begin
      response = Net::HTTP.start(url.host, url.port, use_ssl: true, read_timeout: 30, open_timeout: 10) do |http|
        http.get(url, @headers)
      end

      parsed = JSON.parse(response.body)

      if parsed['estado'].to_i == 429
        raise "RateLimit429"
      end

      return unless parsed['datos']

      data_url = parsed['datos']
      raw_response = Net::HTTP.get_response(URI(data_url))
      body = raw_response.body

      if body.is_a?(String) && body.strip.start_with?('[', '{')
        observations = JSON.parse(body)
        import_observations(observations)
      else
        puts "⚠️  Contenido inesperado recibido."
      end

    rescue OpenSSL::SSL::SSLError => e
      if (retries += 1) <= 3
        puts "🔁 Error SSL. Reintentando intento ##{retries}..."
        sleep 3
        retry
      else
        puts "❌ Fallo SSL persistente: #{e.message}"
      end

    rescue => e
      if e.message == "RateLimit429"
        puts "⚠️  Límite alcanzado, esperando 60s..."
        sleep 60
        retry
      else
        puts "❌ Error inesperado: #{e.class} - #{e.message}"
      end
    end
  end

  private

  def sanitize_utf8(value)
    return nil if value.nil?
    value.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
  end

  def clean_number(value)
    return nil if value.blank?
    return nil if value.match?(/Ip|VARIAS/i)
    return nil if value.include?('//')
    value.tr(',', '.').to_f
  end

  def clean_text(value)
    return nil if value.blank? || value.strip.downcase == "varias" || value == "////"
    value.strip
  end

  def to_i_or_nil(value)
    Integer(value)
  rescue
    nil
  end


  # Create or update each station
  def import_stations(stations)
    stations.each do |data|
      station = Station.find_or_initialize_by(code: data['indicativo'])
      station.update(
        name:       sanitize_utf8(data['nombre']),
        province:   sanitize_utf8(data['provincia']),
        altitude:   data['altitud'].to_i,
        latitude:   sanitize_utf8(data['latitud']),
        longitude:  sanitize_utf8(data['longitud']),
        synop_code: sanitize_utf8(data['indsinop'])
      )
    end

    puts "[AEMET] Import completed: #{stations.size} stations processed."
  end

  def import_observations(observations)
    observations.each do |data|
      station = Station.find_by(code: data['indicativo'])
      next unless station

      WeatherObservation.find_or_initialize_by(
        station: station,
        date: data['fecha']
      ).update(
        avg_temp:         clean_number(data['tmed']),
        precipitation:    clean_number(data['prec']),
        min_temp:         clean_number(data['tmin']),
        min_temp_time:    clean_text(data['horatmin']),
        max_temp:         clean_number(data['tmax']),
        max_temp_time:    clean_text(data['horatmax']),
        wind_direction:   data['dir'].to_i,
        avg_wind_speed:   clean_number(data['velmedia']),
        wind_gust:        clean_number(data['racha']),
        wind_gust_time:   clean_text(data['horaracha']),
        avg_humidity:     to_i_or_nil(data['hrMedia']),
        max_humidity:     to_i_or_nil(data['hrMax']),
        max_humidity_time: clean_text(data['horaHrMax']),
        min_humidity:     to_i_or_nil(data['hrMin']),
        min_humidity_time: clean_text(data['horaHrMin'])
      )
    end
  end

end
