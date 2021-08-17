class API < Grape::API
  prefix 'api'
  mount Login
  mount QueryByTitle
  rescue_from Grape::Exceptions::ValidationErrors do |e|
    byebug
    rack_response({
      status: e.status,
      error_msg: e.message,
    }.to_json, 400)
  end
end