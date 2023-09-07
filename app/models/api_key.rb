require 'openssl'

class ApiKey < ApplicationRecord
  self.table_name = "api_key"

  def self.find_key!(token)
    id, secret = token.split('.', 2)

    model = self.find(id)

    # Same error as being unable to find the model
    digest = OpenSSL::Digest.new('sha512')
    hmac = OpenSSL::HMAC.hexdigest(digest, secret, id)
    if model.secret != hmac
      raise "invalid API key"
    end

    model
  end
end
