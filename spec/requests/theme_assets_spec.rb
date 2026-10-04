require 'rails_helper'

RSpec.describe 'jQuery UI theme stylesheet assets', type: :request do
  it 'emits only theme image URLs that resolve' do
    css = Rails.application.assets['redmond/jquery-ui-1.7.2.custom.css'].to_s
    urls = css.scan(/url\(([^)]+)\)/).flatten.map { |u| u.delete('"\'') }.uniq

    expect(urls).not_to be_empty
    urls.each do |url|
      expect(url).to start_with('/assets/redmond/images/')
      get url
      expect(response).to have_http_status(:ok), "#{url} did not resolve (#{response.status})"
    end
  end
end
