require 'rails_helper'

RSpec.describe CanvasLoad, :type => :model do
  
  before do
    @provider_url = 'http://canvas.instructure.com'
    @user = FactoryGirl.create(:user)
    @authentication = FactoryGirl.create(:authentication, user: @user, provider: 'canvas', provider_url: @provider_url, token: 'atoken')
    @canvas_load = FactoryGirl.create(:canvas_load, user: @user, sis_id: 1234, course_welcome: true, canvas_domain: @provider_url)
    @course = FactoryGirl.create(:course)
    @canvas_load.courses << @course
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

  describe "search_courses" do
    it "retrieves courses for the current user" do
      @canvas_load.search_courses
    end
  end

  describe "find_or_create_sub_account" do
    context "user has permissions to create an account" do
      it "creates a new subaccount with the given name" do
        name = 'test'
        @canvas_load.find_or_create_sub_account(name)
      end
    end
    context "user doesn't have permission to create a sub account" do
      it "returns nil" do
        @canvas_load.find_or_create_sub_account('test')
      end
    end
  end

  describe "find_or_create_course" do
    context "course exists" do
      it "returns the existing course" do
        course = FactoryGirl.create(:course)
        @canvas_load.find_or_create_course(course)
      end
    end
  end

  describe "find_or_create_user" do
    user_params = {
      name "John Doe"
    }
    @canvas_load.find_or_create_user(user_params)
  end

end

