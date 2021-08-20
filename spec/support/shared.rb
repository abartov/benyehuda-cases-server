RSpec.shared_examples 'json result' do
  specify 'returns JSON' do
    #puts 'returns JSON'
    api_call params
    expect { JSON.parse(response.body) }.not_to raise_error
  end
end

RSpec.shared_examples '400' do
  specify 'returns 400' do
    #puts 'returns 400'
    api_call params
    expect(response.status).to eq(400)
  end
end
RSpec.shared_examples '401' do
  specify 'returns 401' do
    #puts 'returns 401'
    api_call params
    expect(response.status).to eq(401)
  end
end

RSpec.shared_examples 'contains error msg' do |msg|
  specify "error msg is #{msg}" do
    #puts "error msg is {msg}"
    api_call params
    json = JSON.parse(response.body)
    expect(json['error'] || json['error_msg']).to eq(msg)
  end
end

RSpec.shared_examples '200' do
  specify 'returns 200' do
    #puts "returns 200"
    api_call params
    expect(response.status).to eq(200)
  end
end

RSpec.shared_examples 'restricted for developers' do
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
    end
  end
end

RSpec.shared_examples 'contains error code' do |code|
  specify "error code is #{code}" do
    #puts "error code is {code}"
    api_call params
    json = JSON.parse(response.body)
    expect(json['error_code']).to eq(code)
  end
end

RSpec.shared_examples 'contains error msg with devheader' do |msg|
  specify "error msg is #{msg}" do
    #puts "error msg is {msg}"
    api_call params
    json = JSON.parse(response.body)
    expect(json['error_msg']).to eq(msg)
  end
end

RSpec.shared_examples 'auditable created' do
  specify 'creates an api call audit' do
    #puts "creates an api call audit"
    expect do
      api_call params
    end.to change{ AuditLog.count }.by(1)
  end
end