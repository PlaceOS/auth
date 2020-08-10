# encoding: UTF-8

require 'omniauth-ldap'
require 'omniauth/strategies/ldap'

module OmniAuth
  module Strategies
    class GenericLdap < OmniAuth::Strategies::LDAP
      include ::CurrentAuthorityHelper


      option :name, 'generic_ldap'


      def request_phase
        authid = request.params['id']
        if authid.nil?
          raise 'no auth definition ID provided'
        else
          set_options(authid)
        end

        session.clear
        session['omniauth.auth_id'] = authid

        super
      end

      def callback_phase
        authid = session.delete 'omniauth.auth_id'

        # Set out details once again
        if authid.nil?
          raise 'no auth definition ID provided'
        else
          set_options(authid)
        end

        super
      end

      def set_options(id)
        strat = LdapStrat.find(id)

        authority = current_authority.try(:id)
        raise 'invalid authentication source' unless authority == strat.authority_id

        options.title = strat.name
        options.port = strat.port
        options.method = strat.auth_method
        options.uid = strat.uid unless strat.filter
        options.host = strat.host
        options.base = strat.base
        options.bind_dn = strat.bind_dn
        options.password = strat.password
        options.filter = strat.filter if strat.filter
      end
    end
  end
end
