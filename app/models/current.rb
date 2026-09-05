class Current < ActiveSupport::CurrentAttributes
  attribute :session, :request
  delegate :user, to: :session, allow_nil: true

  def ip_address
    request&.remote_ip
  end

  def user_agent
    request&.user_agent
  end
end
