module AmexEnhancedAuthorization

  # Amex requests use extended headers and a JSON body.
  class Request < LoggedRequest
    attr_reader :client_id
    attr_reader :authorization

    def initialize(method, path, client_id, logger)
      super(method, path, logger)
      @client_id = client_id
    end

    # Return response on success or log failure and throw error.
    def send(data, authorization)
      @authorization = authorization
      request.body = data if data
      response = super(data)
      fail_unless_expected_response response, Net::HTTPSuccess
      response.body
    end

    def headers
      Hash[
        'Content-Type' => 'application/json; charset=utf-8',
        'Content-Language' => 'en-US',
        'x-amex-api-key' => client_id,
        'x-amex-request-id' => SecureRandom.uuid,
        'authorization' => authorization,
      ]
    end

    class UnexpectedHttpResponse < StandardError
      attr_reader :response

      def initialize(response)
        @response = response
        super "#{response.message} (#{response.code}): #{response.body}"
      end
    end

    def fail_unless_expected_response(response, *allowed_responses)
      unless allowed_responses.any? { |allowed| response.is_a?(allowed) }
        logger.error "#{response.inspect}: #{response.body}"
        raise UnexpectedHttpResponse, response
      end
      response
    end
  end
end
