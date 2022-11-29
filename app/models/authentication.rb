require_relative "application_record"

class Authentication < ApplicationRecord
  belongs_to :user
  belongs_to :authority

  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }

  # Where auth is https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema
  def self.from_omniauth(authority_id, auth)
    find_by id: "auth-#{authority_id}-#{auth["provider"]}-#{auth["uid"]}"
  end

  def self.create_with_omniauth(authority_id, auth, user_id)
    authen = Authentication.new
    authen.authority_id = authority_id
    authen.provider = auth["provider"]
    authen.uid = auth["uid"]
    authen.user_id = user_id
    authen.save!
    authen
  end

  # the before_signup block gives installations the ability to reject
  # signups or modify the user record before any user/auth records are
  # stored. if the block returns false, user signup is rejected.
  def self.before_signup(&block)
    @before_signup = block
  end

  def self.before_signup_block
    @before_signup || (->(_user, _provider, _auth) { true })
  end

  # the after_login block gives installations the ability to perform post
  # login functions, such as syncing user permissions from a remote server
  def self.after_login(&block)
    @after_login = block
  end

  def self.after_login_block
    @after_login || (->(_user, _provider, _auth) {})
  end

  protected

  before_create :generate_id
  def generate_id
    self.id = "auth-#{authority_id}-#{provider}-#{uid}"
  end
end
