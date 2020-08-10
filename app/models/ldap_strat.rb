# encoding: UTF-8

class LdapStrat
  include NoBrainer::Document
  include AuthTimestamps

  table_config name: 'ldap_strat'

  field :name,       type: String  # (used as title)

  belongs_to :authority

  field :port,        type: Integer, default: 636
  field :auth_method, type: String,  default: :ssl
  field :uid,         type: String,  default: lambda { 'sAMAccountName' }
  field :host,        type: String
  field :base,        type: String
  field :bind_dn,     type: String
  field :password,    type: String  # This should not be plain text
  field :filter

  def type
    'ldaps'
  end

  def type=(type)
    raise 'bad type' unless type.to_s == 'ldaps'
  end

  def serializable_hash(**options)
    options = {
      methods: :type
    }.merge!(options)
    super(**options)
  end

  protected

  validates :authority_id, presence: true
  validates :name,         presence: true
  validates :host,         presence: true
  validates :base,         presence: true
end
