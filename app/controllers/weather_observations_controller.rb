class WeatherObservationsController < ApplicationController
  before_action :set_weather_observation, only: %i[ show edit update destroy ]

  # GET /weather_observations or /weather_observations.json
  def index
    @weather_observations = WeatherObservation.all
  end

  # GET /weather_observations/1 or /weather_observations/1.json
  def show
  end

  # GET /weather_observations/new
  def new
    @weather_observation = WeatherObservation.new
  end

  # GET /weather_observations/1/edit
  def edit
  end

  # POST /weather_observations or /weather_observations.json
  def create
    @weather_observation = WeatherObservation.new(weather_observation_params)

    respond_to do |format|
      if @weather_observation.save
        format.html { redirect_to @weather_observation, notice: "Weather observation was successfully created." }
        format.json { render :show, status: :created, location: @weather_observation }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @weather_observation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /weather_observations/1 or /weather_observations/1.json
  def update
    respond_to do |format|
      if @weather_observation.update(weather_observation_params)
        format.html { redirect_to @weather_observation, notice: "Weather observation was successfully updated." }
        format.json { render :show, status: :ok, location: @weather_observation }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @weather_observation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /weather_observations/1 or /weather_observations/1.json
  def destroy
    @weather_observation.destroy!

    respond_to do |format|
      format.html { redirect_to weather_observations_path, status: :see_other, notice: "Weather observation was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_weather_observation
      @weather_observation = WeatherObservation.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def weather_observation_params
      params.expect(weather_observation: [ :weather_station_id, :date, :avg_temp, :  ])
    end
end
