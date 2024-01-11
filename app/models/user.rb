class User < ApplicationRecord
  has_many :email_verification_tokens, dependent: :destroy
  has_many :password_reset_tokens, dependent: :destroy

  # validations

  # end for validations

  class << self
  end
end
