Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  post 'send-phone-verification', to: 'phone_verification#send_verification'
  post 'verify-phone', to: 'phone_verification#code_to_phone_token'
  post 'login', to: 'phone_verification#login'
  post 'signup', to: 'phone_verification#signup'
end
