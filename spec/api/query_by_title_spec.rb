require 'spec_helper'
describe '/api/query_by_title' do
  let(:api_user) { create :api_user}
  let!(:task1) {create :task, name: 'משימת בדיקה 1 / חיים נחמן ביאליק'}
  let!(:task2) {create :task, name: 'משימת בדיקה 2 / חיים נחמן ביאליק'}
  let!(:task3) {create :task, name: 'משימת בדיקה 3 / שאול טשרניחובסקי'}
  let(:original_params) { { title: 'ביאליק', api_key: api_user.api_key} } # counting on a Task seeded in seeds.rb
  let(:params) { original_params }

  def api_call(params)
    get("/api/query_by_title", params: params)
  end
  #it_behaves_like 'restricted for developers'

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
        it_behaves_like 'contains error msg with devheader', 'please aquire a developer key'
        it_behaves_like 'contains error code', ErrorCodes::DEVELOPER_KEY_MISSING
      end
    end
  end
  context 'positive tests' do
    context 'valid params' do
      it_behaves_like '200'
      it_behaves_like 'json result'
      specify "API returns a task" do
        api_call params
        json = JSON.parse(response.body)
        expect(json.length).to eq(2) 
      end
    
   end
  end
end