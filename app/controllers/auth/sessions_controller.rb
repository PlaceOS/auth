# encoding: UTF-8

require 'net/http'
require 'uri'
require 'set'

module Auth
  class SessionsController < CoauthController
    SKIP_PARAMS = Set.new(['urls', 'Website']) # Params we don't want to send to register

    # Inline login
    def new
      details = params.permit(:provider, :continue, :id)
      remove_session
      set_continue(details[:continue])
      uri = "/auth/#{details[:provider]}"

      # Support generic auth sources
      uri = "#{uri}?id=#{details[:id]}" if details[:id]
      redirect_to uri, :status => :see_other
    end

    # Local login
    def signin
      details = params.permit(:email, :password, :continue)
      authority = current_authority

      user = User.find_by_email(authority.id, details[:email])

      if user && user.authenticate(details[:password])
        path = details[:continue] || cookies.encrypted[:continue]
        remove_session
        new_session(user)

        # If there is a path we are using an inline login form
        if path
          redirect_to path
        else
          head :accepted
        end

        self.instance_exec user, "internal", nil, &Authentication.after_login_block
      else
        login_failure(details)
      end
    end

    # Run each time a user logs in via social
    def create
      # Where do we want to redirect to with our new session
      path = cookies.encrypted[:continue] || success_path

      # Get auth hash from omniauth
      auth = request.env['omniauth.auth']
      return login_failure({}) if auth.nil?

      # Find an authentication or create an authentication
      authority = current_authority
      auth_model = Authentication.from_omniauth(authority.id, auth)
      args = safe_params(auth.info)

      # adding a new auth to existing user
      if auth_model.nil? && signed_in?
        user = current_user
        user.assign_attributes(args)
        user.save

        Authentication.create_with_omniauth(authority.id, auth, user.id)
        redirect_to path
        self.instance_exec user, auth['provider'], auth, &Authentication.after_login_block

      # new auth and new user
      elsif auth_model.nil?
        user = ::User.new(args)

        # Use last name and first name by preference
        fn = args[:first_name]
        if fn && !fn.empty?
          user.name = "#{fn} #{args[:last_name]}"
        end

        user.authority_id = authority.id

        # This fixes issues where users change their UID
        if authority.internals[:trusted_authsource]
          existing = ::User.find_by_email(authority.id, user.email)
          if existing
            user = existing
            user.deleted = false
            user.assign_attributes(args)
          end
        end

        # now the user record is initialised (but not yet saved), give
        # the installation the opportunity to modify the user record or
        # reject the signup outright
        result = self.instance_exec user, auth['provider'], auth, &Authentication.before_signup_block
        logger.info "Creating new user: #{result.inspect}\n#{user.inspect}"

        if result != false && user.save
          # user is created, associate an auth record or raise exception
          Authentication.create_with_omniauth(authority.id, auth, user.id)

          # make the new user the currently logged in user
          remove_session
          new_session(user)

          # redirect the user to the page they were trying to access and
          # run any custom post-login actions
          redirect_to path
          self.instance_exec user, auth['provider'], auth, &Authentication.after_login_block
        else
          info = "User creation failed with #{auth.inspect}"
          errors = "User model errors: #{user.errors.messages}"
          logger.warn info
          logger.info errors

          # user save failed (db or validation error) or the before
          # signup block returned false. redirect back to a signup
          # page, where /signup is a required client side path.
          store_social(auth['uid'], auth['provider'])

          response.headers['x-aca-user-info'] = auth.inspect
          response.headers['x-aca-user-errors'] = errors.inspect
          redirect_to "#{authority.internals[:signup_path] || '/signup/index.html'}?#{auth_params_string(auth.info)}"
        end

      # existing auth and existing user
      else
        begin
          # Log-in the user currently authenticating
          user = User.find?(auth_model.user_id)

          # There is no user model, so we want to recover from this automatically
          if user.nil?
            auth_model.destroy
            return create
          end
          remove_session if signed_in?

          user.assign_attributes(args)
          user.save
          new_session(user)
          redirect_to path
          self.instance_exec user, auth['provider'], auth, &Authentication.after_login_block
        rescue => e
          logger.error "Error with user account. Possibly due to a database failure:\nAuth model: #{auth_model.inspect}\n#{e.inspect}"
          raise e
        end
      end
    end

    # Log off
    def destroy
      remove_session

      # do we want to redirect externally?
      path = params.permit(:continue)[:continue] || '/'

      if path.include?("://")
          authority = current_authority
          uri = Addressable::URI.parse(path)

          if uri.domain == authority.domain
            path = "#{uri.request_uri}#{uri.fragment ? "##{uri.fragment}" : nil}"
          else
            path = authority.logout_url
            if path.include?("continue=")
              path = URI.decode_www_form_component(path.split("continue=", 2)[-1])
            end
          end
      end

      redirect_to path
    end


    protected


    def safe_params(authinfo)
      ::ActionController::Parameters.new(authinfo).permit(
        :name, :first_name, :last_name, :email, :password, :password_confirmation, :metadata,
        :login_name, :staff_id, :phone, :country, :nickname, :image, :ui_theme, :building,
        :card_number, :access_token, :refresh_token, :expires_at, :expires
      )
    end

    def auth_params_string(authinfo)
      authinfo.map { |k,v| "#{k}=#{URI.encode_www_form_component(v)}" unless SKIP_PARAMS.include?(k)}.compact.join('&')
    end

    def login_failure(details)
      path = details[:continue]
      if path
        # TODO:: need to add query component to indicate that the request was a failure
        redirect_to request.referer || '/' # login failed, reload the page
      else
        head :unauthorized
      end
    end
  end
end
