module Astrails
  module Auth
    module Model
      def has_no_credentials?
        self.crypted_password.blank? # && self.openid_identifier.blank?
      end

      def active?
        !!activated_at
      end

      def acvivate!
        self.activated_at = Time.now
        save!
      end

      def deliver_password_reset_instructions!
        reset_perishable_token!
        ::Astrails::Auth::Mailer.password_reset_instructions(self).deliver
      end

      def deliver_password_reset_confirmation!
        reset_perishable_token!
        ::Astrails::Auth::Mailer.password_reset_confirmation(self).deliver
      end

      def deliver_activation_instructions!
        reset_perishable_token!
        ::Astrails::Auth::Mailer.activation_instructions(self).deliver
      end

      def deliver_activation_confirmation!
        reset_perishable_token!
        ::Astrails::Auth::Mailer.activation_confirmation(self).deliver
      end
    end
  end
end

