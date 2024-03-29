class Login < Grape::API
  format :json
  desc 'End-points for the Login'
  namespace :login do
    desc 'Login via email and password'
    params do
      requires :email, type: String, desc: 'email'
      requires :password, type: String, desc: 'password'
    end
    post do
      user = APIUser.find_by_email params[:email]
      if user.present? && user.valid_password?(params[:password])
        token = user.api_tokens.valid.first || APIToken.generate(user)
        status 200
        present token.api_user, with: Entities::ApiUserWithTokenEntity
      else
        error_msg = 'Bad Authentication Parameters'
        error!({ 'error_msg' => error_msg }, 401)
      end
    end
  end
end