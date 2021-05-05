class Messenger
  class << self
    def call(phone:, message:)
      @client.messages.create(
        from: Rails.application.credentials.twillio[:from_phone],
        to: phone,
        body: message
      )
    end

    private

    def client
      @client ||= Twilio::REST::Client.new(
        Rails.application.credentials.twillio[:api_key_sid],
        Rails.application.credentials.twillio[:api_key_secret],
        Rails.application.credentials.twillio[:account_sid]
      )
    end
  end
end
