# frozen_string_literal: true

require 'email_validator'
require 'digest/md5'
require 'scrypt'

class User
  include NoBrainer::Document
  include NoBrainer::Document::Timestamps

  table_config :name => 'user'

  PUBLIC_DATA = {only: [
    :id, :email_digest, :nickname, :name, :first_name, :last_name,
    :country, :building, :created_at
  ]}

  field :name,            type: String
  field :email,           type: String, uniq: {scope: :authority}
  field :nickname,        type: String
  field :phone,           type: String
  field :country,         type: String
  field :image,           type: String
  field :metadata,        type: String
  field :login_name,      type: String
  field :staff_id,        type: String
  field :first_name,      type: String
  field :last_name,       type: String
  field :building,        type: String
  field :password_digest, type: String
  field :email_digest,    type: String
  field :card_number,     type: String
  field :deleted,         type: Boolean, default: false

  belongs_to :authority

  def self.find_by_email(authority, email)
    User.where(authority_id: authority, email: email).first
  end

  field :sys_admin, default: false
  field :support,   default: false

  before_save :build_name, if: ->(model) { model.first_name.present? }
  def build_name
    self.name = "#{self.first_name} #{self.last_name}"
  end

  # PASSWORD ENCRYPTION::
  # ---------------------
  attr_reader :password
  validates_confirmation_of :password

  if respond_to?(:attributes_protected_by_default)
    def self.attributes_protected_by_default
      super + ['password_digest']
    end
  end

  def authenticate(unencrypted_password)
    if ::SCrypt::Password.new(password_digest || '') == unencrypted_password
      self
    else
      false
    end
  rescue ::SCrypt::Errors::InvalidHash
    # accounts created with social logins will have an empty password_digest
    # which causes SCrypt to raise an InvalidHash exception
    false
  end

  # Encrypts the password into the password_digest attribute.
  def password=(unencrypted_password)
    @password = unencrypted_password
    unless unencrypted_password.empty?
      self.password_digest = ::SCrypt::Password.create(unencrypted_password)
    end
  end
  # --------------------
  # END PASSWORD METHODS

  # Make reference to the email= function of the model
  alias_method :assign_email, :email=
  def email=(new_email)
    super(new_email)

    # For looking up user pictures without making the email public
    self.email_digest = new_email ? Digest::MD5.hexdigest(new_email) : nil
  end

  protected

  # Validations
  validates :email, :email => true
  validates :password, length: { minimum: 6, message: 'must be at least 6 characters' }, allow_blank: true
end