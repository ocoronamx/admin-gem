class Permission < ApplicationRecord
  KEY_FORMAT = /\A[a-z0-9_]+\.[a-z0-9_]+\z/

  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  validates :key, presence: true, uniqueness: true
  validates :key, format: { with: KEY_FORMAT, message: "debe tener el formato 'recurso.acción'" }
end
