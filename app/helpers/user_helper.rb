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

    @current_user = User.find_by(id: user["id"]) || remove_session
  end

  def signed_in?
    !!current_user
  end
end
