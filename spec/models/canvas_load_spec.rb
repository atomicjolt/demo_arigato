require 'rails_helper'

RSpec.describe CanvasLoad, :type => :model do
  
  before do
    @provider_url = 'http://canvas.instructure.com'
    @user = FactoryGirl.create(:user)
    @authentication = FactoryGirl.create(:authentication, user: @user, provider: 'canvas', provider_url: @provider_url, token: 'atoken')
    @canvas_load = FactoryGirl.create(:canvas_load, user: @user, sis_id: 1234, course_welcome: true, canvas_domain: @provider_url)
    @cartridge_course = FactoryGirl.create(:cartridge_course)
    @canvas_load.cartridge_courses << @cartridge_course
  end

  describe "check_sis_id" do
    it "checks for a valid sis id" do
      @canvas_load.check_sis_id
    end
  end

  describe "setup_welcome" do
    it "sets up the welcome course if specified" do
      @canvas_load.setup_welcome
    end
  end

end
