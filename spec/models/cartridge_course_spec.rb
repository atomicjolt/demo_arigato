require 'rails_helper'

RSpec.describe CartridgeCourse, :type => :model do
  describe "content" do
    it "should set values based on content string" do
      content = ["k12-algebra", "1019879", "Algebra 1A", "Algebra 1A", "107740", "HE-K12-algebra-master-export.imscc", "TRUE"]
      course = CartridgeCourse.new(content: content)
      course.category.should == "k12-algebra"
      course.source_id.should == 1019879
      course.short_name.should == "Algebra 1A"
      course.long_name.should == "Algebra 1A"
      course.sub_account.should == 107740
      course.course_file.should == "HE-K12-algebra-master-export.imscc"
      course.is_enabled.should == true
    end
    it "should set values based on content array and mark object not enabled" do
      content = ["k12-algebra", "1019879", "Algebra 1A", "Algebra 1A", "107740", "HE-K12-algebra-master-export.imscc", "FALSE"].join(',')
      course = CartridgeCourse.new(content: content)
      course.category.should == "k12-algebra"
      course.is_enabled.should == false
    end
    it "should set values based on content array" do
      content = ["k12-algebra", "1019879", "Algebra 1A", "Algebra 1A", "107740", "HE-K12-algebra-master-export.imscc", "TRUE"].join(',')
      course = CartridgeCourse.new(content: content)
      course.category.should == "k12-algebra"
      course.source_id.should == 1019879
      course.short_name.should == "Algebra 1A"
      course.long_name.should == "Algebra 1A"
      course.sub_account.should == 107740
      course.course_file.should == "HE-K12-algebra-master-export.imscc"
      course.is_enabled.should == true
    end
  end
end
