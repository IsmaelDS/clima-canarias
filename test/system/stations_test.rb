require "application_system_test_case"

class StationsTest < ApplicationSystemTestCase
  setup do
    @station = stations(:one)
  end

  test "visiting the index" do
    visit stations_url
    assert_selector "h1", text: "Stations"
  end

  test "should create station" do
    visit stations_url
    click_on "New station"

    fill_in "Altitude", with: @station.altitude
    fill_in "Code", with: @station.code
    fill_in "Latitude", with: @station.latitude
    fill_in "Longitude", with: @station.longitude
    fill_in "Name", with: @station.name
    fill_in "Province", with: @station.province
    fill_in "Synop code", with: @station.synop_code
    click_on "Create Station"

    assert_text "Station was successfully created"
    click_on "Back"
  end

  test "should update Station" do
    visit station_url(@station)
    click_on "Edit this station", match: :first

    fill_in "Altitude", with: @station.altitude
    fill_in "Code", with: @station.code
    fill_in "Latitude", with: @station.latitude
    fill_in "Longitude", with: @station.longitude
    fill_in "Name", with: @station.name
    fill_in "Province", with: @station.province
    fill_in "Synop code", with: @station.synop_code
    click_on "Update Station"

    assert_text "Station was successfully updated"
    click_on "Back"
  end

  test "should destroy Station" do
    visit station_url(@station)
    click_on "Destroy this station", match: :first

    assert_text "Station was successfully destroyed"
  end
end
