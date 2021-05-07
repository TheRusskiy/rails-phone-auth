# Rails Phone Authentication

## You can read the full explanation [in this article](https://www.dmitry-ishkov.com/2021/05/phone-authentication-in-ruby.html)

This is an example of how a phone sign-in / sign-up could work.

The core of the logic is located at `PhoneVerification` class.

## Pseudo-code API:

```ruby
# ask user for a phone and send an SMS code
POST /send-phone-verification { phone: '+19178456780' }
PhoneVerification.send_verification(phone: params[:phone])
=> {}


# verify the phone entering the code from SMS,
# get encoded phoneToken in return
POST /verify-phone { phone: '+19178456780', code: '123456' }
phone_token = PhoneVerification.code_to_phone_token(
  phone: params[:phone],
  code: params[:code]
)
=> { phoneToken: phone_token }


# exchange the phoneToken to a user information
POST /sign-in { phoneToken: 'xxxxxxxxxxxxx' }
trusted_phone = PhoneVerification.phone_token_to_phone(params[:phone_token])
user = User.find_by_phone(trusted_phone)
=> { user: user }

# OR

# use the phone token to create a new user with verified phone
POST /sign-up { phoneToken: 'xxxxxxxxxxxxx', name: 'John Doe', email: 'john@example.com' }
trusted_phone = PhoneVerification.phone_token_to_phone(params[:phone_token])
user = User.find_or_create_by!(phone: trusted_phone) do |u|
  u.name = params[:name]
  u.email = params[:email]
end
=> { user: user }
```

# License: MIT
