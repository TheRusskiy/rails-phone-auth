class Messenger
  class << self
    def call(phone:, message:)
      @client.messages.create(
        from: Rails.application.credentials.twilio[:from_phone],
        to: phone,
        body: message
      )
    end

    private

    def client
      @client ||= Twilio::REST::Client.new(
        Rails.application.credentials.twilio[:api_key_sid],
        Rails.application.credentials.twilio[:api_key_secret],
        Rails.application.credentials.twilio[:account_sid]
      )
    end
  end
end
