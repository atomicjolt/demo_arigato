# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  factory :authentication do
    user
    provider { FactoryGirl.generate(:name) }
  end

end
