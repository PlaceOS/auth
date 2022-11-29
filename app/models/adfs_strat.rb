require_relative "application_record"

class AdfsStrat < ApplicationRecord
  belongs_to :authority

  # Not actually sure what this type stuff is for?
  def type
    "adfs"
  end

  def type=(type)
    raise "bad type" unless type.to_s == "adfs"
  end

  def serializable_hash(**options)
    options = {
      methods: :type
    }.merge!(options)
    super(**options)
  end

  validates :authority_id, presence: true
  validates :name, presence: true
  validates :issuer, presence: true
  validates :idp_sso_target_url, presence: true
  validates :name_identifier_format, presence: true
  validates :assertion_consumer_service_url, presence: true
  validates :request_attributes, presence: true
end
