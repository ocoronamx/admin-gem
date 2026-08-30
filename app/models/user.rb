class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :role

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :password, length: { minimum: 12 }, allow_nil: true

  delegate :permits?, to: :role
end
