class Role < ApplicationRecord
  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions
  has_many :users, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true

  def permits?(key)
    permission_keys.include?(key.to_s)
  end

  private

  def permission_keys
    @permission_keys ||= permissions.pluck(:key)
  end
end
