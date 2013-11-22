# EmulateGoogle
#
# This module takes provides an interface that's compatible with Google's geocoding
# API. See https://developers.google.com/maps/documentation/geocoding/ for details.
#
# Copyright (C) 2012 Pete Warden <pete@petewarden.com>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'rubygems' if RUBY_VERSION < '1.9'

require 'json'
require 'uri'
require 'net/http'

WOE_TYPE_TOWN = 7
WOE_TYPE_REGION = 8
WOE_TYPE_POSTAL_CODE = 11
WOE_TYPE_COUNTRY = 12

cwd = File.expand_path(File.dirname(__FILE__))
require File.join(cwd, 'street2coordinates')

# Emulates the interface to Google's geocoding API.
def google_geocoder_api_call(params)

  format = params[:format].downcase
  address = params[:address]
  latlng = params[:latlng]
  result = nil
  if address
    result = google_style_street2coordinates(address)
    if !result
      result = google_style_twofishes(address)
    end
    if !result
      result = google_style_geodict(address)
    end
  elsif latlng
    halt 404, "Reverse geocoding not supported"    
  else
    halt 404, "Format not found"
  end

  if !result
    output = {
      'results' => [],
      'status' => 'ZERO_RESULTS',
    }
  else
    output = {
      'results' => [result],
      'status' => 'OK',
    }
  end
  
  output
end

def google_style_street2coordinates(address)
  found = street2coordinates([address])
  info = found[address]
  if !info
    return nil
  end

  lat = info[:latitude].to_f
  lon = info[:longitude].to_f
  street_number = info[:street_number]
  street_name = info[:street_name]
  locality = info[:locality]
  region = info[:region]
  country_name = info[:country_name]
  country_code = info[:country_code]
  address_components = []
  types = nil
  if street_number
    address_components << {
      'long_name' => street_number,
      'short_name' => street_number,
      'types' => ['street_number'],
    }
  end
  if street_name
    address_components << {
      'long_name' => street_name,
      'short_name' => street_name,
      'types' => ['route'],
    }
    if !types
      types = ['street_address']
    end
  end
  if locality
    address_components << {
      'long_name' => info[:locality],
      'short_name' => info[:locality],
      'types' => [ 'locality', 'political' ],
    }
    if !types
      types = ['locality', 'political']
    end
  end
  if region
    address_components << {
      'long_name' => region,
      'short_name' => region,
      'types' => ['administrative_area_level_1', 'political'],
    }
    if !types
      types = ['administrative_area_level_1', 'political']
    end
  end
  if country_name and country_code
    address_components << {
      'long_name' => country_name,
      'short_name' => country_code,
      'types' => ['country', 'political'],
    }
    if !types
      types = ['country', 'political']
    end
  end      
  result = {
    'address_components' => address_components,
    'formatted_address' => address,
    'geometry' => {
      'location' => {
        'lat' => lat,
        'lng' => lon,
      },
      'location_type' => 'ROOFTOP',
      'viewport' => {
        'northeast' => {
          'lat' => lat + 0.001,
          'lng' => lon + 0.001,
        },
        'southwest' => {
          'lat' => lat - 0.001,
          'lng' => lon - 0.001,
        },
      }
    },
    'types' => types,
  }
  result
end

def google_style_geodict(address)
  capitalized_address = address.split(' ').select {|word| word.capitalize! || word }.join(' ')
  location_string = 'at '+capitalized_address
  locations = find_locations_in_text(location_string)
  result = nil
  locations.each_with_index do |location_info, index|
    found_tokens = location_info[:found_tokens]
    match_start_index = found_tokens[0][:start_index]
    match_end_index = found_tokens[found_tokens.length-1][:end_index]
    location = get_most_specific_token(found_tokens)
    country_code = location[:country_code]
    country_name = get_country_name_from_code(country_code)
    lat = location[:lat].to_f
    lon = location[:lon].to_f
    type = location[:type]
    if type == :CITY
      bounding_range = 0.1
      type_name = 'locality'
      address_components = [
        {
          'long_name' => location[:matched_string],
          'short_name' => location[:matched_string],
          'types' => [ 'locality', 'political' ],
        },
      ]
    elsif type == :POSTAL_CODE
      bounding_range = 0.1
      type_name = 'postal_code'
      address_components = [
        {
          'long_name' => location[:matched_string],
          'short_name' => location[:code].strip,
          'types' => [ 'postal_code', 'political' ],
        },
      ]
      found_tokens.each do |token|
        if token[:type] == :CITY
          address_components <<
            {
              'long_name' => token[:matched_string],
              'short_name' => token[:matched_string],
              'types' => [ 'locality', 'political' ],
            }
        end
      end
      address_components <<
        {
          'long_name' => location[:region_code],
          'short_name' => location[:region_code].strip,
          'types' => [ 'administrative_area_level_1', 'political' ],
        }
    elsif type == :REGION
      bounding_range = 1.0
      type_name = 'administrative_area_level_1'
      address_components = [
        {
          'long_name' => location[:matched_string],
          'short_name' => location[:code].strip,
          'types' => [ 'administrative_area_level_1', 'political' ],
        },
      ]
    else
      bounding_range = 5.0
      type_name = 'country'
      address_components = []
    end
    address_components <<
      {
        'long_name' => country_name,
        'short_name' => country_code,
        'types' => [ 'country', 'political' ],
      }
    result = {
      'address_components' => address_components,
      'geometry' => {
        'location' => {
          'lat' => lat,
          'lng' => lon,
        },
        'location_type' => 'APPROXIMATE',
        'viewport' => {
          'northeast' => {
            'lat' => lat + bounding_range,
            'lng' => lon + bounding_range,
          },
          'southwest' => {
            'lat' => lat - bounding_range,
            'lng' => lon - bounding_range,
          },
        }
      },
      'types' => [ type_name, 'political' ],
    }
    break
  end
  result
