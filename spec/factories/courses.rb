FactoryGirl.define do
  factory :course do
    canvas_load
    content: {
        course_code: "k12-algebra",
        name: "Algebra 1A",
        sis_course_id: 107740,
        status: "active",
        catridge: "HE-K12-algebra-master-export.imscc"
      }
  end

end
