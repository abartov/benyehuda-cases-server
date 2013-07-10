require 'spec_helper'

describe ReportController do

  describe "GET 'stalled'" do
    it "returns http success" do
      get 'stalled'
      response.should be_success
    end
  end

  describe "GET 'inactive'" do
    it "returns http success" do
      get 'inactive'
      response.should be_success
    end
  end

  describe "GET 'active'" do
    it "returns http success" do
      get 'active'
      response.should be_success
    end
  end

  describe "GET 'newvols'" do
    it "returns http success" do
      get 'newvols'
      response.should be_success
    end
  end

end
