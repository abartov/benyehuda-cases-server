class APIToken < ActiveRecord::Base
  belongs_to :api_user
  validates :token, presence: true
  scope :valid, -> { where( "expires_at = null OR expires_at > ?", Time.zone.now) }

  def self.generate(for_user)
    token = nil
    loop do
      token = Devise.friendly_token
      break token unless APIToken.where(token: token).first
    end
    new_token = APIToken.new(token: token, api_user: for_user, expires_at: 1.day.from_now)
    new_token.save!
    return new_token
  end
end
