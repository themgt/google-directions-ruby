# encoding: UTF-8
require 'cgi'
require 'json'
require 'net/http'
require 'open-uri'

class GoogleDirections
  attr_reader :status, :directions, :json, :origin, :destination, :options
  @@base_url = 'https://maps.googleapis.com/maps/api/directions/json'
  @@default_options = {
    :language => :en,
    :alternative => :true,
    :sensor => :false,
    :mode => :driving,
  }
#transcribe is ripe for an update to be done at time of request
  def initialize(origin = "", destination = "", opts={})
    @origin = origin
    @destination = destination
    @waypoints = []
    @options = opts.merge(@@default_options)
                   .merge({:origin => transcribe(@origin), :destination => transcribe(@destination)})
  end

  def update_origin address
    @options[:origin] = transcribe address
  end

  def update_destination address
    @options[:destination] = transcribe address
  end

  def add_waypoint address
    clean_address = transcribe address
    @waypoints << clean_address
  end

  def get_waypoints
    @waypoints.join("|")
  end

  def get_directions
    @options[:waypoints] = get_waypoints unless @waypoints.empty?
    @url = @@base_url + '?' + @options.to_query
    @directions = JSON.parse open(@url).read
    @status = @directions['status']
  end

  def get_overview_polyline
    @directions['overview_polyline']['points']
  end

  def get_legs
    @directions['leg']
  end

  def get_steps leg = nil
    if @status == 'OK'
      steps = @directions['routes'].first['legs'].first['steps'] if leg.nil?
      steps = leg['steps'] unless leg.nil?
    else
      steps = []
    end
    steps
  end

  def get_leg_polyline leg
    polylines = []
    leg['steps'].each do |step|
      polylines << step['polyline']['points']
    end
    polylines
  end

  def get_leg_polyline_url_part leg
    polylines = get_leg_polyline leg
    url_part = ""
    polylines.each do |p|
      url_part += "&path=enc:" + p
    end
    url_part
  end

  def get_text_directions leg = nil
    @directions['routes'].first['legs'].first['steps'].map {|step| step['html_instructions']}.join('\n') if leg.nil?
    leg['steps'].map {|step| step['html_instructions']}.join('\n') unless leg.nil?
  end

  def json_call
    @url
  end

  # an example URL to be generated
  #https://maps.google.com/maps/api/directions/json?origin=St.+Louis,+MO&destination=Nashville,+TN&sensor=false&key=ABQIAAAAINgf4OmAIbIdWblvypOUhxSQ8yY-fgrep0oj4uKpavE300Q6ExQlxB7SCyrAg2evsxwAsak4D0Liiv

  def drive_time_in_minutes leg = nil
    if @status != "OK"
      drive_time = 0
    else
      drive_time = @directions['routes'].first['legs'].first['duration']['value'].to_i if leg.nil?
      drive_time = leg['duration']['value'].to_i unless leg.nil?
      convert_to_minutes(drive_time)
    end
  end

  # the distance.value field always contains a value expressed in meters.
  def distance leg = nil
    return @distance if @distance
    unless @status == 'OK'
      @distance = 0
    else
      @distance = @directions['routes'].first['legs'].first['distance']['value'].to_i if leg.nil?
      @distance = leg['distance']['value'].to_i unless leg.nil?
    end
    @distance
  end

  def distance_text leg = nil
    return @distance_text if @distance_text
    unless @status == 'OK'
      @distance_text = "0 km"
    else
      @distance_text = @directions['routes'].first['legs'].first['distance']['text'] if leg.nil?
      @distance_text = leg['distance']['text'] unless leg.nil?
    end
    @distance_text
  end

  def distance_in_miles
    if @status != "OK"
      distance_in_miles = 0
    else
      meters = distance
      distance_in_miles = (meters.to_f / 1610.22).round
    end
    distance_in_miles
  end

  def public_url
    "http://maps.google.com/maps?saddr=#{transcribe(@origin)}&daddr=#{transcribe(@destination)}&hl=#{@options[:language]}&ie=UTF8"
  end

  private

    def convert_to_minutes(text)
      (text.to_f / 60).round
    end

    def transcribe(location)
      CGI::escape(location)
    end

end

class Hash
  def to_query
    params = ''
#should there be some url encoding going on?
    each do |k, v|
      params << "#{k}=#{v}&"
    end

    params.chop! # trailing &
    params
  end unless method_defined? :to_query
end
