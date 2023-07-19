require_relative "application_record"
require "addressable/uri"

class Authority < ApplicationRecord
  self.table_name = "authority"

  validates :name, presence: true

  # Ensure we are only saving the host
  def domain=(dom)
    parsed = Addressable::URI.heuristic_parse(dom)
    super(parsed&.host.nil? ? nil : parsed.host.downcase)
  end

  def self.find_by_domain(name)
    find_by domain: name.downcase
  end

  def as_json(options = {})
    super.tap do |json|
      json[:login_url] = login_url
      json[:logout_url] = logout_url
    end
  end

  # ==========================
  # Uploads controller helpers:
  # ==========================

  DEFAULT_BUCKET = ENV["DEFAULT_BUCKET"]

  def get_bucket
    internals["storage_bucket"] || DEFAULT_BUCKET
  end

  def get_storage
    config = ::Condo::Configuration

    if internals["storage"]
      storage = internals["storage"].deep_symbolize_keys
      config.dynamic_residence(storage[:name], storage)
    else
      # Default storage service
      config.residencies[0]
    end
  end

  def get_callback_uri
    internals["default_callback_uri"]
  end
end
