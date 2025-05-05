json.extract! weather_observation, :id, :weather_station_id, :date, :avg_temp, : , :created_at, :updated_at
json.url weather_observation_url(weather_observation, format: :json)
