module ApiHelpers
  module AuthenticationHelper
    def restrict_access_to_developers
      #byebug
      if params[:api_key].blank?
        error_code = ErrorCodes::DEVELOPER_KEY_MISSING
        error_msg = 'please aquire a developer key'
        error!({ :error_msg => error_msg, :error_code => error_code }, 401)
      else
        user = APIUser.where(api_key:  params[:api_key] )
        Rails.logger.info "API call: #{headers}\tWith params: #{params.inspect}" if ENV['DEBUG']
        if user.blank?
          begin
            raise
          rescue => e
            AuditLog.create data: "unauthenticated user access from #{request.ip}", backtrace: e.backtrace.to_s.truncate(250)
          end
          error_code = ErrorCodes::BAD_AUTHENTICATION_PARAMS
          error_msg = 'invalid developer key'
          error!({ :error_msg => error_msg, :error_code => error_code }, 401)
          # LogAudit.new({env:env}).execute
        end
      end
    end
  end
end