end

def get_json(url)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  
  headers = {}
  request = Net::HTTP::Get.new(uri.request_uri, headers)
  
  begin
    response = http.request(request)  
    
    result_string = nil
    if response.code != '200'
      log "Bad response code #{response.status} for '#{url}'"
      result = nil
      else
      if response.header[ 'Content-Encoding' ].eql?( 'gzip' ) then
        sio = StringIO.new( response.body )
        gz = Zlib::GzipReader.new( sio )
        result_string = gz.read()
      else
        result_string = response.body
      end
    end
  rescue NoMethodError
    result_string = nil
  end

  if !result_string
    result = nil
  else
    result = JSON.parse(result_string)
  end

  result
end

def google_style_twofishes(address)
  url = 'http://localhost/twofishes?query=' + URI.encode(address)
  twofishes_data = get_json(url)
  if !twofishes_data or !twofishes_data['interpretations'] then return nil end
  interpretations = twofishes_data['interpretations']
  if interpretations.length == 0 then return nil end
  interpretation = interpretations[0]
  if !interpretation['feature'] then return nil end
  feature = interpretation['feature']
  country_code = feature['cc']
  country_name = get_country_name_from_code(country_code)

  geometry = feature['geometry']
  center = geometry['center']
  lat = center['lat']
  lon = center['lng']

  bounds = geometry['bounds']
  ne = bounds['ne']
  ne_lat = ne['lat']
  ne_lon = ne['lng']
  sw = bounds['sw']
  sw_lat = sw['lat']
  sw_lon = sw['lng']

  short_name = feature['name']
  long_name = feature['displayName']

  woe_type = feature['woeType']
  if woe_type == WOE_TYPE_TOWN
    type_name = 'locality'
    address_components = [
      {
        'long_name' => long_name,
        'short_name' => short_name,
        'types' => [ 'locality', 'political' ],
      },
    ]
  elsif woe_type == WOE_TYPE_POSTAL_CODE
    type_name = 'postal_code'
    address_components = [
      {
        'long_name' => long_name,
        'short_name' => short_name,
        'types' => [ 'postal_code', 'political' ],
      },
    ]
  elsif woe_type == WOE_TYPE_REGION
    type_name = 'administrative_area_level_1'
    address_components = [
      {
        'long_name' => long_name,
        'short_name' => short_name,
        'types' => [ 'administrative_area_level_1', 'political' ],
      },
    ]
  elsif woe_type == WOE_TYPE_COUNTRY
    type_name = 'country'
    address_components = []
  end
  address_components <<
    {
      'long_name' => country_name,
      'short_name' => country_code,
      'types' => [ 'country', 'political' ],
    }
  result = {
    'address_components' => address_components,
    'geometry' => {
      'location' => {
        'lat' => lat,
        'lng' => lon,
      },
      'location_type' => 'APPROXIMATE',
      'viewport' => {
        'northeast' => {
          'lat' => ne_lat,
          'lng' => ne_lon,
        },
        'southwest' => {
          'lat' => sw_lat,
          'lng' => sw_lon,
        },
      }
    },
    'types' => [ type_name, 'political' ],
  }
  result
end

if __FILE__ == $0

  if ARGV.length < 1
    address = '2543 Graystone Place, Simi Valley, CA 93065'
  else
    address = ARGV[0]
  end

  params = {
    :format => 'json',
    :address => address,
  }
  
  result = google_geocoder_api_call(params)
  $stderr.puts "result=#{JSON.pretty_generate(result)}"

end
