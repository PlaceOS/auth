# encoding: UTF-8

#
# Define the various storage providers you would like to upload to here.
#   Amazon S3 and Google are the only fully featured providers
#
# NOTE:: The first definition is treated as the default.
#   It is possible to dynamically set the provider from the controller without configuring anything here
# => http://www.elastician.com/2009/12/comprehensive-list-of-aws-endpoints.html
#

# Microsoft Azure
#opts = {
#   :account_name => ENV['AZURE_ACCOUNT'],
#   :access_key => ENV['AZURE_SECRET']
#}
#Condo::Configuration.add_residence(:MicrosoftAzure, opts)

# Excon.defaults[:ssl_verify_peer] = false
# Condo::Configuration.add_residence(:OpenStackSwift, {
#      username: 'admin:admin',
#      secret_key: 'changeme',
#      storage_url: 'AUTH_admin',
#      auth_url: 'https://swift.domain.com/auth/v1.0',
#      location: 'https://swift.domain.com',
#      temp_url_key: 'zy14opzraEcjcAUTruOidDoZ6UInjNHLfMNNc60WA',
#      bucket_name: 'cotag',
#      scheme: 'https' #or http (update the above two urls)
# })

#
# Enable if you would like to use this provider
#
#Condo::Configuration.add_residence(:GoogleCloudStorage, {
#   :access_id => ENV['GOOGLE_KEY'],
#   :secret_key => ENV['GOOGLE_SECRET']
#})

#
# Enable this if you would like to use v2 of Google's storage API (https://developers.google.com/storage/docs/accesscontrol#Signed-URLs)
# => Convert cert to PEM: openssl pkcs12 -in file/name.p12 - nodes -nocerts > out/put.pem
# => NOTE:: The password is: notasecret
#
#Condo::Configuration.add_residence(:GoogleCloudStorage, {
#   :access_id => ENV['GOOGLE_KEY'],            # Service account email
#   :secret_key => File.read('google.pem'),     # Private key in pem format (don't use this location ;)
#   :api => 2
#})

=begin
Excon.defaults[:ssl_verify_peer] = false
Condo::Configuration.add_residence(:OpenStackSwift, {
    :username => ENV['RACKS_KEY'],

    # This is the API key
    :secret_key => ENV['RACKS_SECRET'],

    # Something like (MossoCloudFS_abf330f5-5f4e-48be-9993-b5dxxxxxx)
    # Basically your account identifier
    :storage_url => ENV['RACKS_STORAGE_URL'],
    :temp_url_key => ENV['RACKS_TEMP_URL_KEY']
})
=end

# AWS S3 bucket permissions will need to be set: https://docs.google.com/document/d/1zd5kCB0QH7GmVSnyjVRscILn5l-r_Xp_hvV4Vv9v9Ig/edit#
if ENV['S3_KEY']
  Condo::Configuration.add_residence(:AmazonS3, {
      access_id:  ENV['S3_KEY'],
      secret_key: ENV['S3_SECRET'],
      location:   ENV['S3_REGION'] || 'ap-southeast-2'
  })
end
