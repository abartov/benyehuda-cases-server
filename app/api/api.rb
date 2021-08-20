class API < Grape::API
  prefix 'api'
  format :json
  mount Login
  mount QueryByTitle
  mount CreateTask

  rescue_from Grape::Exceptions::ValidationErrors do |e|
    rack_response({
      status: e.status,
      error_msg: e.message,
    }.to_json, 400)
  end
end