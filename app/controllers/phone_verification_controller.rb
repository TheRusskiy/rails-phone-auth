class PhoneVerificationController < ApplicationController
  def send_verification
    PhoneVerification.send_verification(phone: params[:phone])
    render json: {
      error: nil
    }
  rescue => e
    render json: { error: e.message }
  end

  def code_to_phone_token
    phone_token = PhoneVerification.code_to_phone_token(
      phone: params[:phone],
      code: params[:code]
    )
    render json: {
      phoneToken: phone_token,
      error: nil
    }
  rescue => e
    render json: { error: e.message }
  end

  def login
    phone = PhoneVerification.phone_token_to_phone(params[:phoneToken])

    user = User.find_by_phone(phone)

    render json: {
      user: user,
      error: nil
    }
  rescue => e
    render json: { error: e.message }
  end

  def signup
    phone = PhoneVerification.phone_token_to_phone(params[:phoneToken])

    user = User.find_or_create_by(phone: phone) do |u|
      u.name = params[:name]
      u.email = params[:email]
    end

    render json: {
      user: user,
      error: nil
    }
  rescue => e
    render json: { error: e.message }
  end
end
