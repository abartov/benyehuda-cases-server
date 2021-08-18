require 'spec_helper'
describe '/api/create_task' do
  let(:api_user) { create :api_user}
  let!(:task_kind) {create :task_kind, name: 'סריקה'}
  let(:original_params) { { title: 'אל הציפור', author: 'חיים נחמן ביאליק', creator_id: 11, api_key: api_user.api_key} } # counting on a Task seeded in seeds.rb
  let(:params) { original_params }

  def api_call(params)
    post("/api/create_task", params: params)
  end

  context 'negative tests' do
    context 'invalid params' do
      context 'incorrect key' do
        let(:params) { original_params.merge(api_key: 'invalid') }
    
        it_behaves_like '401'
        it_behaves_like 'json result'
        it_behaves_like 'auditable created'
    
        it_behaves_like 'contains error msg with devheader', 'invalid developer key'
        it_behaves_like 'contains error code', ErrorCodes::BAD_AUTHENTICATION_PARAMS
      end

      context 'missing key' do
        let(:params) { original_params.except(:api_key) }
        it_behaves_like '401'
        it_behaves_like 'json result'
        it_behaves_like 'contains error msg with devheader', 'please acquire a developer key'
        it_behaves_like 'contains error code', ErrorCodes::DEVELOPER_KEY_MISSING
      end
      context 'missing required params' do
        let(:params) { original_params.except(:title) }
        it_behaves_like '400'
        it_behaves_like 'json result'
      end
    end
  end
  context 'positive tests' do
    context 'valid params' do
      it_behaves_like '200'
      it_behaves_like 'json result'
      specify "API returns the created task" do
        api_call params
        json = JSON.parse(response.body)
        expect(json).to include('task')  # TODO: implement
      end
    
   end
  end
end