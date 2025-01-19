class Current < ActiveSupport::CurrentAttributes
  attribute :session, :network
  delegate :user, to: :session, allow_nil: true
end
