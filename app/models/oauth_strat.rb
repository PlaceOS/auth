# encoding: UTF-8

class OauthStrat
  include NoBrainer::Document
  include AuthTimestamps

  table_config name: 'oauth_strat'

  field :name,           type: String

  belongs_to :authority

  field :client_id,        type: String
  field :client_secret,    type: String

  # Maps oauth fields to our fields
  field :info_mappings,    type: Hash

  # additional params to be sent as part of the authorisation request
  field :authorize_params, type: Hash, default: ->{ {} }

  # Security checks to be made on the returned data String => Array(String)
  field :ensure_matching,  type: Hash, default: ->{ {} }
  field :site,             type: String
  field :authorize_url,    type: String
  field :token_method,     type: String
  field :auth_scheme,      type: String
  field :token_url,        type: String
  field :scope,            type: String
  field :raw_info_url,     type: String

  def type
    'oauths'
  end

  def type=(type)
    raise 'bad type' unless type.to_s == 'oauths'
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
end
