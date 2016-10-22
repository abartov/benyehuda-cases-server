module Astrails
  module Auth
    class Mailer < ActionMailer::Base
      def password_reset_instructions(user)
        @domain = domain
        @user = user 
        @edit_password_url = edit_password_url(user.perishable_token)       
        mail to: user.email_recipient, from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: (_("%{domain}: Password Reset Instructions") % {:domain => domain})
      end

      def password_reset_confirmation(user)
        @domain = domain
        @user = user 
        @login_url = login_url
        mail to: user.email_recipient, from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: (_("%{domain}: Password Reset Notification") % {:domain => domain})
      end

      def activation_instructions(user)
        @domain = domain
        @user = user 
        @account_activation_url = activate_url(user.perishable_token)
        mail to: user.email_recipient, from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: (_("%{domain}: Account Activation Instructions") % {:domain => domain})
      end

      def activation_confirmation(user)
        @domain = domain
        @user = user 
        @login_url = login_url
        mail to: user.email_recipient, from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: (_("Welcome to %{domain}") % {:domain => domain})
      end

      protected

      def domain
        if domain = GlobalPreference.get(:domain)
          default_url_options[:host] = domain
        end
        @domain ||= domain
      end

    end
  end
end
