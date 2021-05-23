class RestartController < ApplicationController
  #verify :method => :post, :redirect_to => "/"
  before_action :require_admin

  def restart
    system("touch #{RAILS_ROOT}/tmp/restart.txt")
    redirect_to "/"
  end
end
