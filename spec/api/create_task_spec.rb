require 'spec_helper'
describe '/api/create_task' do
  let(:editor) { create :editor}
  let(:api_user_writer) { create :api_user, email: editor.email}
  let(:api_user) { create :api_user}
  let!(:task_kind) {create :task_kind, name: 'סריקה'}
  let(:original_params) { { title: 'אל הציפור', author: 'חיים נחמן ביאליק', api_key: api_user.api_key} } # counting on a Task seeded in seeds.rb
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
      context 'read-only access' do
        specify "API refuses to create task if api_key not associated with editor" do
          api_call params
          json = JSON.parse(response.body)
          expect(json['error'] || json['error_msg']).to eq('your API key is not allowed to change the database')
          expect(json['error_code']).to eq(ErrorCodes::KEY_WITHOUT_WRITE_ACCESS)
          expect(response.status).to eq(403)
        end
      end
    end
  end
  context 'positive tests' do
    context 'valid params' do
      let(:params) { original_params.merge(api_key: api_user_writer.api_key)}
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