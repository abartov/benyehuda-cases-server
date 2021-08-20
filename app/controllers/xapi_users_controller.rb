require 'securerandom'

class XapiUsersController < InheritedResources::Base
  before_action :require_admin
  defaults resource_class: APIUser

    def api_user_params
      params.require(:api_user).permit(:api_key, :email)
    end

    def index
      @api_users = APIUser.all
    end
    def new
      @api_user = APIUser.new(api_key: SecureRandom.hex)
    end
    def create
      params.permit!
      super
    end
    def show
      @api_user = APIUser.find(params[:id])
    end
    def edit
      @api_user = APIUser.find(params[:id])
    end
    def update
      params.permit!
      super
    end
end
