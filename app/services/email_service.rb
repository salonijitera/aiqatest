class EmailService < BaseService
  def send_verification_email(user_email, token)
    begin
      # Assuming ActionMailer is set up in the project
      mail = ActionMailer::Base.mail(
        from: "noreply@example.com",
        to: user_email,
        subject: "Email Verification",
        body: render_verification_email(user_email, token)
      )
      mail.deliver_now
    rescue StandardError => e
      # Handle email delivery errors
      Rails.logger.error "Email delivery failed: #{e.message}"
      return { success: false, error: e.message }
    end
    { success: true }
  end

  private
  def render_verification_email(user_email, token)
    # Load and render the email template, replacing placeholders with actual values
    template = File.read(Rails.root.join('app', 'views', 'devise', 'mailer', 'confirmation_instructions.html.slim'))
    template.gsub!('@email', user_email)
    template.gsub!('@token', token)
    Slim::Template.new { template }.render
  end
end
