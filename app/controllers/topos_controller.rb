class ToposController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]

  def index
    if params[:query].present?
      @topos = Topo.search_by_topo_and_river(params[:query])

    else
      find_topo_by_address
      @topos = Topo.all if @topos.count.zero?
    end

    if params[:levels].present?
      @topos = @topos.levels(params[:levels])
    end
  end

  def toggle_favorite
    topo = Topo.find(params[:id])

    @fav = Favorite.find_by(user: current_user, topo: topo)
    if @fav
      @fav.destroy
    else
      @fav = Favorite.create(user: current_user, topo: topo)
    end
    redirect_to topo_path(params[:id])
  end

  def show
    @topo = Topo.find(params[:id])
    @departure = Address.find(@topo.departure_id)
    @arrival = Address.find(@topo.arrival_id)

    @comments = Comment.where(topo: @topo).sort_by(&:updated_at).reverse
    @alerts_count = @comments.select { |comment| comment.category == 'alert' && comment.active == true }.count
    @favorite = Favorite.where(user: current_user, topo: @topo).exists?
  end

  def river_data
    @topo = Topo.find(params[:id])

    stats = StatsForRiver.call(@topo.river)

    data = stats.each do |station|
      station[:data] = station[:data].map { |set| [set[:date], set[:level]] }.to_h
    end
    render json: data.to_json
  end

  private

  def find_topo_by_address
    ip = request.remote_ip
    ip = `curl http://ipecho.net/plain` if ip == "::1"
    address = Geocoder.search(ip)
    topo_addresses = Address.near("#{address[0].city}, #{address[0].country}", 100)
    @topos = []
    topo_addresses.each do |topo_address|
      sql_query = "departure_id = #{topo_address.id} OR arrival_id = #{topo_address.id}"
      topo = Topo.where(sql_query)
      @topos << topo[0]
    end
  end
end

  # def water_data
  #   series_a = {
  #     "2021-08-31 07:05:00" => 30,
  #     "2021-08-31 08:05:00" => 100,
  #     "2021-08-31 09:05:00" => 80,
  #   }
  #   series_b = {
  #     "2021-08-31 07:05:00" => 100,
  #     "2021-08-31 08:05:00" => 10,
  #     "2021-08-31 09:05:00" => 8,
  #   }
  #   data = [
  #     {name: "Station A", data: series_a, color: "orange"},
  #     {name: "Station B", data: series_b, color: "black"}
  #   ]
  #   ap data
  #   return data
  # end
