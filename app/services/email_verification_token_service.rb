require_relative '../models/email_verification_token'

class EmailVerificationTokenService < BaseService
  def create_token(user_id)
    begin
      token = SecureRandom.hex(10)
      expires_at = Time.current + 2.days

      email_verification_token = EmailVerificationToken.create!(
        token: token,
        user_id: user_id,
        expires_at: expires_at,
        is_used: false
      )

      # Here you would send the email with the token

      email_verification_token
    rescue => e
      # Handle error, log it and return a meaningful error message
      nil
    end
  end
end
