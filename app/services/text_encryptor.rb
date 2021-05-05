class TextEncryptor
  class << self
    def encrypt(text)
      text = text.to_s unless text.is_a? String

      len   = ActiveSupport::MessageEncryptor.key_len
      salt  = SecureRandom.hex len
      key   = ActiveSupport::KeyGenerator.new(secret).generate_key salt, len
      crypt = ActiveSupport::MessageEncryptor.new key
      encrypted_data = crypt.encrypt_and_sign text
      "#{salt}$$#{encrypted_data}"
    end

    def decrypt(text)
      salt, data = text.split "$$"

      len   = ActiveSupport::MessageEncryptor.key_len
      key   = ActiveSupport::KeyGenerator.new(secret).generate_key salt, len
      crypt = ActiveSupport::MessageEncryptor.new key
      crypt.decrypt_and_verify data
    end

    private

    def secret
      Rails.application.secrets.secret_key_base
    end
  end
end
