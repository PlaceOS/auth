# encoding: UTF-8

require 'email_validator'
require 'digest/md5'
require 'bcrypt'

class User
  include NoBrainer::Document
  include AuthTimestamps
  include BCrypt

  table_config name: 'user'

  PUBLIC_DATA = {only: [
    :id, :email_digest, :nickname, :name, :first_name, :last_name,
    :country, :building, :created_at
  ]}

  field :name,            type: String
  field :nickname,        type: String
  field :email,           type: String, uniq: {scope: :authority_id}
  field :phone,           type: String
  field :country,         type: String
  field :image,           type: String
  field :ui_theme,        type: String
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

  # typically LDAP groups
  field :groups,          type: Array, default: ->{ [] }

  # User credentials
  field :access_token,    type: String
  field :refresh_token,   type: String
  field :expires_at,      type: Integer
  field :expires,         type: Boolean

  belongs_to :authority
  has_many :authentications, dependent: :destroy
  has_many :access_tokens, class_name: 'Doorkeeper::AccessToken', dependent: :destroy, foreign_key: :resource_owner_id
  has_many :access_grants, class_name: 'Doorkeeper::AccessGrant', dependent: :destroy, foreign_key: :resource_owner_id

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
    self.password == unencrypted_password ? self : false
  rescue
    # accounts created with social logins will have an empty password_digest
    # which causes BCrypt to raise an InvalidHash exception
    false
  end

  # Encrypts the password into the password_digest attribute.
  def password
    return nil unless @password.present? || self.password_digest.present?
    @password ||= Password.new(self.password_digest)
  end

  def password=(new_password)
    if !new_password.present?
      @password = nil
      self.password_digest = ""
      return new_password
    end

    self.password_digest = Password.create(new_password)
    @password = new_password
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
