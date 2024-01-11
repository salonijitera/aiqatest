require 'bcrypt'

class UserRegistrationService < BaseService
  def register(email, password, password_confirmation)
    # Validate presence of fields
    return { error: 'Email cannot be blank' } if email.blank?
    return { error: 'Password cannot be blank' } if password.blank?
    return { error: 'Password confirmation cannot be blank' } if password_confirmation.blank?

    # Validate email format
    return { error: 'Invalid email format' } unless email.match(URI::MailTo::EMAIL_REGEXP)

    # Check if email already exists
    existing_user = User.find_by(email: email)
    return { error: 'Email has already been taken' } if existing_user

    # Compare passwords
    return { error: 'Password confirmation does not match' } if password != password_confirmation

    # Encrypt password
    encrypted_password = BCrypt::Password.create(password)

    # Create user record
    user = User.create(email: email, password_hash: encrypted_password, is_email_verified: false)

    # Generate email verification token
    token = SecureRandom.hex(10)
    EmailVerificationToken.create(token: token, user: user, expires_at: 24.hours.from_now, is_used: false)

    # Send email with verification token
    send_verification_email(user, token)

    # Return success message
    { success: 'User registered successfully. Please check your email to verify your account.' }
  rescue StandardError => e
    { error: e.message }
  end

  private

  def send_verification_email(user, token)
    # Email sending logic here
    # Use devise mailer template for confirmation instructions
  end
end

class BaseService
  # Define the base service class if it doesn't exist
end
