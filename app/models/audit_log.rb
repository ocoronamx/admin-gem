class AuditLog < ApplicationRecord
  belongs_to :user, optional: true # nil = acción sin actor (seeds, jobs)
  belongs_to :resource, polymorphic: true

  validates :action, presence: true

  scope :by_action, ->(value) { where(action: value) }
end
