# encoding: UTF-8

require 'omniauth-saml'

::OneLogin::RubySaml::Attributes.single_value_compatibility = false
class ::OneLogin::RubySaml::Attributes
  @@single_value_compatibility = false
  def multi(name)
    attributes[canonize_name(name)].try { |attr| attr.length == 1 ? attr.first : attr.join(",") }
  end
end

module OmniAuth
  module Strategies
    class GenericAdfs < OmniAuth::Strategies::SAML
      include ::CurrentAuthorityHelper

      option :name, 'generic_adfs'

      def aca_configure_opts
        authid = request.params['id']
        if authid.nil?
          raise 'no auth definition ID provided'
        else
          set_options(authid)
        end
      end

      def request_phase
        aca_configure_opts
        session.clear
        super
      end

      def callback_phase
        aca_configure_opts
        super
      end

      def other_phase
        if current_path.start_with?(request_path)
          aca_configure_opts
          super
        else
          call_app!
        end
      end

      DEFAULT_CERT_VALIDATOR = lambda { |fingerprint| fingerprint }
      def set_options(id)
        strat = ::AdfsStrat.find(id)

        # Ensure this isn't some cross domain hacking attempt
        authority = current_authority.try(:id)
        raise 'invalid authentication source' unless authority == strat.authority_id

        # Map the database model to the strategy settings
        options.title = strat.name

        [
          :issuer, :name_identifier_format, :assertion_consumer_service_url,
          :idp_sso_target_url, :idp_slo_target_url, :slo_default_relay_state,
          :idp_sso_target_url_runtime_params, :idp_cert, :idp_cert_fingerprint,
          :request_attributes, :attribute_service_name, :attribute_statements,
          :uid_attribute
        ].each do |param|
          value = strat.__send__(param)
          options.__send__(:"#{param}=", value) if value.present?
        end

        options.allowed_clock_drift = 10.seconds

        if strat.idp_cert.present?
          options.idp_cert_fingerprint_validator = nil
        else
          options.idp_cert_fingerprint_validator = DEFAULT_CERT_VALIDATOR
        end
      end
    end
  end
end
