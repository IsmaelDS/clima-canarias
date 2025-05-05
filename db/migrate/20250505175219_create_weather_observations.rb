class CreateWeatherObservations < ActiveRecord::Migration[8.0]
  def change
    create_table :weather_observations do |t|
      t.references :station, null: false, foreign_key: true

      t.date    :date, null: false
      t.decimal :avg_temp
      t.decimal :precipitation
      t.decimal :min_temp
      t.string  :min_temp_time
      t.decimal :max_temp
      t.string  :max_temp_time

      t.integer :wind_direction
      t.decimal :avg_wind_speed
      t.decimal :wind_gust
      t.string  :wind_gust_time

      t.integer :avg_humidity
      t.integer :max_humidity
      t.string  :max_humidity_time
      t.integer :min_humidity
      t.string  :min_humidity_time

      t.timestamps
    end
  end
end