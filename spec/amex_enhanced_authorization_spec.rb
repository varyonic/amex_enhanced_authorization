RSpec.describe AmexEnhancedAuthorization do
  it "has a version number" do
    expect(AmexEnhancedAuthorization::VERSION).not_to be nil
  end

  let(:host) { 'api.qasb.americanexpress.com' }
  let(:client_id) { ENV.fetch('AEEA_CLIENT_ID') }
  let(:client_secret) { ENV.fetch('AEEA_CLIENT_SECRET') }
  let(:transaction_params) do
    {
      card_number: '375987654321001',
      amount: '100',
      timestamp: Time.now,
      currency_code: '840',
      card_acceptor_id: '1030026553'
    }
  end
  let(:purchaser_information) do
    {
      customer_email: "customer@wal.com",
      billing_address: "1234 Main Street",
      billing_postal_code: "12345",
      billing_first_name: "Test",
      billing_last_name: "User",
      billing_phone_number: "6028888888",
      shipto_address: "1234 Main Street",
      shipto_postal_code: "12345",
      shipto_first_name: "Test",
      shipto_last_name: "User",
      shipto_phone_number: "6028888888",
      shipto_country_code: "840",
      device_ip: "10.0.0.0",
    }
  end

  subject do
    AmexEnhancedAuthorization::Connection.new(
      host: host,
      client_id: client_id,
      client_secret: client_secret
    )
  end

  before { subject.logger = Logger.new(STDOUT) if ENV['AEEA_LOG'] }

  context do
    # Copied from amex-api-java-client-core ApiAuthenticationTest.java
    let(:host) { 'github.com' }
    let(:client_id) { "UNIT-TEST-KEY-4388-87b9-85cf463231d7" }
    let(:client_secret) { 'UNIT-TEST-SEC-4206-8a21-a73eed54c896' }
    let(:payload) { 'The swift brown fox jumped over the lazy dogs back' }
    let(:bodyhash) { 'wlAalPXGd1oDuqepWDawftGy9zhgEV3oHZve/hz5Yac=' }

    it 'digests a payload' do
      expect(subject.hmac_digest(payload)).to eq(bodyhash)
    end

    context do
      let(:resource_path) { "/americanexpress/risk/fraud/v1/enhanced_authorizations/online_purchases" }
      let(:nonce) { "f00870f3-5862-45f1-9bd1-ba94c71d2661"}
      let(:ts) { "1473803713478" }

      it 'generates an HMAC header value' do
        authorization = subject.hmac_authorization('POST', resource_path, payload, nonce, ts)
        expect(authorization).to match(%Q{MAC id="#{client_id}"})
        expect(authorization).to match(%Q{,ts="#{ts}"})
        expect(authorization).to match(%Q{,nonce="#{nonce}"})
        expect(authorization).to match(%Q{,bodyhash="#{bodyhash}"})
      end
    end
  end

  it 'obtains a risk score and related data' do
    response = subject.online_purchase(transaction_params.merge purchaser_information)
    expect(response.class).to eq Hash
  end
end
