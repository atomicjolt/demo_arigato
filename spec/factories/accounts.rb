# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  
  factory :account do
    name { FactoryGirl.generate(:name) }
    lti_key { FactoryGirl.generate(:lti_key) }
    domain { FactoryGirl.generate(:domain) }
    canvas_uri { FactoryGirl.generate(:domain) }

  end
end
