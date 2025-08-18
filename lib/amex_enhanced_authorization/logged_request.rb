require 'benchmark'
require 'net/http'

module AmexEnhancedAuthorization

  # An HTTPS request whose content, response and latency are logged.
  class LoggedRequest
    attr_reader :uri, :request
    attr_reader :logger

    # @param [String] method, e.g. 'POST'
    # @param [String] path, e.g. '/payments/digital/v2/tokens/provisioning'
    # @param [Logger] logger
    def initialize(method, path, logger)
      @uri = URI(path)
      @request = Net::HTTP.const_get(method.capitalize).new(@uri)
      @logger = logger
    end

    # Add provided headers and invoke request over HTTPS.
    # @return response
    def send(data, options)
      headers.each_pair { |k, v| request[k] = v }
      log_request_response(headers, data, options) do
        options[:cert] = OpenSSL::X509::Certificate.new(options[:cert]) if options[:cert].is_a?(String)
        options[:key] = OpenSSL::PKey::RSA.new(options[:key]) if options[:key].is_a?(String)
        https(uri, options).request(request)
      end
    end

    # @return [Hash]
    def headers
      @headers ||= {}
    end

    protected

    def https(uri, options = {})
      Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.use_ssl = true
        # Set any supported Net::HTTP options from the options hash
        %i[verify_mode cert key ca_file].each do |opt|
          http.public_send("#{opt}=", options[opt]) if options[opt]
        end
      end
    end

    # Log URI, method, data
    # Start timer.
    # Yield to request block.
    # Log response and time taken.
    def log_request_response(headers, data = nil, options = {})
      logger.info "[#{self.class.name}] request = #{request.method} #{uri}#{data ? '?' + data : ''}"
      logger.info "[#{self.class.name}] headers = #{headers}"
      response = nil
      tms = Benchmark.measure do
        response = yield
      end
      logger.info("[#{self.class.name}] response (#{ms(tms)}ms): #{response.inspect} #{response.body}")
      response
    end

    def ms(tms)
      (tms.real*1000).round(3)
    end
  end
end
