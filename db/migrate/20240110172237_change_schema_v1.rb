class ChangeSchemaV1 < ActiveRecord::Migration[6.0]
  def change
    create_table :password_reset_tokens, comment: 'Stores tokens for password reset process' do |t|
      t.string :token

      t.boolean :is_used

      t.datetime :expires_at

      t.timestamps null: false
    end

    create_table :users, comment: 'Stores user account information' do |t|
      t.boolean :is_email_verified

      t.string :password_hash

      t.string :email

      t.timestamps null: false
    end

    create_table :email_verification_tokens, comment: 'Stores tokens for email verification process' do |t|
      t.datetime :expires_at

      t.boolean :is_used

      t.string :token

      t.timestamps null: false
    end

    add_reference :email_verification_tokens, :user, foreign_key: true

    add_reference :password_reset_tokens, :user, foreign_key: true
  end
end
