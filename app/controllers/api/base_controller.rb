# typed: ignore
module Api
  require_relative '../../services/password_reset_service'
  require_relative '../../services/email_verification_service'

  class BaseController < ActionController::API
    include ActionController::Cookies
    include Pundit::Authorization

    # =======End include module======

    rescue_from ActiveRecord::RecordNotFound, with: :base_render_record_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :base_render_unprocessable_entity
    rescue_from Exceptions::AuthenticationError, with: :base_render_authentication_error
    rescue_from ActiveRecord::RecordNotUnique, with: :base_render_record_not_unique
    rescue_from Pundit::NotAuthorizedError, with: :base_render_unauthorized_error

    def error_response(resource, error)
      {
        success: false,
        full_messages: resource&.errors&.full_messages,
        errors: resource&.errors,
        error_message: error.message,
        backtrace: error.backtrace
      }
    end

    private

    def base_render_record_not_found(_exception)
      render json: { message: I18n.t('common.404') }, status: :not_found
    end

    def base_render_unprocessable_entity(exception)
      render json: { message: exception.record.errors.full_messages }, status: :unprocessable_entity
    end

    def base_render_authentication_error(_exception)
      render json: { message: I18n.t('common.404') }, status: :not_found
    end

    def base_render_unauthorized_error(_exception)
      render json: { message: I18n.t('common.errors.unauthorized_error') }, status: :unauthorized
    end

    def base_render_record_not_unique
      render json: { message: I18n.t('common.errors.record_not_uniq_error') }, status: :forbidden
    end

    def custom_token_initialize_values(resource, client)
      token = CustomAccessToken.create(
        application_id: client.id,
        resource_owner: resource,
        scopes: resource.class.name.pluralize.downcase,
        expires_in: Doorkeeper.configuration.access_token_expires_in.seconds
      )
      @access_token = token.token
      @token_type = 'Bearer'
      @expires_in = token.expires_in
      @refresh_token = token.refresh_token
      @resource_owner = resource.class.name
      @resource_id = resource.id
      @created_at = resource.created_at
      @refresh_token_expires_in = token.refresh_expires_in
      @scope = token.scopes
    end

    def request_password_reset
      email = params.require(:email)
      result = PasswordResetService.request_password_reset(email: email)

      case result
      when 'Invalid email format'
        render json: { message: 'Invalid email format.' }, status: :bad_request
      when 'Account does not exist'
        render json: { message: 'Email not found.' }, status: :not_found
      when 'Password reset instructions have been sent to your email'
        render json: { status: 200, message: result }, status: :ok
      else
        render json: { message: 'An unexpected error occurred on the server.' }, status: :internal_server_error
      end
    rescue ActionController::ParameterMissing
      render json: { message: 'Invalid parameters.' }, status: :bad_request
    end

    def verify_email
      token = params.require(:token)
      result = EmailVerificationService.new.verify_email(token)

      if result[:success]
        render json: { status: 200, message: result[:message] }, status: :ok
      else
        case result[:message]
        when 'Token is invalid or expired'
          render json: { status: 404, message: result[:message] }, status: :not_found
        when 'This token has already been used.'
          render json: { status: 410, message: result[:message] }, status: :gone
        else
          render json: { status: 500, message: result[:message] }, status: :internal_server_error
        end
      end
    rescue ActionController::ParameterMissing => e
      render json: { status: 400, message: e.message }, status: :bad_request
    end

    def current_resource_owner
      return super if defined?(super)
    end
  end
end
