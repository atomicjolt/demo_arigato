user = CreateAdminService.new.call
puts 'CREATED ADMIN USER: ' << user.email

# Setup default accounts
if Rails.env.production?
  accounts = [{
    code: 'demoarigato',
    name: 'Demo Arigator',
    domain: 'http://demoarigato.herokuapp.com',
    lti_key: 'demoarigato',
    lti_secret: '81bb01a80454b7b5a587cfbf1e745d501c0f3b2e3e36b0e60240a2fe7ba8daac0b588678ca8dfaf0d4341017e6646d03751df63c4056a85e01a22e3ce72a8e29',
    canvas_uri: 'https://demo.instructure.com'
  }]
else
  accounts = [{
    code: 'demoarigato',
    name: 'Demo Arigator',
    domain: 'http://arigator.ngrok.com',
    lti_key: 'demoarigato',
    lti_secret: 'd52ca2c9892975bbb9def56e68eefe8e92a338d9b74d73ec5dad64803a376b2f1f5129c0bd9f7e73684526c234e0835bd1635e09d427cd45cb0de4296278682f',
    canvas_uri: 'https://atomicjolt.instructure.com'
  }]
end

# Setup accounts
accounts.each do |account|
  if a = Account.find_by(code: account[:code])
    a.update_attributes!(account)
  else
    Account.create!(account)
  end
end