require 'securerandom'

class PasswordResetService < BaseService
  def self.request_password_reset(email:)
    return 'Email cannot be empty' if email.blank?

    unless email.match(/\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i)
      return 'Invalid email format'
    end

    user = User.find_by(email: email)
    return 'Account does not exist' unless user

    token = SecureRandom.hex(10)
    expiration_date = 2.hours.from_now

    PasswordResetToken.create!(
      user: user,
      token: token,
      expires_at: expiration_date,
      is_used: false
    )

    PasswordResetMailer.with(user: user, token: token).reset_password_instructions.deliver_now

    'Password reset instructions have been sent to your email'
  end

  def confirm_reset(token, new_password, new_password_confirmation)
    raise ActiveRecord::RecordInvalid, 'Passwords do not match' unless new_password == new_password_confirmation

    PasswordResetToken.transaction do
      password_reset_token = PasswordResetToken.find_by(token: token, is_used: false)
      raise ActiveRecord::RecordNotFound, 'Token is invalid or expired' if password_reset_token.nil? || password_reset_token.expires_at < Time.current

      password_reset_token.update!(is_used: true)

      user = password_reset_token.user
      encrypted_password = User.encrypt_password(new_password) # Assuming User model has a method to encrypt password
      user.update!(password_hash: encrypted_password)
    end

    { message: 'Password has been successfully reset' }
  rescue ActiveRecord::RecordInvalid => e
    { error: e.message }
  rescue ActiveRecord::RecordNotFound => e
    { error: e.message }
  end
end

# Mailer class assumed to be set up for sending emails
class PasswordResetMailer < ApplicationMailer
  def reset_password_instructions
    @user = params[:user]
    @token = params[:token]
    mail(to: @user.email, subject: I18n.t('devise.mailer.reset_password_instructions.subject'))
  end
end
