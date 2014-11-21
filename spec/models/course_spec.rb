require 'rails_helper'

RSpec.describe Course, :type => :model do
  describe "content" do
    before do
      @course = FactoryGirl.create(:course)
    end
    it "should set values based on content json" do
      @course.course_code.should == "k12-algebra"
      @course.name.should == "Algebra 1A"
      @course.catridge.should == "HE-K12-algebra-master-export.imscc"
      @course.is_enabled.should == true
    end
    it "should set values based on content array and mark object not enabled" do
      content = @course.parsed
      content[:status] = ''
      course = FactoryGirl.create(:course, content.to_json)
      course.course_code.should == "k12-algebra"
      course.is_enabled.should == false
    end
  end
end
