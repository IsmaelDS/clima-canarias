json.extract! station, :id, :code, :name, :province, :altitude, :latitude, :longitude, :synop_code, :created_at, :updated_at
json.url station_url(station, format: :json)
