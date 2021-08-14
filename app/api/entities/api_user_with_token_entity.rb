module Entities
  class ApiUserWithTokenEntity < ApiUserEntity
    expose :token do |user, options|
      user.api_tokens.valid.first.token
    end
  end
end