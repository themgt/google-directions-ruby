# encoding: UTF-8
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))

# TODO: mocks
class GoogleDirectionsTest < Test::Unit::TestCase

  def test_happy_case
    orig = "121 Gordonsville Highway, 37030"
    dest = "499 Gordonsville Highway, 38563"
    google = GoogleDirections.new(orig, dest)
    google.get_directions
    assert_equal(4, google.distance_in_miles)
    assert_equal(5, google.drive_time_in_minutes)
    assert_equal('https://maps.googleapis.com/maps/api/directions/json?language=en&alternative=true&sensor=false&mode=driving&origin=121+Gordonsville+Highway%2C+37030&destination=499+Gordonsville+Highway%2C+38563', google.json_call)

    assert_equal orig, google.origin
    assert_equal dest, google.destination
  end

  def test_google_not_found
    google = GoogleDirections.new("fasfefasdfdfsd", "499 Gordonsville Highway, 38563")
    google.get_directions
    assert_equal(0, google.distance_in_miles)
    assert_equal(0, google.drive_time_in_minutes)
    assert_equal("NOT_FOUND", google.status)
  end

  def test_zero_results
    google = GoogleDirections.new("27 Beemdenlaan, 2550 Kontich", "499 Gordonsville Highway, 38563")
    google.get_directions
    assert_equal(0, google.distance_in_miles)
    assert_equal(0, google.drive_time_in_minutes)
    assert_equal("ZERO_RESULTS", google.status)
  end

  def test_french_direction
    assert_nothing_raised do
      # URI::InvalidURIError
      google = GoogleDirections.new("15 rue poissonnière, 75002 Paris", "169 11th Street CA 94103 San Francisco United States")
      google.get_directions
      google
    end
  end

  def test_get_steps
    google = GoogleDirections.new("rue poissonnière, 75002 Paris", "51 rue de Turbigo, 75003 Paris France")
    google.get_directions
    assert_equal Array, google.get_steps.class
    assert_equal 5, google.get_steps.size
  end

  def test_distance_text
    google = GoogleDirections.new("Place du Maquis du Vercors PARIS-19EME", "rue poissoniere 75002 paris")
    google.get_directions
    assert_equal String, google.distance_text.class
    assert_equal "6.3 km", google.distance_text
  end

  def test_zero_distance_text
    google = GoogleDirections.new("27 Beemdenlaan, 2550 Kontich", "499 Gordonsville Highway, 38563")
    google.get_directions
    assert_equal "0 km", google.distance_text
  end
end
