# frozen_string_literal: true

require "active_support/all"

module AuthTimestamps
  extend ActiveSupport::Concern

  included do
    field :created_at, type: Integer
    field :updated_at, type: Integer
  end

  def _create(options = {})
    now = Time.now.to_i
    self.created_at = now unless created_at_changed?
    self.updated_at = now unless updated_at_changed?
    super
  end

  def _update(attrs)
    self.updated_at = Time.now.to_i unless updated_at_changed?
    super(attrs.merge("updated_at" => @_attributes["updated_at"]))
  end

  def cache_key
    "#{super}-#{updated_at}"
  end

  def touch
    update!(updated_at: Time.now.to_i)
  end
end
