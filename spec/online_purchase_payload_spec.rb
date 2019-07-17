RSpec.describe AmexEnhancedAuthorization::OnlinePurchasePayload do
  subject { described_class.new(timestamp: Time.now) }

  it 'uses a correctly formatted timestamp' do
    expect(subject.to_json).to match(/\+00:00/)
  end

  context 'accented fields' do
    subject do
      described_class.new(
        billing_last_name: 'López',
        billing_address: '1 Sábanas Dr',
        shipto_last_name: 'Martínez',
        timestamp: Time.now)
    end

    it { expect(subject.to_json).to match(/Lopez/) }
    it { expect(subject.to_json).to match(/Sabanas/) }
    it { expect(subject.to_json).to match(/Martinez/) }
  end
end
