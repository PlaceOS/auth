# frozen_string_literal: true

require 'multi_json'
require 'jwt'
require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class GenericOauth < OmniAuth::Strategies::OAuth2
      option :name, 'generic_oauth'

      uid do
        raw_info[options.client_options.info_mappings['uid']].to_s
      end

      info do
        data = {}
        options.client_options.info_mappings.each do |key, value|
          data[key] = raw_info[value]
        end
        data
      end

      def request_phase
        authid = request.params['id']
        if authid.nil?
          raise 'no auth definition ID provided'
        else
          set_options(authid)
        end
        super
      end

      def callback_phase
        authid = request.params['id']

        # Set out details once again
        if authid.nil?
          raise 'no auth definition ID provided'
        else
          set_options(authid)
        end

        super
      end

      def set_options(id)
        strat = OauthStrat.find(id)

        options.client_options.site = strat.site if strat.site
        options.client_options.authorize_url = strat.authorize_url if strat.authorize_url
        options.client_options.token_url = strat.token_url  if strat.token_url
        options.client_options.token_method = strat.token_method.downcase.to_sym if strat.token_method
        options.client_options.auth_scheme = strat.auth_scheme.downcase.to_sym if strat.auth_scheme
        # options.client_options.authorize_path = strat.authorize_path  if strat.authorize_path (renamed to authorize_url)
        options.client_options.raw_info_url = strat.raw_info_url if strat.raw_info_url
        options.client_options.info_mappings = strat.info_mappings if strat.info_mappings

        options.authorize_params.scope = strat.scope

        options.client_id = strat.client_id
        options.client_secret = strat.client_secret
      end

      def access_token_options
        options.access_token_options.inject({}) { |h,(k,v)| h[k.to_sym] = v; h }
      end

      # https://github.com/omniauth/omniauth/blob/ef7f7c2349e5cc2da5eda8ab1b1308a46685a5f5/lib/omniauth/strategy.rb#L438
      # https://github.com/zquestz/omniauth-google-oauth2/blob/414c43ef3ffec37d473321f262e80f1e46dda89f/lib/omniauth/strategies/google_oauth2.rb#L104
      def callback_url
        full_host + script_name + callback_path + "?id=#{request.params['id']}"
      end

      def raw_info
        @raw_info ||= access_token.get(options.client_options.raw_info_url).parsed
      end

      def prune!(hash)
        hash.delete_if do |_, value|
          prune!(value) if value.is_a?(Hash)
          value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end
      end

      def query_string
        request.query_string.empty? ? '' : "?#{request.query_string}"
      end
    end
  end
end
