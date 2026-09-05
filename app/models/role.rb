class Role < ApplicationRecord
  include Auditable

  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions
  has_many :users, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true

  # Parcial (ILIKE), no exacta — es la que de verdad sirve en un filtro de
  # tabla administrativa. sanitize_sql_like escapa % y _ del valor del
  # usuario para que no altere el patrón (ver Filterable).
  scope :by_name, ->(value) { where("name ILIKE ?", "%#{sanitize_sql_like(value)}%") }
  scope :by_key,  ->(value) { where("key ILIKE ?", "%#{sanitize_sql_like(value)}%") }
  scope :by_email, ->(value) { where("email_address ILIKE ?", "%#{sanitize_sql_like(value)}%") }

  def permits?(key)
    permission_keys.include?(key.to_s)
  end

  private

  def permission_keys
    @permission_keys ||= permissions.pluck(:key)
  end
end
