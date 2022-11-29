require_relative "application_record"

class LdapStrat < ApplicationRecord
  belongs_to :authority

  def type
    "ldaps"
  end

  def type=(type)
    raise "bad type" unless type.to_s == "ldaps"
  end

  def serializable_hash(**options)
    options = {
      methods: :type
    }.merge!(options)
    super(**options)
  end

  validates :authority_id, presence: true
  validates :name, presence: true
  validates :host, presence: true
  validates :base, presence: true
end
