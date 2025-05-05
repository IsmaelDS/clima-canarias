require "test_helper"

class WeatherObservationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @weather_observation = weather_observations(:one)
  end

  test "should get index" do
    get weather_observations_url
    assert_response :success
  end

  test "should get new" do
    get new_weather_observation_url
    assert_response :success
  end

  test "should create weather_observation" do
    assert_difference("WeatherObservation.count") do
      post weather_observations_url, params: { weather_observation: {  : @weather_observation. , avg_temp: @weather_observation.avg_temp, date: @weather_observation.date, weather_station_id: @weather_observation.weather_station_id } }
    end

    assert_redirected_to weather_observation_url(WeatherObservation.last)
  end

  test "should show weather_observation" do
    get weather_observation_url(@weather_observation)
    assert_response :success
  end

  test "should get edit" do
    get edit_weather_observation_url(@weather_observation)
    assert_response :success
  end

  test "should update weather_observation" do
    patch weather_observation_url(@weather_observation), params: { weather_observation: {  : @weather_observation. , avg_temp: @weather_observation.avg_temp, date: @weather_observation.date, weather_station_id: @weather_observation.weather_station_id } }
    assert_redirected_to weather_observation_url(@weather_observation)
  end

  test "should destroy weather_observation" do
    assert_difference("WeatherObservation.count", -1) do
      delete weather_observation_url(@weather_observation)
    end

    assert_redirected_to weather_observations_url
  end
end
