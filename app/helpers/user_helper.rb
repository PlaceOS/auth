# frozen_string_literal: true

module UserHelper
  def remove_session
    cookies.delete(:user,   path: '/auth')
    cookies.delete(:social, path: '/auth')
    cookies.delete(:continue, path: '/auth')
    @current_user = nil
  end

  def current_user
    user = cookies.encrypted[:user]
    @current_user ||= User.find((user[:id] || user['id'])) if user
  end

  def signed_in?
    !!current_user
  end
end
