Gem::Specification.new do |spec|  
  spec.name        = 'google_directions'  
  spec.version     = '0.2.0'
  spec.files       = Dir['lib/**/*', 'test/**/*', 'README.textile', 'Gemfile', 'init.rb', 'Manifest', 'Rakefile']
  
  spec.summary     = 'Class for retrieving directions from the Google Directions API service'
  spec.description = "Easily retrieve turn-by-turn directions, polylines, and distances from Google using just addresses. Also supports waypoints."
  
  spec.authors           = 'Josh Crews, Danny Summerlin'  
  spec.email             = 'hello@craftedbycreo.com'
  spec.homepage          = 'http://www.craftedbycreo.com/'
  
  spec.add_runtime_dependency 'nokogiri', '~>1.6.0'
end
