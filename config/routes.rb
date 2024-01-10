require 'sidekiq/web'

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  get '/health' => 'pages#health_check'
  get 'api-docs/v1/swagger.yaml' => 'swagger#yaml'
  # ... other routes ...

  post '/api/users/register', to: 'api/base_controller#register'
  post '/api/users/request-password-reset', to: 'api/base_controller#request_password_reset'
  post '/api/users/verify-email' => 'users#verify_email'
end
