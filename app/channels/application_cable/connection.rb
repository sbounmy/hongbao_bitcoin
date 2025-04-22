module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private
      def find_verified_user
        if session_id = cookies.signed[:session_id]
          Rails.logger.info "Attempting to connect with session_id: #{session_id}"
          if session = Session.find_by(id: session_id)
            Rails.logger.info "Found session for user: #{session.user.email}"
            session.user
          else
            Rails.logger.info "No session found for session_id: #{session_id}"
            nil
          end
        else
          Rails.logger.info "No session_id cookie found"
          nil
        end
      rescue => e
        Rails.logger.error "Error in find_verified_user: #{e.message}"
        nil
      end
  end
end
