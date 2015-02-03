class CanvasLoad < ActiveRecord::Base
  belongs_to :user
  has_many :courses
  
  attr_accessor :response

  accepts_nested_attributes_for :courses, reject_if: proc { |a| a['is_selected'] != '1' }

  def welcome_to_canvas_name
    'Welcome to Canvas'
  end

  def check_sis_id
    sis_profile
  rescue Canvas::ApiError => ex
    if CanvasWrapper.no_exist_fail?(ex)
      false
    else
      raise ex
    end
  end

  def sis_profile
      @sis_profile ||= self.canvas.get_profile_by_sis_id(self.sis_id)
    end

  def setup_welcome(sub_account_id = nil)
    # Check to see if Welcome course exists already
    if welcome_course = search_courses(sub_account_id, welcome_to_canvas_name).find{|c| c['name'].include?(welcome_to_canvas_name)}
      false
    else
      self.courses.create!(content: {
        course_code: "welcome-to-canvas",
        name: welcome_to_canvas_name,
        sis_course_id: nil,
        status: "active",
        cartridge: "https://s3.amazonaws.com/SSL_Assets/sales/demo_courses/2015/welcome-to-canvas-export.imscc"
      }.to_json)
      true
    end
  end

  def find_course_by_course_code(sub_account_id, course_code)
    @courses_for_course_code ||= search_courses(sub_account_id)
    @courses_for_course_code.find{|cc| course_code == cc['course_code']}
  end

  def search_courses(sub_account_id = nil, search_term = nil)
    if canvas.is_account_admin
      found_courses = canvas.get_courses_for_account(sub_account_id, search_term)
    else
      found_courses = canvas.get_courses
      # Filter courses to only the ones we have control over.
      found_courses = found_courses.reject{|course| course['enrollments'].none?{|enrollment| ['teacher', 'designer'].include?(enrollment['type']) } }
    end

    while found_courses.more? && found_courses.length < 500 # Just in case we don't want to loop over courses forever
      found_courses.next_page!
    end

    found_courses
  rescue Canvas::ApiError => ex
    raise Canvas::ApiError.new("Could not get current courses: #{ex}")
  end

  def find_or_create_sub_account(name)
    sub_accounts = canvas.sub_accounts
    if sub_account = sub_accounts.find{|sa| sa['name'] == name}
      {
        sub_account: sub_account,
        existing: true
      }
    else
      sub_account = canvas.create_subaccount({account: {name: name}})
      {
        sub_account: sub_account,
        existing: false
      }
    end
    rescue Canvas::ApiError => ex
      if CanvasWrapper.authorized_fail?(ex)
        nil
      else
        raise ex
      end
  end
 
  def find_or_create_course(course, sub_account_id, always_create_courses = false)

    existing_course = search_courses(sub_account_id).find{|cc| course.course_code == cc['course_code']}  

    if !always_create_courses && existing_course
      return {
        course: existing_course,
        existing: true
      }
    end
    
    course_params = course.parsed

    if existing_course
      course_params[:sis_course_id] = "#{course_params[:sis_course_id]}_#{DateTime.now}" 
    end

    course_params[:name] << " - #{self.suffix}" # Add suffix to course name
    begin
      # try creating the course with the sis id
      canvas_course = canvas.create_course({course: course_params}, sub_account_id)
    rescue Canvas::ApiError => ex
      if CanvasWrapper.sis_taken_error?(ex)
        # If we get an error try it without the sis id
        #course_params.delete(:sis_course_id)
        course_params[:sis_course_id] = "#{course_params[:sis_course_id]}_#{DateTime.now}"
        canvas_course = canvas.create_course({course: course_params}, sub_account_id)
      else
        raise ex
      end
    end

    course.update_attributes!(canvas_course_id: canvas_course['id'], canvas_account_id: canvas_course['account_id'])
    
    migration = canvas.migrate_content(canvas_course['id'], {
      migration_type: 'common_cartridge_importer',
      settings: {
        file_url: course.cartridge
      }
    })
    # Publish the course
    canvas.update_course({offer: true}, canvas_course['id'])
    {
      course: canvas_course,
      migration: migration,
      existing: false
    }
    
  end

  def current_users
    return @current_users if @current_users
    @current_users = canvas.list_users # canvas.list_users(sub_account_id)
    while @current_users.more? && @current_users.length < 500 # Just in case we don't want to loop over users forever
      @current_users.next_page!
    end
    @current_users
  end

  def find_or_create_user(params, sub_account_id = nil)

    user_params = {
      "user[name]" => params[:name],
      "user[short_name]" => params[:name],
      "user[avatar][url]" => params[:avatar]
    }

    if user = canvas.get_profile_by_sis_id(params[:sis_user_id]) || current_users.find{|u| u['login_id'] == params[:email]}
      add_avatar(user, params)
      return {
        user: user,
        existing: true
      }
    end

    user_params["pseudonym[unique_id]"] = params[:email]
    user_params["pseudonym[password]"] = params[:password]
    user_params["pseudonym[sis_user_id]"] = "#{params[:sis_user_id]}_#{DateTime.now.to_i}"
    

    if user.blank?
      user = safe_create_user(user_params, sub_account_id)
    end
    
    if user.blank?
      # This is likely due to us using an sis_id and it being rejected. Try again without the sis id and password
      user_params.delete("pseudonym[sis_user_id]")
      user_params.delete("pseudonym[password]")
      user = safe_create_user(user_params, sub_account_id)
    end
    
    add_avatar(user, params)
    
    {
      user: user,
      existing: false
    }

  end

  def create_discussion(user_id, course_id, discussion)
    @discussions ||= {}
    @discussions[course_id] ||= {}
    reply = (discussion[:reply] || 'n').downcase
    title = discussion[:title].strip
    if reply == 'n'
      result = canvas.create_discussion(user_id, course_id, title, discussion[:message])
      @discussions[course_id][title] = result
    else
      if topic = @discussions[course_id][title]
        result = canvas.create_discussion_entry(user_id, course_id, topic['id'], discussion[:message])
      else
        result = canvas.create_discussion(user_id, course_id, title, discussion[:message])
        @discussions[course_id][title] = result
      end
    end
    result
  end

  def ensure_enrollment(user_id, course_id, enrollment_type)
    canvas.enroll_user(course_id, { enrollment: { user_id: user_id, type: "#{enrollment_type.capitalize}Enrollment", enrollment_state: 'active' }})
  end

  def check_progress(migration)
    progress_id = migration['progress_url'].split('/').last
    canvas.get_progress(progress_id)
  end

  def existing_tools(course_id, sub_account_id = nil)
    if sub_account_id
      @lti_tools ||= canvas.get_account_lti_tools(sub_account_id)
    else
      canvas.get_course_lti_tools(course_id)
    end
  end

  def lti_tool_params(key, secret, config_url)
    {
      name: key,
      domain: 'instructure.com',
      config_type: 'url',
      privacy_level: 'public',
      config_url: config_url,
      consumer_key: key,
      shared_secret: secret
    }
  end

  def create_lti_tool(params, course_id, sub_account_id = nil)
    if sub_account_id
      canvas.create_account_lti_tool(params, sub_account_id)
    else
      canvas.create_account_lti_tool(params, course_id)
    end
  end

  def add_lti_tool(params, course_id, sub_account_id = nil)
    tools = existing_tools(course_id, sub_account_id)
    if tool = tools.find{|t| t['name'] == params[:name]}
      existing = true
    else
      existing = false
      tool = create_lti_tool(params, course_id, sub_account_id)
    end
    {
      existing: existing,
      tool: tool
    }
  end

  def canvas
    return @canvas if @canvas.present?
    token = self.user.authentications.find_by(provider_url: self.canvas_domain).token
    @canvas = CanvasWrapper.new(self.canvas_domain, token)
  end

  protected
    
    def add_avatar(user, params)
      canvas.update_user(user['id'], { "user[avatar][url]" => params[:avatar] })
    end

    def safe_create_user(params, sub_account_id)
      canvas.create_user(params, sub_account_id)
    rescue Canvas::ApiError => ex
      nil
    end

end