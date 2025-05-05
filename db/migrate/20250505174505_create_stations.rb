class CreateStations < ActiveRecord::Migration[8.0]
  def change
    create_table :stations do |t|
      t.string :code
      t.string :name
      t.string :province
      t.integer :altitude
      t.string :latitude
      t.string :longitude
      t.string :synop_code

      t.timestamps
    end
  end
end
