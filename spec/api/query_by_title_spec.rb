require 'spec_helper'
describe '/api/query_by_title' do
  let(:email) { api_user.email }
  let(:password) { api_user.password }
  let!(:api_user) { create :api_user }
  let(:original_params) { { email: email, password: password } }
  let(:params) { original_params }
  def api_call(params)
    get "/api/query_by_title", params: params
  end
  context 'negative tests' do
    context 'invalid params' do
      context 'missing title' do
        let(:params) { original_params.merge(password: 'invalid') }
        it_behaves_like '401'
        it_behaves_like 'json result'
        it_behaves_like 'contains error msg', 'Bad Authentication Parameters'
      end
      context 'with a non-existent login' do
        let(:params) { original_params.merge(email: 'invalid') }
        it_behaves_like '401'
        it_behaves_like 'json result'
        it_behaves_like 'contains error msg', 'Bad Authentication Parameters'
      end
    end
  end
  context 'positive tests' do
    context 'valid params' do
      it_behaves_like '200'
      it_behaves_like 'json result'

      specify 'returns the token as part of the response' do
        api_call params
        expect(JSON.parse(response.body)['token']).to be_present
      end
    end
  end
end