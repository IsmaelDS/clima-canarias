require "test_helper"

class StationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @station = stations(:one)
  end

  test "should get index" do
    get stations_url
    assert_response :success
  end

  test "should get new" do
    get new_station_url
    assert_response :success
  end

  test "should create station" do
    assert_difference("Station.count") do
      post stations_url, params: { station: { altitude: @station.altitude, code: @station.code, latitude: @station.latitude, longitude: @station.longitude, name: @station.name, province: @station.province, synop_code: @station.synop_code } }
    end

    assert_redirected_to station_url(Station.last)
  end

  test "should show station" do
    get station_url(@station)
    assert_response :success
  end

  test "should get edit" do
    get edit_station_url(@station)
    assert_response :success
  end

  test "should update station" do
    patch station_url(@station), params: { station: { altitude: @station.altitude, code: @station.code, latitude: @station.latitude, longitude: @station.longitude, name: @station.name, province: @station.province, synop_code: @station.synop_code } }
    assert_redirected_to station_url(@station)
  end

  test "should destroy station" do
    assert_difference("Station.count", -1) do
      delete station_url(@station)
    end

    assert_redirected_to stations_url
  end
end
