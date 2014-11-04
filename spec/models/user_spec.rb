require 'rails_helper'

RSpec.describe User, :type => :model do

  before do
    @user = FactoryGirl.create(:user)
    @attr = {
      :name => "Example User",
      :email => "user@example.com",
      :password => "foobar",
      :password_confirmation => "foobar"
    }
  end

end