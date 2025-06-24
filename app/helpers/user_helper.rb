# frozen_string_literal: true

module UserHelper
  def remove_session
    cookies.delete(:verified, path: "/")
    cookies.delete(:user, path: "/auth")
    cookies.delete(:social, path: "/auth")
    cookies.delete(:continue, path: "/auth")
    @current_user = nil
  end

  def current_user
    return @current_user if @current_user

    user = cookies.encrypted[:user]
    return nil unless user
    return remove_session if Time.now.to_i > user["expires"]

    user_model = User.find_by(id: user["id"])

    # check if the user has logged off since this session was created
    last_log_out = user_model.logged_out_at
    if last_log_out
      iat_usec = user["iat"]&.to_i
      if iat_usec
        session_created = Time.at(iat_usec / 1_000_000, iat_usec % 1_000_000)
        user_model = nil if session_created < last_log_out
      else
        user_model = nil
      end
    end

    # return the user model or nil + delete the session
    @current_user = user_model || remove_session
  end

  def signed_in?
    !!current_user
  end
end
