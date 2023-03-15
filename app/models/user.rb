require_relative "application_record"
require "email_validator"
require "digest/md5"
require "bcrypt"

class User < ApplicationRecord
  include BCrypt

  self.table_name = "user"

  after_initialize :set_defaults

  # TODO:: this should be configured in the database for cross service consistency
  def set_defaults
    deleted = false
    groups = []
    expires = true
    sys_admin = false
    support = false
  end

  PUBLIC_DATA = {only: %i[
    id email_digest nickname name first_name last_name groups
    country building image created_at authority_id deleted
    department preferred_language staff_id
  ]}.freeze

  belongs_to :authority
  has_many :authentications, dependent: :destroy
  has_many :access_tokens, class_name: "Doorkeeper::AccessToken", dependent: :destroy, foreign_key: :resource_owner_id
  has_many :access_grants, class_name: "Doorkeeper::AccessGrant", dependent: :destroy, foreign_key: :resource_owner_id

  def self.find_by_email(authority, email)
    email_digest = Digest::MD5.hexdigest(email.downcase)
    find_by authority_id: authority, email_digest: email_digest
  end

  before_save :build_name, if: ->(model) { model.first_name.present? }
  def build_name
    self.name = "#{first_name} #{last_name}"
  end

  before_save :hash_email, if: ->(model) { model.email.present? }
  def hash_email
    self.email_digest = Digest::MD5.hexdigest(email.downcase)
  end

  # PASSWORD ENCRYPTION::
  # ---------------------

  validates_confirmation_of :password

  if respond_to?(:attributes_protected_by_default)
    def self.attributes_protected_by_default
      super + ["password_digest"]
    end
  end

  def authenticate(unencrypted_password)
    password == unencrypted_password ? self : false
  rescue
    # accounts created with social logins will have an empty password_digest
    # which causes BCrypt to raise an InvalidHash exception
    false
  end

  # Encrypts the password into the password_digest attribute.
  def password
    return nil unless @password.present? || password_digest.present?

    @password ||= Password.new(password_digest)
  end

  def password=(new_password)
    if new_password.present?
      self.password_digest = Password.create(new_password)
      @password = new_password
    else
      @password = nil
      self.password_digest = ""
      new_password
    end
  end
  # --------------------
  # END PASSWORD METHODS

  # Make reference to the email= function of the model
  def email=(new_email)
    super(new_email)

    # For looking up user pictures without making the email public
    self.email_digest = new_email ? Digest::MD5.hexdigest(new_email.downcase) : nil
  end
  alias_method :assign_email, :email=

  # Validations
  validates :email, email: true
  validates :password, length: {minimum: 6, message: "must be at least 6 characters"}, allow_blank: true
  validates_each :email do |record, attr_name, value|
    user = User.find_by_email(record.authority_id, value)
    record.errors.add(attr_name, "already exists, it must be unique") if user && user.id != record.id
  end
end
