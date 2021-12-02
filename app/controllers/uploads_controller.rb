# frozen_string_literal: true

require "set"

class UploadsController < ApplicationController
  include Condo
  include CurrentAuthorityHelper

  before_action :check_authenticated

  protected

  # before filter auth checks
  # See ./config/initializers/doorkeeper for JWT format
  def check_authenticated
    payload, _header = get_jwt
    if payload
      head(:forbidden) if (request.host != payload["aud"]) && Rails.env.production?
    else
      head(:unauthorized)
    end
  end

  #
  # This is a request for the current user_id
  # We forward it to our current user method
  condo_callback :resident_id do
    payload, _header = get_jwt
    payload["sub"]
  end

  #
  # Database entry needs to be updated here
  # We'll mark it as ready for processing
  condo_callback :upload_complete do |upload|
    upload.remove_entry
    true
    # TODO: : We should mark the upload as complete and ready for processing
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

  # If we want to filter certain file types in the future
  # SUPPORTED = Set.new(['.png'])
  # condo_callback :pre_validation do
  #   if SUPPORTED.include? File.extname(@upload[:file_name]).downcase
  #     true
  #   else
  #     [false, {errors: {file_name: 'is not a supported file type'}}]
  #   end
  # end

  # #
  # # Should return the bucket name for the current user
  # # Bucket should be created as a background user
  condo_callback :bucket_name do
    current_authority.get_bucket
  end

  condo_callback :select_residence do |_config, _resident_id, _upload|
    current_authority.get_storage
  end

  #
  # The name of the file when saved on the cloud storage system
  condo_callback :object_key do |upload|
    "#{request.host}/#{Time.now.to_f.to_s.sub(".", "")}#{rand(1000)}#{File.extname(upload[:file_name])}"
  end

  # Defined here: https://github.com/cotag/Condominios/blob/5d1b297853e89c91afadcfeb48ab3f09ccff28b5/lib/condo.rb#L111
  # Mime types set here: https://github.com/cotag/Condominios/blob/5d1b297853e89c91afadcfeb48ab3f09ccff28b5/lib/condo/strata/amazon_s3.rb#L101
  # and https://github.com/cotag/Condominios/blob/5d1b297853e89c91afadcfeb48ab3f09ccff28b5/lib/condo/strata/open_stack_swift.rb#L122
  condo_callback :object_options do |_upload_object|
    file_mime = params[:file_mime].presence
    if file_mime
      {
        permissions: :public,
        headers: {
          "Content-Type" => file_mime
        }
      }
    else
      {permissions: :public}
    end
  end
end
