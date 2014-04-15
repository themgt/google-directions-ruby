# encoding: UTF-8
require 'cgi'
require 'net/http'
require 'open-uri'
require 'nokogiri'

class GoogleDirections
  attr_reader :status, :directions, :xml, :origin, :destination, :options
  @@base_url = 'https://maps.googleapis.com/maps/api/directions/xml'
  @@default_options = {
    :language => :en,
    :alternative => :true,
    :sensor => :false,
    :mode => :driving,
  }
#transcribe is ripe for an update to be done at time of request
  def initialize(origin = "", destination = "", opts=@@default_options)
    @origin = origin
    @destination = destination
    @waypoints = []
    @options = opts.merge({:origin => transcribe(@origin), :destination => transcribe(@destination)})
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
    @options[:waypoints] = get_waypoints unless @waypoints.blank?
    @url = @@base_url + '?' + @options.to_query
    #might switch to JSON, need to see if Nokogiri or JSON is faster
    @xml = open(@url).read
    @directions = Nokogiri::XML(@xml)
    @status = @directions.css('status').text
  end

  def get_overview_polyline
    @directions.css("overview_polyline").css("points").text
  end

  def get_legs
    @directions.css("leg")
  end

  def get_steps leg = nil
    if @status == 'OK'
      @directions.css('steps') if leg.nil?
      leg.css("step") unless leg.nil?
    else
      []
    end
  end

  def get_leg_polyline leg
    polylines = []
    leg.css("step").each do |step|
      polylines << step.css("polyline").css("points").text
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

  def get_text_directions
    @directions.css("html_instructions").map { |e| e.text }
  end

  def xml_call
    @url
  end

  # an example URL to be generated
  #https://maps.google.com/maps/api/directions/xml?origin=St.+Louis,+MO&destination=Nashville,+TN&sensor=false&key=ABQIAAAAINgf4OmAIbIdWblvypOUhxSQ8yY-fgrep0oj4uKpavE300Q6ExQlxB7SCyrAg2evsxwAsak4D0Liiv

  def drive_time_in_minutes
    if @status != "OK"
      drive_time = 0
    else
      drive_time = @directions.css("duration value").last.text
      convert_to_minutes(drive_time)
    end
  end

  # the distance.value field always contains a value expressed in meters.
  def distance
    return @distance if @distance
    unless @status == 'OK'
      @distance = 0
    else
      @distance = @directions.css("distance value").last.text
    end
  end

  def distance_text
    return @distance_text if @distance_text
    unless @status == 'OK'
      @distance_text = "0 km"
    else
      @distance_text = @directions.css("distance text").last.text
    end
  end

  def distance_in_miles
    if @status != "OK"
      distance_in_miles = 0
    else
      meters = distance
      distance_in_miles = (meters.to_f / 1610.22).round
      distance_in_miles
    end
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
