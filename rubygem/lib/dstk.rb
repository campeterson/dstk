# Client interface to the Data Science Toolkit API
# See http://www.datasciencetoolkit.org/developerdocs for details
# By Pete Warden, pete@petewarden.com

require 'rubygems' if RUBY_VERSION < '1.9'

require 'json'
require 'httparty'
require 'httmultiparty'

module DSTK
  class DSTK
    def initialize(options = {})
      default_options = {
        :api_base => 'http://www.datasciencetoolkit.org',
        :check_version => true,
      }

      if ENV['DSTK_API_BASE']
        default_options[:api_base] = ENV['DSTK_API_BASE']
      end

      default_options.each do |key, value|
        if !options.has_key?(key)
          options[key] = value
        end
      end
          
      @dstk_api_base = options[:api_base]

      if options[:check_version]
        self.check_version()
      end
    end

    # A short-hand method to URL encode a string. See http://web.elctech.com/?p=58
    def u(str)
      str.gsub(/[^a-zA-Z0-9_\.\-]/n) {|s| sprintf('%%%02x', s[0]) }
    end

    def api_url(endpoint, arguments = {})
      api_url = @dstk_api_base + endpoint
      arguments_list = arguments.map do |name, value|
        name + '=' + URI.encode(value)
      end
      if arguments_list.length > 0
        arguments_string = '?' + arguments_list.join('&')
        api_url += arguments_string
      end

      api_url
    end

    def dstk_api_get(endpoint, arguments = {})
      response = HTTParty.get(api_url(endpoint, arguments))

      if !response.body or response.code != 200
        raise "DSTK::dstk_api_get('#{endpoint}', #{arguments.to_json}) call to '#{api_url}' failed with code #{response.code} : '#{response.message}'"
      end

      result = nil
      begin
        result = JSON.parse(response.body)
      rescue JSON::ParseError => e
        raise "DSTK::dstk_api_get('#{endpoint}', #{arguments.to_json}, '#{data_payload}', '#{data_payload_type}') call to '#{api_url}' failed to parse response '#{response.body}' as JSON - #{e.message}"
      end
      if !result.is_a?(Array) and result['error']
        raise result['error']
      end
      result
    end

    def prep_payload(data_payload, data_payload_type)
      data_payload_type == 'json' ? data_payload.to_json : data_payload
    end

    def dstk_api_post(endpoint, arguments = {}, data_payload = nil, data_payload_type = 'json')
      response = HTTParty.post(api_url(endpoint, arguments),
                               { :body => prep_payload(data_payload, data_payload_type) })

      if !response.body or response.code != 200
        raise "DSTK::dstk_api_post('#{endpoint}', #{arguments.to_json}, '#{data_payload}', '#{data_payload_type}') call to '#{api_url}' failed with code #{response.code} : '#{response.message}'"
      end

      result = nil
      begin
        result = JSON.parse(response.body)
      rescue JSON::ParseError => e
        raise "DSTK::dstk_api_post('#{endpoint}', #{arguments.to_json}, '#{data_payload}', '#{data_payload_type}') call to '#{api_url}' failed to parse response '#{response.body}' as JSON - #{e.message}"
      end
      if !result.is_a?(Array) and result['error']
        raise result['error']
      end
      result
    end

    def ensure_array(item)
      if !item.is_a?(Array)
        [item]
      else
        item
      end
    end

    ############### non data_payload requests ############
    def check_version
      required_version = 50
      response = dstk_api_get('/info')
      actual_version = response['version']
      if actual_version < required_version
        raise "DSTK: Version #{actual_version.to_s} found but #{required_version.to_s} is required"
      end
    end

    def geocode(address)
      dstk_api_get('/maps/api/geocode/json', { 'address' => address })
    end

    ############### data_payload requests ################
    def ip2coordinates(ips)
      dstk_api_post('/ip2coordinates', {}, ensure_array(ips), 'json')
    end
    def street2coordinates(addresses)
      dstk_api_post('/street2coordinates', {}, ensure_array(addresses), 'json')
    end
    def coordinates2politics(coordinates)
      dstk_api_post('/coordinates2politics', {}, coordinates, 'json')
    end
    def text2places(text)
      dstk_api_post('/text2places', {}, text, 'string')
    end
    def file2text(inputfile)
      dstk_api_post('/text2places', {}, {:inputfile => inputfile}, 'file')
    end
    def text2sentences(text)
      dstk_api_post('/text2sentences', {}, text, 'string')
    end
    def html2text(html)
      dstk_api_post('/html2text', {}, html, 'string')
    end
    # TODO: fix failing test
    def html2story(html)
      dstk_api_post('/html2story', {}, html, 'string')
    end
    # TODO: fix failing test
    def text2people(text)
      dstk_api_post('/text2people', {}, text, 'string')
    end
    def text2times(text)
      dstk_api_post('/text2times', {}, text, 'string')
    end
    def text2sentiment(text)
      dstk_api_post('/text2sentiment', {}, text, 'string')
    end
    # TODO: fix failing test
    def coordinates2statistics(coordinates, statistics = nil)
      if statistics
        if !statistics.is_a?(Array) then statistics = [statistics] end
        arguments = { 'statistics' => statistics.join(',') }
      else
        arguments = {}
      end

      dstk_api_post('/coordinates2statistics', arguments, coordinates, 'json')
    end

  end
end
