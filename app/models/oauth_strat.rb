# frozen_string_literal: true

class OauthStrat
  include NoBrainer::Document
  include NoBrainer::Document::Timestamps

  field :name,           type: String

  belongs_to :authority

  field :client_id,      type: String
  field :client_secret,  type: String
  field :info_mappings,  type: Hash
  field :site,           type: String
  field :authorize_url,  type: String
  field :token_method,   type: String
  field :auth_scheme,    type: String
  field :token_url,      type: String
  field :scope,          type: String
  field :raw_info_url,   type: String

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
