class PhoneVerification
  class << self
    # time that user has before a code expires
    EXPIRATION = 5.minutes

    # an SMS can't be sent more frequently than that
    TIME_BEFORE_RESEND = 30.seconds

    # how many times can a user enter an invalid code
    MAX_ATTEMPTS = 5

    # if a user has entered an invalid code
    # this is how long he has to wait before sending a new one
    TIME_BEFORE_RETRY = 10.minutes

    # once a phone is verified, a phone token
    # needs to be used within that time frame
    PHONE_TOKEN_EXPIRATION = 1.hour

    # how many digits there are in the verification code
    CODE_LENGTH = 6

    # Sends a verification code to a given phone number
    def send_verification(phone:)
      raise StandardError, "Phone can't be blank" if phone.blank?
      raise StandardError, "Please enter a valid phone" unless PhoneValidator.valid?(phone)

      # check if a code was already sent to this phone number
      existing_code = redis.get(phone_key(phone))
      if existing_code

        # if a code was already sent, we need to check
        # that time has passed before re-sending it
        # we don't want to allow users to send too many SMS
        # because they cost money and could be abused
        too_early = redis.get(resend_key(phone)).present?

        raise StandardError, "Can't resend a code this soon" if too_early

        # verify that the maximum number of attempts was not yet reached
        attempts = redis.get(attempts_key(phone)).to_i
        raise StandardError, "You reached the maximum number of attempts, please wait" if attempts > MAX_ATTEMPTS

        # if time has passed, we re-send the same code
        code = existing_code
      else
        # generate N digit code
        code = SecureRandom.random_number(10 ** CODE_LENGTH).to_s.rjust(CODE_LENGTH, "0")

        # save this code in redis under the given phone number
        redis.set(phone_key(phone), code, ex: EXPIRATION, nx: true)
        # set attempts to 0
        redis.set(attempts_key(phone), "0", ex: EXPIRATION, nx: true)
      end

      # reset a timer for being able to send a code for a given phone number
      redis.set(resend_key(phone), "true", ex: TIME_BEFORE_RESEND, nx: true)

      content = "Verification code: #{code}"
      # actually send the SMS using twilio or some other service
      Messenger.call(phone: phone, message: content)
    end

    # Verifies that a code is valid
    # and returns an encoded phone token
    # that proves the phone was verified
    def code_to_phone_token(phone:, code:)
      raise StandardError, "Phone can't be blank" if phone.blank?
      raise StandardError, "Please enter a valid phone" unless PhoneValidator.valid?(phone)
      raise StandardError, "Code can't be blank" if code.blank?

      real_code = redis.get(phone_key(phone))
      if real_code.nil?
        raise StandardError, "The code has expired"
      end
      attempts = redis.get(attempts_key(phone)).to_i
      attempts += 1
      # if number of attempts has exceeded the threshold
      # then don't let a code to be sent until some time passes
      if attempts > MAX_ATTEMPTS
        # prolong code and attempts expiration,
        # user won't be able to send new code until this time passes
        redis.set(phone_key(phone), real_code, ex: TIME_BEFORE_RETRY)
        redis.set(attempts_key(phone), attempts.to_s, ex: TIME_BEFORE_RETRY)
        raise StandardError, "You reached the maximum number of attempts, please wait"
      end
      is_valid = ActiveSupport::SecurityUtils.secure_compare(code, real_code)
      unless is_valid
        # prolong phone key expiration
        redis.set(phone_key(phone), real_code, ex: EXPIRATION)
        # save updated attempts count
        redis.set(attempts_key(phone), attempts.to_s, ex: EXPIRATION)
        raise StandardError, "The code is invalid"
      end
      # contents of the phone token
      # using this token we can always lookup a user
      # by phone and make sure the token hasn't expired
      payload = {
        phone: PhoneValidator.clean(phone),
        iat: Time.now.to_i
      }
      # the only way to generate this token is if you know the secret key
      TextEncryptor.encrypt(JSON.dump(payload))
    end

    # Exchange phone token to a phone,
    # later this phone can be used to sign-in / sign-up a user
    def phone_token_to_phone(phone_token)
      payload = begin
                  JSON.parse(TextEncryptor.decrypt(phone_token)).symbolize_keys
                rescue
                  raise StandardError, "The phone token is invalid"
                end
      # make sure the token hasn't expired yet
      issued_at = Time.at(payload[:iat])
      if issued_at < PHONE_TOKEN_EXPIRATION.ago
        raise StandardError, "The phone token is no longer valid"
      end
      payload[:phone]
    end

    private

    def phone_key(phone)
      "phone_verification_#{PhoneValidator.clean(phone)}"
    end

    def resend_key(phone)
      "#{phone_key(phone)}_resend"
    end

    def attempts_key(phone)
      "#{phone_key(phone)}_attempts"
    end

    def redis
      RedisClient.instance
    end
  end
end
