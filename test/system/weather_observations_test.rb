require "application_system_test_case"

class WeatherObservationsTest < ApplicationSystemTestCase
  setup do
    @weather_observation = weather_observations(:one)
  end

  test "visiting the index" do
    visit weather_observations_url
    assert_selector "h1", text: "Weather observations"
  end

  test "should create weather observation" do
    visit weather_observations_url
    click_on "New weather observation"

    fill_in "", with: @weather_observation. 
    fill_in "Avg temp", with: @weather_observation.avg_temp
    fill_in "Date", with: @weather_observation.date
    fill_in "Weather station", with: @weather_observation.weather_station_id
    click_on "Create Weather observation"

    assert_text "Weather observation was successfully created"
    click_on "Back"
  end

  test "should update Weather observation" do
    visit weather_observation_url(@weather_observation)
    click_on "Edit this weather observation", match: :first

    fill_in "", with: @weather_observation. 
    fill_in "Avg temp", with: @weather_observation.avg_temp
    fill_in "Date", with: @weather_observation.date
    fill_in "Weather station", with: @weather_observation.weather_station_id
    click_on "Update Weather observation"

    assert_text "Weather observation was successfully updated"
    click_on "Back"
  end

  test "should destroy Weather observation" do
    visit weather_observation_url(@weather_observation)
    click_on "Destroy this weather observation", match: :first

    assert_text "Weather observation was successfully destroyed"
  end
end
