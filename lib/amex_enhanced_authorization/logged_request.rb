require 'benchmark'
require 'net/http'

module AmexEnhancedAuthorization

  # An HTTPS request whose content, response and latency are logged.
  class LoggedRequest
    attr_reader :uri, :request
    attr_reader :logger

    def initialize(method, path, logger)
      @uri = URI(path)
      @request = Net::HTTP.const_get(method.capitalize).new(@uri)
      @logger = logger
    end

    # Add provided headers and invoke request over HTTPS.
    # @return response
    def send(data)
      headers.each_pair { |k, v| request[k] = v }
      log_request_response(headers, data) do
        https(uri).request(request)
      end
    end

    # @return [Hash]
    def headers
      @headers ||= {}
    end

    protected

    def https(uri)
      Net::HTTP.new(uri.host, uri.port).tap { |http| http.use_ssl = true }
    end

    # Log URI, method, data
    # Start timer.
    # Yield to request block.
    # Log response and time taken.
    def log_request_response(headers, data = nil)
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
