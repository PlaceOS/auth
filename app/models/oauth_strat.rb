require_relative "application_record"

class OauthStrat < ApplicationRecord
  belongs_to :authority

  def type
    "oauths"
  end

  def type=(type)
    raise "bad type" unless type.to_s == "oauths"
  end

  def serializable_hash(**options)
    options = {
      methods: :type
    }.merge!(options)
    super(**options)
  end

  validates :authority_id, presence: true
  validates :name, presence: true
end
