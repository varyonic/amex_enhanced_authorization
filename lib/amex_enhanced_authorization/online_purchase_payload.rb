require 'json'

module AmexEnhancedAuthorization
  class OnlinePurchasePayload
    attr_accessor :card_acceptor_id, :card_number, :currency_code, :amount, :timestamp
    attr_accessor :customer_email
    attr_accessor :billing_address, :billing_postal_code, :billing_first_name, :billing_last_name, :billing_phone_number
    attr_accessor :shipto_address, :shipto_postal_code, :shipto_first_name, :shipto_last_name, :shipto_phone_number, :shipto_country_code
    attr_accessor :device_ip

    def initialize(params)
      params.each_pair { |k, v| send "#{k}=", v }
    end

    def to_json
      payload = {
        timestamp: strftime(Time.now),
        transaction_data: {
          card_acceptor_id: card_acceptor_id.to_s, # aka. SE10 or Merchant code
          card_number: card_number,
          amount: amount.to_s,
          currency_code: currency_code,
          transaction_timestamp: strftime(timestamp),
          additional_information: { risk_score: true },
        }
      }
      payload[:purchaser_information] = purchaser_information if purchaser_information.any?
      payload.to_json
    end

    protected

    def purchaser_information
      @purchaser_information ||= {
        customer_email: customer_email,
        billing_address: munge(billing_address, /[^A-Za-z0-9 ]/, 70),
        billing_postal_code: munge(billing_postal_code, /[^A-Za-z0-9\- ]/, 9),
        billing_first_name: munge(billing_first_name, /[^A-Za-z0-9 ]/, 30),
        billing_last_name: munge(billing_last_name, /[^A-Za-z0-9 ]/,  30),
        billing_phone_number: billing_phone_number,
        shipto_address: munge(shipto_address, /[^A-Za-z0-9 ]/, 50),
        shipto_postal_code: shipto_postal_code,
        shipto_first_name: shipto_first_name,
        shipto_last_name: munge(shipto_last_name, /[^A-Za-z0-9 ]/, 30),
        shipto_phone_number: shipto_phone_number,
        shipto_country_code: shipto_country_code,
        device_ip: device_ip,
      }.compact
    end

    def munge(s, exp, length)
      s && ascify(s).gsub(exp, ' ')[0..(length-1)]
    end

    def ascify(s)
      s && s.tr( 
"ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž", 
"AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz")
    end

    def strftime(timestamp)
      timestamp.utc.strftime('%Y-%m-%dT%H:%M:%S.%L%:z')
    end
  end
end
