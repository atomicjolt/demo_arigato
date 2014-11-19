require "rails_helper"

RSpec.describe CanvasLoadsController, :type => :controller do
  
  before do
    @user = FactoryGirl.create(:user)
    @authentication = FactoryGirl.create(:authentication, user: @user, provider: 'canvas', provider_url: 'http://canvas.instructure.com')
    @admin = FactoryGirl.create(:user, email: Rails.application.secrets.admin_email)
    @authentication = FactoryGirl.create(:authentication, user: @admin, provider: 'google')

    @canvas_load = FactoryGirl.create(:canvas_load, user: @user, sis_id: 1234, course_welcome: true, canvas_domain: @provider_url)
    @cartridge_course = FactoryGirl.create(:cartridge_course)
    @canvas_load.cartridge_courses << @cartridge_course
  end

  login_user

  describe "GET new" do
    it "displays a form for the user to enter Canvas demo course details" do
      get :new
      expect(response).to have_http_status(200)
    end
  end

  describe "POST create" do
    before do
      @params = {
        "lti_attendance"=>"1", 
        "lti_chat"=>"1", 
        "user_id"=>"213443",
        "suffix"=>"",
        "course_welcome"=>"0",
        "cartridge_courses_attributes"=>{
          "0"=>{
            "is_selected"=>"1",
            "content"=>"k12-english,1076098,Language Arts 11B,Language Arts 11B,107741,K12-english-11-q3-master-export.imscc,TRUE"
          }, 
          "1"=>{
            "is_selected"=>"0",
            "content"=>"k12-history,1040321,Social Studies 10A,Social Studies 10A,107736,social-studies-master-export.imscc,TRUE"
          }, 
          "2"=>{
            "is_selected"=>"0",
            "content"=>"k12-kindergarten,669716,Kindergarten,Kindergarten,88846,,TRUE"
          }, 
          "3"=>{
            "is_selected"=>"1",
            "content"=>"k12-grade5,1083185,Grade 5,Mr Stein's Grade 5,107783,K12-mr-steins-5th-grade-master-export.imscc,TRUE"
          }, 
          "4"=>{
            "is_selected"=>"0",
            "content"=>"k12-music,1014879,Music,Introduction to Music,107739,K12-introduction-to-music-master-export.imscc,TRUE"
          }, 
          "5"=>{
            "is_selected"=>"0",
            "content"=>"k12-earth,1025574,Earth Sciences,Earth Sciences,107737,K12-earth-sciences-master-export.imscc,TRUE"
          }, 
          "6"=>{
            "is_selected"=>"0",
            "content"=>"he-history,985737,US History,US History,107792,us-history-master-export.imscc,TRUE"
          }, 
          "7"=>{
            "is_selected"=>"0",
            "content"=>"he-music,956085,Intro Music,Introduction to Music Theory,107816,HE-intro-to-music-theory-master-export.imscc,TRUE"
          }, 
          "8"=>{
            "is_selected"=>"0",
            "content"=>"he-geol,1012890,Intro Geology,Intro to Geology,88946,HE-introduction-to-geology-master-export.imscc,TRUE"
          }, 
          "9"=>{
            "is_selected"=>"0",
            "content"=>"demo-course00,1012890,Geology Student Demo,Intro to Geology Student Demo,88946,HE-introduction-to-geology-master-export.imscc,TRUE"
          }, 
          "10"=>{
            "is_selected"=>"0",
            "content"=>"corp-prof-learn,,Professional Learning,Kick-Start Your Own Professional Learning,,corp-kick-start-your-own-professional-learning-export.imscc,TRUE"}
        }
      }
    end

    describe "Creates a Canvas load entry" do
      it "renders the create template" do
        post :create, {canvas_load: @params}
        expect(response).to have_http_status(200)
      end
      it "Adds selected catridge courses" do
        post :create, {canvas_load: @params}
        expect(assigns(:canvas_load).cartridge_courses.any?{|c| c.source_id == 1076098}).to be true
      end
      it "Doesn't add non-selected catridge courses" do
        post :create, {canvas_load: @params}
        expect(response).to have_http_status(200)
        expect(assigns(:canvas_load).cartridge_courses.any?{|c| c.source_id == 1040321}).to be false
      end
    end

    describe "setup_course" do
      it "Calls the Canvas API to setup the course" do
        expect(response.stream).to receive(:write).with("Checking sisID...")
        get :setup_course, id: @canvas_load
      end
      it "Writes the results of API calls to the response" do
        get :setup_course, id: @canvas_load
      end

    end

  end

end
