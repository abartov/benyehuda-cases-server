module Entities
  class ApiTaskEntity < Grape::Entity
    expose :task do
      expose :id
      expose :name
      expose :source
    end
  end
end