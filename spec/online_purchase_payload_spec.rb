RSpec.describe AmexEnhancedAuthorization::OnlinePurchasePayload do
  subject { described_class.new(timestamp: Time.now) }

  it 'uses a correctly formatted timestamp' do
    expect(subject.to_json).to match(/\+00:00/)
  end

  context 'accented last name' do
    subject { described_class.new(billing_last_name: 'López', timestamp: Time.now) }

    it { expect(subject.to_json).to match(/Lopez/) }
  end
end
