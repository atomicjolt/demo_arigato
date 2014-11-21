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
    true
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
    if welcome_course = search_courses(sub_account_id, welcome_to_canvas_name).find{|c| c['name'] == welcome_to_canvas_name}
      false
    else
      self.courses.create!(content: {
        course_code: "welcome-to-canvas",
        name: welcome_to_canvas_name,
        sis_course_id: nil,
        status: "active",
        catridge: "welcome-to-canvas-export.imscc"
      })
      true
    end
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
      sub_account
    else
      canvas.create_subaccount({account: {name: name}})
    end
    rescue Canvas::ApiError => ex
      if CanvasWrapper.authorized_fail?(ex)
        nil
      else
        raise ex
      end
  end

  def find_or_create_course(course, sub_account_id)
    if existing_course = search_courses(sub_account_id).find{|cc| course.course_code == cc['course_code']}
      {
        course: existing_course,
        existing: true
      }
    else
      course_params = course.parsed
      course_params.delete(:sis_course_id)
      canvas_course = canvas.create_course({course: course_params}, sub_account_id)
      course.update_attributes!(canvas_course_id: canvas_course['id'], canvas_account_id: canvas_course['account_id'])
      {
        course: canvas_course,
        existing: false
      }
    end
  end

  def find_or_create_user(params, sub_account_id = nil)
    if user = canvas.get_profile_by_sis_id(params[:sis_user_id])
      return {
        user: user,
        existing: true
      }
    end
    if user.blank?
      user_params = {
        user: {
          name: params[:name],
          short_name: params[:name]
        }, 
        pseudonym: {
          unique_id: params.delete(:email),
          password: params.delete(:password),
          sis_user_id: params.delete(:sis_user_id)
        }
      }
      user = safe_create_user(user_params, sub_account_id)
    end
    if user.blank?
      # This is likely due to us using an sis_id and it being rejected. Try again without the sis id and password
      user_params[:pseudonym].delete(:sis_user_id)
      user_params[:pseudonym].delete(:password)
      user = safe_create_user(user_params, sub_account_id)
    end
    {
      user: user,
      existing: false
    }
  end

  def ensure_enrollment(user_id, course_id, enrollment_type)
    canvas.enroll_user(course_id, { enrollment: { user_id: user_id, type: enrollment_type, enrollment_state: 'active' }})
  end

  protected
    
    def safe_create_user(params, sub_account_id)
      canvas.create_user(params, sub_account_id)
    rescue Canvas::ApiError => ex
      byebug
      nil
    end

    def canvas
      return @canvas if @canvas.present?
      token = self.user.authentications.find_by(provider_url: self.canvas_domain).token
      @canvas = CanvasWrapper.new(self.canvas_domain, token)
    end

end