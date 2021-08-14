require 'spec_helper'

describe Entities::ApiUserWithTokenEntity do
  describe 'fields' do
    subject(:subject) { Entities::ApiUserWithTokenEntity }
    specify { expect(subject).to represent(:email)}

    let!(:token) { create :api_token }
    specify 'presents the first available token' do
      json = Entities::ApiUserWithTokenEntity.new(token.api_user).as_json
      expect(json[:token]).to be_present
    end
  end
end