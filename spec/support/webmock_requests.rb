require 'webmock/rspec'

# Don't allow real connections when testing
WebMock.disable_net_connect!(allow_localhost: true)

csv = "category,sourceid,shortname,longname,subaccount,coursefile,active\nk12-algebra,1019879,Algebra 1A,Algebra 1A,107740,HE-K12-algebra-master-export.imscc,FALSE\nk12-english,1076098,Language Arts 11B,Language Arts 11B,107741,K12-english-11-q3-master-export.imscc,TRUE\nk12-history,1040321,Social Studies 10A,Social Studies 10A,107736,social-studies-master-export.imscc,TRUE\nk12-kindergarten,669716,Kindergarten,Kindergarten,88846,,TRUE\nk12-grade5,1083185,Grade 5,Mr Stein's Grade 5,107783,K12-mr-steins-5th-grade-master-export.imscc,TRUE\nk12-music,1014879,Music,Introduction to Music,107739,K12-introduction-to-music-master-export.imscc,TRUE\nk12-earth,1025574,Earth Sciences,Earth Sciences,107737,K12-earth-sciences-master-export.imscc,TRUE\nhe-algebra,272987,Algebra 1,Introduction to Algebra,107797,HE-K12-algebra-master-export.imscc,FALSE\nhe-english,172727,American Lit,American Literature Since 1865,107791,,FALSE\nhe-history,985737,US History,US History,107792,us-history-master-export.imscc,TRUE\nhe-music,956085,Intro Music,Introduction to Music Theory,107816,HE-intro-to-music-theory-master-export.imscc,TRUE\nhe-geol,1012890,Intro Geology,Intro to Geology,88946,HE-introduction-to-geology-master-export.imscc,TRUE\ndemo-course00,1012890,Geology Student Demo,Intro to Geology Student Demo,88946,HE-introduction-to-geology-master-export.imscc,TRUE\ncorp-prof-learn,,Professional Learning,Kick-Start Your Own Professional Learning,,corp-kick-start-your-own-professional-learning-export.imscc,TRUE"


RSpec.configure do |config|
  config.before(:each) do

    # Google
    stub_request(:get, %r|http[s]*://docs.google.com/spreadsheets/export\?exportFormat=csv&id=.+|).
      to_return(:status => 200, :body => csv, :headers => {})

    # Canvas
    stub_request(:get, %r|http[s]*://canvas.instructure.com/api/v1/users/sis_user_id:.+/profile\?access_token=atoken|).
      with(:headers => {'User-Agent'=>'CanvasAPI Ruby'}).
      to_return(:status => 200, :body => "", :headers => {})

    stub_request(:get, %r|http[s]*://canvas.instructure.com/api/v1/.+/accounts/self\?access_token=atoken|).
      with(:headers => {'User-Agent'=>'CanvasAPI Ruby'}).
      to_return(:status => 200, :body => "", :headers => {})

    stub_request(:get, "http://canvas.instructure.com/api/v1//accounts/self?access_token=atoken").
      with(:headers => {'User-Agent'=>'CanvasAPI Ruby'}).
      to_return(:status => 200, :body => "{\"errors\":[{\"message\":\"The specified resource does not exist.\"}],\"error_report_id\":35651642}", :headers => {})

  end
end