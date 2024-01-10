class EmailVerificationService < BaseService
  def verify_email(token)
    raise ArgumentError, 'Token cannot be blank' if token.blank?

    email_verification_token = EmailVerificationToken.find_by(token: token, is_used: false)
    if email_verification_token.nil? || email_verification_token.expires_at < Time.current
      return { success: false, message: 'Token is invalid or expired' }
    end

    EmailVerificationToken.transaction do
      email_verification_token.update!(is_used: true)
      email_verification_token.user.update!(is_email_verified: true)
    end

    { success: true, message: 'Email has been successfully verified' }
  rescue ActiveRecord::RecordInvalid => e
    logger.error "Email verification failed: #{e.record.errors.full_messages.join(', ')}"
    { success: false, message: 'Email verification failed' }
  rescue StandardError => e
    logger.error "Email verification encountered an unexpected error: #{e.message}"
    { success: false, message: 'An unexpected error occurred' }
  end
end

# Load the related models
# Note: In Rails, it's not necessary to explicitly require the related models
# as Rails uses autoloading to include necessary files based on naming conventions.
# The following lines are just a reminder that the service interacts with these models.
# EmailVerificationToken model (app/models/email_verification_token.rb)
# User model (app/models/user.rb)

