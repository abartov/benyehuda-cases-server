require 'rails_helper'

RSpec.describe 'Users anniversary greeting', type: :request do
  let(:editor) { create(:user, :editor, :active_user) }
  let(:volunteer) { create(:user, :volunteer, :active_user, created_at: 2.years.ago) }

  before do
    # Log in as editor using Authlogic test helpers
    post '/user_sessions', params: { user_session: { email: editor.email, password: 'qweqwe' } }
  end

  describe 'POST /users/:id/send_anniversary_greeting' do
    context 'when the volunteer has not suppressed anniversary greetings' do
      it 'sends the greeting and returns success' do
        allow(Notification).to receive_message_chain(:anniversary_greeting, :deliver_now)

        post send_anniversary_greeting_user_path(volunteer), params: { message: 'Congratulations!' }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
      end

      it 'updates the congratulated_at timestamp' do
        allow(Notification).to receive_message_chain(:anniversary_greeting, :deliver_now)

        expect {
          post send_anniversary_greeting_user_path(volunteer), params: { message: 'Congratulations!' }
        }.to change { volunteer.reload.congratulated_at }.from(nil)
      end
    end

    context 'when the volunteer has suppressed anniversary greetings' do
      let(:volunteer) do
        create(:user, :volunteer, :active_user,
               created_at: 2.years.ago,
               suppress_anniversary_greeting: true)
      end

      it 'returns an error and does not send the email' do
        expect(Notification).not_to receive(:anniversary_greeting)

        post send_anniversary_greeting_user_path(volunteer), params: { message: 'Congratulations!' }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
      end

      it 'does not update the congratulated_at timestamp' do
        expect(Notification).not_to receive(:anniversary_greeting)

        expect {
          post send_anniversary_greeting_user_path(volunteer), params: { message: 'Congratulations!' }
        }.not_to change { volunteer.reload.congratulated_at }
      end
    end
  end

  describe 'PUT /users/:id (profile update)' do
    context 'when a volunteer updates their own suppress_anniversary_greeting preference' do
      before do
        # Log out the editor and log in as the volunteer
        delete '/user_sessions'
        post '/user_sessions', params: { user_session: { email: volunteer.email, password: 'qweqwe' } }
      end

      it 'saves the preference when set to true' do
        put user_path(volunteer), params: {
          user: { suppress_anniversary_greeting: '1' }
        }

        expect(volunteer.reload.suppress_anniversary_greeting).to be true
      end

      it 'clears the preference when set to false' do
        volunteer.update!(suppress_anniversary_greeting: true)

        put user_path(volunteer), params: {
          user: { suppress_anniversary_greeting: '0' }
        }

        expect(volunteer.reload.suppress_anniversary_greeting).to be false
      end
    end
  end
end
