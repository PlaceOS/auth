# Here is the place to configure NoBrainer.
# We are using the default connection settings.
NoBrainer.configure do |config|
  # config.rethinkdb_url = ENV['RDB_URL'] || "rethinkdb://localhost/#{Rails.app.name}_#{Rails.env}"

  # 64kb
  config.max_string_length = 65_536
end

# NoBrainer.sync_indexes
