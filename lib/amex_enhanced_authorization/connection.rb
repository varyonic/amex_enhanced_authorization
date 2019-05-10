module AmexEnhancedAuthorization
  class Connection
    attr_reader :host
    attr_reader :base_path
    attr_reader :client_id, :client_secret
    attr_accessor :logger

    def initialize(host:,
                   client_id:, client_secret:,
                   logger: Logger.new('/dev/null'))
      @host = host
      @base_path = "/risk/fraud/v2/apiplatform/enhanced_authorizations".freeze
      @client_id, @client_secret = client_id, client_secret
      @logger = logger
    end

    def online_purchase(params)
      payload = OnlinePurchasePayload.new(params).to_json
      JSON.parse send_authorized_request('POST', 'online_purchases', payload)
    end

    def send_authorized_request(method, route, payload = nil)
      resource_path = "#{base_path}/#{route}"
      authorization = hmac_authorization(method, resource_path, payload)
      request = Request.new(method, "https://#{host}#{resource_path}", client_id, logger)
      request.send(payload, authorization)
    end

    # @param [String] method, e.g. 'POST'
    # @param [String] resource_path, e.g. '/payments/digital/v2/tokens/provisioning'
    # @param [String] JSON payload
    # @return [String] Authorization: MAC id="gfFb4K8esqZgMpzwF9SXzKLCCbPYV8bR",ts="1463772177193",nonce="61129a8d-ca24-464b-8891-9251501d86f0", bodyhash="YJpz6NdGP0aV6aYaa+6qKCjQt46of+Cj4liBz90G6X8=", mac="uzybzLPj3fD8eBZaBzb4E7pZs+l+IWS0w/w2wwsExdo="
    def hmac_authorization(method, resource_path, payload, nonce = SecureRandom.uuid, ts = (Time.now.to_r * 1000).to_i)
      bodyhash = hmac_digest(payload)
      mac = hmac_digest([ts, nonce, method, resource_path, host, 443, bodyhash, ''].join("\n"))
      %(MAC id="#{client_id}",ts="#{ts}",nonce="#{nonce}",bodyhash="#{bodyhash}",mac="#{mac}")
    end

    def hmac_digest(s)
      Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, client_secret, s.to_s))
    end
  end
end
