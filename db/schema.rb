# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_05_05_175219) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "stations", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.string "province"
    t.integer "altitude"
    t.string "latitude"
    t.string "longitude"
    t.string "synop_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "weather_observations", force: :cascade do |t|
    t.bigint "station_id", null: false
    t.date "date", null: false
    t.decimal "avg_temp"
    t.decimal "precipitation"
    t.decimal "min_temp"
    t.string "min_temp_time"
    t.decimal "max_temp"
    t.string "max_temp_time"
    t.integer "wind_direction"
    t.decimal "avg_wind_speed"
    t.decimal "wind_gust"
    t.string "wind_gust_time"
    t.integer "avg_humidity"
    t.integer "max_humidity"
    t.string "max_humidity_time"
    t.integer "min_humidity"
    t.string "min_humidity_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["station_id"], name: "index_weather_observations_on_station_id"
  end

  add_foreign_key "weather_observations", "stations"
end
