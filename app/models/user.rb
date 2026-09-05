class User < ApplicationRecord
  include Auditable

  audit_excludes :password_digest, :reset_password_token, :reset_password_sent_at
  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :role

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :password, length: { minimum: 12 }, allow_nil: true

  audit_excludes :password_digest

  delegate :permits?, to: :role

  scope :active, -> { where(deactivated_at: nil) }
  scope :deactivated, -> { where.not(deactivated_at: nil) }
  scope :by_email, ->(value) { where("email_address ILIKE ?", "%#{sanitize_sql_like(value)}%") }

  def active?
    deactivated_at.nil?
  end
end
