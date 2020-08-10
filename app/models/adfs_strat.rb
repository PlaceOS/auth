# encoding: UTF-8

class AdfsStrat
  include NoBrainer::Document
  include AuthTimestamps

  table_config name: 'adfs_strat'

  field :name, type: String
  belongs_to :authority

  field :issuer, type: String, default: :aca
  field :idp_sso_target_url_runtime_params, type: Hash
  field :name_identifier_format, type: String, default: ->{ 'urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified' }
  field :uid_attribute, type: String

  field :assertion_consumer_service_url, type: String
  field :idp_sso_target_url, type: String

  field :idp_cert, type: String
  field :idp_cert_fingerprint, type: String

  field :attribute_service_name, type: String
  field :attribute_statements, type: Hash, default: ->{
    {
      name: ["name"],
      email: ["email", "mail"],
      first_name: ["first_name", "firstname", "firstName", "givenname"],
      last_name: ["last_name", "lastname", "lastName", "surname"]
    }
  }
  field :request_attributes, type: Array, default: ->{
    [
      { :name => 'ImmutableID', :name_format => 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic', :friendly_name => 'Login Name' },
      { :name => 'email', :name_format => 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic', :friendly_name => 'Email address' },
      { :name => 'name', :name_format => 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic', :friendly_name => 'Full name' },
      { :name => 'first_name', :name_format => 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic', :friendly_name => 'Given name' },
      { :name => 'last_name', :name_format => 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic', :friendly_name => 'Family name' }
    ]
  }

  field :idp_slo_target_url, type: String
  field :slo_default_relay_state, type: String

  # Not actually sure what this type stuff is for?
  def type
    'adfs'
  end

  def type=(type)
    raise 'bad type' unless type.to_s == 'adfs'
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

  validates :issuer,                         presence: true
  validates :idp_sso_target_url,             presence: true
  validates :name_identifier_format,         presence: true
  validates :assertion_consumer_service_url, presence: true
  validates :request_attributes,             presence: true
end
