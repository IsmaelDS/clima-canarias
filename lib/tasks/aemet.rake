namespace :aemet do
  desc "Descarga observaciones históricas por grupo (20 estaciones por grupo)"
  task :fetch_group, [:index] => :environment do |_, args|
    i = args[:index].to_i
    puts "[AEMET][TAREA] Procesando grupo ##{i}..."
    AemetApiClient.new.fetch_historical_laspalmas_group(i)
  end
end
