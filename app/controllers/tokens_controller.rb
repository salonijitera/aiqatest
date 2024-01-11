
# frozen_string_literal: true

class TokensController < Doorkeeper::TokensController
  # callback
  before_action :validate_resource_owner

  # methods

  def validate_resource_owner
    return if resource_owner.blank?

    if resource_owner_locked?
      render json: {
        error: I18n.t('common.errors.token.locked'),
        message: I18n.t('common.errors.token.locked')
      }, status: :unauthorized
    end
    return if resource_owner_confirmed?

    render json: {
             error: I18n.t('common.errors.token.inactive'),
             message: I18n.t('common.errors.token.inactive')
           },
           status: :unauthorized
  end

  def resource_owner
    return nil if action_name == 'revoke'

    return unless authorize_response.respond_to?(:token)

    authorize_response&.token&.resource_owner
  end

  def resource_owner_locked?
    resource_owner.access_locked?
  end

  def resource_owner_confirmed?
    # based on condition jitera studio
  end

  # POST /api/users/reset-password
  def confirm_password_reset
    token = params[:token]
    new_password = params[:new_password]
    new_password_confirmation = params[:new_password_confirmation]

    if token.blank? || new_password.blank? || new_password_confirmation.blank?
      render json: { error: 'All fields are required.' }, status: :bad_request
      return
    end

    unless new_password == new_password_confirmation
      render json: { error: 'Password confirmation does not match.' }, status: :unprocessable_entity
      return
    end

    password_reset_token = PasswordResetToken.find_by(token: token, is_used: false)
    if password_reset_token.nil?
      render json: { error: 'Token is invalid or expired.' }, status: :not_found
      return
    elsif password_reset_token.expires_at < Time.current
      render json: { error: 'Token is expired.' }, status: :unprocessable_entity
      return
    end

    password_reset_token.update!(is_used: true)
    encrypted_password = BCrypt::Password.create(new_password)
    user = password_reset_token.user
    user.update(password_hash: encrypted_password)

    render json: { message: 'Password has been successfully reset.' }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found.' }, status: :not_found
  rescue => e
    render json: { error: e.message }, status: :internal_server_error
  end
end
