class Session < ApplicationRecord
  belongs_to :user

  scope :stale, -> { where(updated_at: ...30.days.ago) }
end
