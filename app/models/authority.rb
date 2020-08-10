# encoding: UTF-8

require 'addressable/uri'

class Authority
  include NoBrainer::Document
  include AuthTimestamps

  table_config name: 'authority'

  field :name,        type: String
  field :domain,      type: String, uniq: true, index: true
  field :description, type: String
  field :login_url,   type: String, default: '/login?continue={{url}}'
  field :logout_url,  type: String, default: '/auth/logout'
  field :internals,   type: Hash,   default: ->{ {} }
  field :config,      type: Hash,   default: ->{ {} }

  validates :name,   presence: true

  # Ensure we are only saving the host
  def domain=(dom)
    parsed = Addressable::URI.heuristic_parse(dom)
    super(parsed&.host.nil? ? nil : parsed.host.downcase)
  end

  def self.find_by_domain(name)
    Authority.where(domain: name.downcase).first
  end

  def as_json(options = {})
    super.tap do |json|
      json[:login_url] = self.login_url
      json[:logout_url] = self.logout_url
    end
  end

  # ==========================
  # Uploads controller helpers:
  # ==========================
  DEFAULT_BUCKET ||= ENV['DEFAULT_BUCKET']

  def get_bucket
    self.internals["storage_bucket"] || DEFAULT_BUCKET
  end

  def get_storage
    config = ::Condo::Configuration

    if self.internals["storage"]
      storage = self.internals["storage"].deep_symbolize_keys
      config.dynamic_residence(storage[:name], storage)
    else
      # Default storage service
      config.residencies[0]
    end
  end
end
