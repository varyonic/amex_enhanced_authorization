RSpec.describe AmexEnhancedAuthorization::OnlinePurchasePayload do
  subject { described_class.new(timestamp: Time.now) }

  it 'uses a correctly formatted timestamp' do
    expect(subject.to_json).to match(/\+00:00/)
  end
end
