class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :role

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :password, length: { minimum: 12 }, allow_nil: true

  delegate :permits?, to: :role

  scope :active, -> { where(deactivated_at: nil) }
  scope :deactivated, -> { where.not(deactivated_at: nil) }

  def active?
    deactivated_at.nil?
  end
end