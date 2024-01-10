require 'securerandom'

class PasswordResetService
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
end

# Mailer class assumed to be set up for sending emails
class PasswordResetMailer < ApplicationMailer
  def reset_password_instructions
    @user = params[:user]
    @token = params[:token]
    mail(to: @user.email, subject: I18n.t('devise.mailer.reset_password_instructions.subject'))
  end
end
