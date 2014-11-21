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
    
  def setup_welcome
    # Check to see if Welcome course exists already
    if welcome_course = current_courses.find{|c| c['name'] == welcome_to_canvas_name}
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

  def current_courses
    return @current_courses if @current_courses.present?
  
    if canvas.is_account_admin
      @current_courses = canvas.get_courses_for_account(welcome_to_canvas_name)
    else
      @current_courses = canvas.get_courses
    end

    while @current_courses.more? && @current_courses.length < 500 # Just in case we don't want to loop over courses forever
      @current_courses.next_page!
    end

    # Filter courses to only the ones we have control over.
    @current_courses = @current_courses.reject{|course| course['enrollments'].none?{|enrollment| ['teacher', 'designer'].include?(enrollment['type']) } }

  rescue Canvas::ApiError => ex
    raise Canvas::ApiError.new("Could not get current courses: #{ex}")
  end

  def create_subaccount(name)
    canvas.create_subaccount({account: {name: name}})
    rescue Canvas::ApiError => ex
      if CanvasWrapper.authorized_fail?(ex)
        nil
      else
        raise ex
      end
  end

  def find_or_create_course(course, sub_account_id)
    if existing_course = current_courses.find{|cc| course.course_code == cc['course_code']}
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

  def find_or_create_user(params)
    user = canvas.get_profile_by_sis_id(params['sis_user_id'])
    user = safe_create_user(params) unless user
    if !user
      # This is likely due to us using an sis_id and it being rejected. Try again without the sis id
      params.delete('sis_user_id')
      user = safe_create_user(params)
    end
    user
  end

  protected
    
    def safe_create_user(params)
      canvas.create_user(params)
    rescue Canvas::ApiError => ex
      if CanvasWrapper.server_error?(ex)
        nil
      else
        raise ex
      end
    end

    def canvas
      return @canvas if @canvas.present?
      token = self.user.authentications.find_by(provider_url: self.canvas_domain).token
      @canvas = CanvasWrapper.new(self.canvas_domain, token)
    end

end