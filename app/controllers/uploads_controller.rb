# frozen_string_literal: true

require 'set'

class UploadsController < ApplicationController
  include Condo

  SUPPORTED_VIDEOS ||= Set.new(['.avi', '.mpg', '.mov', '.wmv', '.mpeg', '.webm', '.ogv', '.ogg', '.m4v', '.mp4', '.mkv', '.flv'])
  SUPPORTED_IMAGES ||= Set.new(['.jpg', '.jpeg', '.jpe', '.jif', '.jfif', '.jfi', '.webp', '.gif', '.png', '.bmp', '.tiff', '.tif'])
  SUPPORTED ||= Set.new
  SUPPORTED.merge(SUPPORTED_VIDEOS)
  SUPPORTED.merge(SUPPORTED_IMAGES)

  #
  # These are not defined by Condo
  #
  def index
    @@elastic ||= Elastic.new(condo_backend)
    # Index shouldn't need authorization as we will filter on
    # the user_id of the uploads we are collecting (eventually)
    query = @@elastic.query(params)
    results = @@elastic.search(query)
    # respond_with results
    render json: results
  end

  protected

  #
  # This is a request for the current user_id
  # We forward it to our current user method
  condo_callback :resident_id do
    current_user.id
  end

  #
  # Database entry needs to be updated here
  # We'll mark it as ready for processing
  condo_callback :upload_complete do |upload|
    upload.remove_entry
    true
    # TODO:: We should mark the upload as complete and ready for processing
    # We can time stamp with last processed to ensure processing

    # Remove if already converting
    # next
  end

  #
  # We need to mark an upload for processing
  # We then delete from the cloud before removing the database entry
  condo_callback :destroy_upload do |upload|
    current_residence.destroy(upload)
    upload.remove_entry

    # return true to indicate successful update
    true
  end

  # #
  # # Should return the bucket name for the current user
  # # Bucket should be created as a background user
  condo_callback :bucket_name do
    # 'tonsley' or 'hw-cotag' or 'acasignage'
    ENV['DEFAULT_BUCKET']
  end

  condo_callback :select_residence do |config, resident_id, upload|
    ::Condo::Configuration.residencies[0]
  end

  #
  # The name of the file when saved on the cloud storage system
  def self.generate_file_name(upload)
    "#{Time.now.to_f.to_s.sub('.', '')}#{rand(1000)}#{File.extname(upload[:file_name])}"
  end

  condo_callback :object_key, method(:generate_file_name)

  condo_callback :object_options do
    { permissions: :public }
  end
end
