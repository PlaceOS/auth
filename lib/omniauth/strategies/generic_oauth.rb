# frozen_string_literal: true

require "multi_json"
require "jwt"
require "omniauth/strategies/oauth2"

module OmniAuth
  module Strategies
    class GenericOauth < OmniAuth::Strategies::OAuth2
      option :name, "generic_oauth"

      uid do
        raw_info[options.client_options.info_mappings["uid"]].to_s
      end

      info do
        creds = credentials
        data = {}
        options.client_options.info_mappings.each do |key, value|
          value.split(",").each do |info_key|
            info_key = info_key.strip
            info_value = raw_info[info_key] || creds[info_key]
            if info_value
              data[key] = info_value
              break
            end
          end
        end
        data
      end

      extra do
        raw_info
      end

      def request_phase
        authid = request.params["id"]
        if authid.nil?
          raise "no auth definition ID provided"
        else
          set_options(authid)
        end

        super
      end

      def callback_phase
        authority = Authority.find_by_domain(request.host)
        authid = request.params["id"] || (authority.get_callback_uri || OauthStrat.where(authority_id: authority.id).order(:id).first.try(:id))

        # Set out details once again
        if authid.nil?
          raise "no auth definition ID provided"
        else
          set_options(authid)
        end

        super
      end

      def set_options(id)
        strat = OauthStrat.find(id)

        options.client_options.site = strat.site if strat.site
        options.client_options.authorize_url = strat.authorize_url if strat.authorize_url
        options.client_options.token_url = strat.token_url if strat.token_url
        options.client_options.token_method = strat.token_method.downcase.to_sym if strat.token_method
        options.client_options.auth_scheme = strat.auth_scheme.downcase.to_sym if strat.auth_scheme
        # options.client_options.authorize_path = strat.authorize_path  if strat.authorize_path (renamed to authorize_url)
        options.client_options.raw_info_url = strat.raw_info_url if strat.raw_info_url
        options.client_options.info_mappings = strat.info_mappings if strat.info_mappings
        options.client_options.ensure_matching = strat.ensure_matching || {}

        auth_params = strat.authorize_params || {}
        auth_params[:scope] = strat.scope
        options.authorize_params = auth_params

        options.client_id = strat.client_id
        options.client_secret = strat.client_secret

        # prevent csrf errors
        options.provider_ignores_state = true
      end

      def access_token_options
        options.access_token_options.transform_keys(&:to_sym)
      end

      # https://github.com/omniauth/omniauth/blob/ef7f7c2349e5cc2da5eda8ab1b1308a46685a5f5/lib/omniauth/strategy.rb#L438
      # https://github.com/zquestz/omniauth-google-oauth2/blob/414c43ef3ffec37d473321f262e80f1e46dda89f/lib/omniauth/strategies/google_oauth2.rb#L104
      def callback_url
        full_host + script_name + callback_path + "?id=#{request.params["id"]}"
      end

      def raw_info
        return @raw_info if @raw_info

        inf = access_token.get(options.client_options.raw_info_url).parsed
        required_matches = options.client_options.ensure_matching
        match = true
        required_matches.each do |field, options|
          checking = Array(inf[field.to_s])
          expressions = options.map { |str| Regexp.new(str, Regexp::IGNORECASE) }
          matches = false
          checking.each do |check|
            expressions.each do |regex|
              matching = regex.match(check)
              if matching
                matches = true
                break
              end
            end

            break if matches
          end

          if !matches
            match = false
            break
          end
        end
        raise "Invalid Hosted Domain" unless match

        @raw_info = inf
      end

      def prune!(hash)
        hash.delete_if do |_, value|
          prune!(value) if value.is_a?(Hash)
          value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end
      end

      def query_string
        request.query_string.empty? ? "" : "?#{request.query_string}"
      end
    end
  end
end
