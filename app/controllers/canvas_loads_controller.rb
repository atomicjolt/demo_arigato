class CanvasLoadsController < ApplicationController
  include ActionController::Live
  
  Mime::Type.register "text/event-stream", :stream

  before_action :set_canvas_load, only: [:show, :setup_course]

  def index
    @canvas_loads = current_user.canvas_loads
  end

  def show
  end

  def new
    @canvas_load = CanvasLoad.new(courses: sample_courses)
  end

  def create
    @canvas_load = current_user.canvas_loads.build(canvas_load_params)
    @canvas_load.canvas_domain = current_user.authentications.find_by_provider('canvas').provider_url
    if @canvas_load.save    
      render :create
    else
      render :new
    end
  end

  def setup_course

    subaccount_name = 'Canvas Demo Courses'
    response.headers['Content-Type'] = 'text/event-stream'
    sub_account_id = nil
    valid_teacher = false

    # For now just set this to false. Later if we want to add an option to the UI we can allow
    # users to be enrolled in existing courses not just the courses that were added in this iteration.
    enroll_in_existing_courses = false

    # We can update existing courses if we want to add an option to the UI. For now just create new ones. 
    always_create_courses = true

    begin
      response.stream.write "Starting setup. This will take a few moments...\n\n"
      if @canvas_load.sis_id.present?
        response.stream.write "Checking sisID...\n\n"
        if valid_teacher = @canvas_load.check_sis_id
          response.stream.write "Found valid user for teacher role.\n\n"
        else
          response.stream.write "Found no valid user for teacher role.\n\n" 
        end
      end

      if sub_account = @canvas_load.find_or_create_sub_account(subaccount_name)
        sub_account_id = sub_account[:sub_account]['id']
        if sub_account['existing']
          response.stream.write "Found Existing Sub Account #{subaccount_name}-------------------------------\n\n"
        else
          response.stream.write "Adding Sub Account -------------------------------\n\n"
          response.stream.write "Added sub account: #{subaccount_name}.\n\n"
        end
      else
        response.stream.write "You don't have permissions to add subaccount: #{subaccount_name}. Courses will be added to your default account.\n\n"
      end

      if @canvas_load.course_welcome
        response.stream.write "Checking for existing 'Welcome to Canvas' course.\n\n"
        if @canvas_load.setup_welcome(sub_account_id)
          response.stream.write "Preparing to create 'Welcome to Canvas' course.\n\n"
        else
          response.stream.write "Found a 'Welcome to Canvas' course -- won't create another.\n\n"
        end
      end

      response.stream.write "Adding Users -------------------------------\n\n"
      users = {}
      sample_users.each do |user|
        result = @canvas_load.find_or_create_user(user, sub_account_id)
        if result[:user] 
          users[user[:email]] = result[:user]
          if result[:existing]
            response.stream.write "Found existing user: #{user[:name]}.\n\n"
          else
            response.stream.write "Added user: #{user[:name]}.\n\n"
          end
        else
          response.stream.write "Couldn't find or add #{user[:name]}\n\n"
        end
      end

      response.stream.write "Adding Courses -------------------------------\n\n"
      courses = {}
      migrations = {}
      @canvas_load.courses.each do |course|
        result = @canvas_load.find_or_create_course(course, sub_account_id, always_create_courses)
        courses[course.sis_course_id] = result[:course]
        migrations[course.sis_course_id] = result[:migration] if result[:migration]
        if result[:existing]
          response.stream.write "#{course.name} already exists.\n\n"
        else
          response.stream.write "Added course: #{course.name}.\n\n"
        end
      end

      if users.present?
        response.stream.write "Adding Enrollments -------------------------------\n\n"
        
        if valid_teacher
          courses.each do |sis_course_id, course|
            @canvas_load.ensure_enrollment(valid_teacher['id'], course['id'], 'teacher')
            response.stream.write "Enrolled #{valid_teacher[:name]} in #{course['course_code']}\n\n"
          end
        end

        samples('enrollments').each do |enrollment|

          if user = users[enrollment[:email]]
             
            course = courses[enrollment[:sis_course_id]]

            if !course && enroll_in_existing_courses
              if course = @canvas_load.find_course_by_course_code(sub_account_id, enrollment[:sis_course_id])
                courses[enrollment[:sis_course_id]] = course
              end
            end

            if course
              course_code = course['course_code']
              begin
                @canvas_load.ensure_enrollment(user['id'], course['id'], enrollment[:type])
                response.stream.write "Enrolled #{enrollment[:name]} (#{enrollment[:email]}) in #{course_code}\n\n"
              rescue Canvas::ApiError => ex
                response.stream.write "Error #{enrollment[:name]} (#{enrollment[:email]}) in #{course_code}: #{ex}\n\n"
              end
            else
              if enroll_in_existing_courses
                response.stream.write "Could not enroll #{enrollment[:name]} (#{enrollment[:email]}). #{enrollment[:sis_course_id]} not available.\n\n"
              end
            end
          else
            response.stream.write "Could not find #{enrollment[:name]} (#{enrollment[:email]}) to enroll in #{enrollment[:sis_course_id]}\n\n"
          end
        end
      end

      
      ['discussions', 'assignments', 'quizzes', 'conversations', 'other_activities'].each do |type|
        response.stream.write "Adding #{type} -------------------------------\n\n"
        samples(type).each do |item|
          if course = courses[item[:sis_course_id]]
            case type
            when 'discussions'
              result = @canvas_load.canvas.create_discussion(course['id'], item['title'], item['message'])
              response.stream.write "Added #{item['title']}\n\n" if result['id']
            when 'assignments'

            when 'quizzes'

            when 'conversations'

            when 'other_activities'

            end
          end
        end
      end
    
      # Setup LTI tools
      courses.each do |sis_course_id, course|
        if @canvas_load.lti_attendance
          params = @canvas_load.lti_tool_params(
            Rails.application.secrets.lti_attendance_key, 
            Rails.application.secrets.lti_attendance_secret, 
            'https://rollcall.instructure.com/configure.xml')
          tool = @canvas_load.add_lti_tool(params, course['id'], sub_account_id)
          response.stream.write "Added Attendance LTI tool to #{course['course_code']}\n\n"
        end
        if @canvas_load.lti_chat
          params = @canvas_load.lti_tool_params(
            Rails.application.secrets.lti_chat_key,
            Rails.application.secrets.lti_chat_secret, 
            'https://chat.instructure.com/lti/configure.xml')
          tool = @canvas_load.add_lti_tool(params, course['id'], sub_account_id)
          response.stream.write "Added Chat LTI tool to #{course['course_code']}\n\n"
        end
      end

      completed_courses = {}
      while completed_courses.keys.length < migrations.keys.length
        migrations.each do |sis_course_id, migration|
          if completed_courses[sis_course_id].blank?
            course_code = courses[sis_course_id]['course_code']
            progress = @canvas_load.check_progress(migration)
            case progress['workflow_state']
            when 'queued'
              response.stream.write "#{course_code} is queued.\n\n"
            when 'running'
              response.stream.write "#{course_code} is #{progress['completion']}% complete. #{progress['message']}\n\n"
            when 'completed'
              completed_courses[sis_course_id] = true
              response.stream.write "#{course_code} is ready\n\n"
              response.stream.write %Q{Course url: #{@canvas_load.canvas_domain}/courses/#{courses[sis_course_id]['id']}\n\n}
            when 'failed'
              completed_courses[sis_course_id] = true
              response.stream.write "Failed to add content to #{course_code}.\n\n"
            else
              response.stream.write "#{course_code} entered an unknown state.\n\n"
            end
          end
        end
        sleep(3)
      end

    rescue IOError => ex # Raised when browser interrupts the connection
      response.stream.write "Error: #{ex}\n\n"
    rescue Canvas::ApiError => ex
      response.stream.write "Canvas Error: #{ex}\n\n"
    ensure
      response.stream.write "Finished!\n\n"
      response.stream.close # Prevents stream from being open forever
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_canvas_load
      @canvas_load = CanvasLoad.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def canvas_load_params
      params.require(:canvas_load).permit(:lti_attendance, :lti_chat, :user_id, :sis_id, :suffix, :course_welcome, courses_attributes: [:is_selected, :content])
    end

    def sample_courses
      courses = google_drive.load_spreadsheet(Rails.application.secrets.courses_google_id, Rails.application.secrets.courses_google_gid)
      map_array(courses, []).map{|course| Course.new(content: course.to_json) }
    end

    def sample_users
      users = google_drive.load_spreadsheet(Rails.application.secrets.users_google_id, Rails.application.secrets.users_google_gid)
      map_array(users, ['first_name', 'last_name'])
    end

    def samples(type)
      result = google_drive.load_spreadsheet(Rails.application.secrets["#{type}_google_id"], Rails.application.secrets["#{type}_google_gid"])
      map_array(result, [])
    end

    def map_array(data, reject_fields)
      header = data[0].map{|v| v.present? ? v.downcase : ''}
      results = data[1..data.length].map do |d| 
        header.each_with_index.inject({}) do |result, (key, index)| 
          result[key.to_sym] = d[index] unless d[index].blank? || reject_fields.include?(key)
          result
        end
      end
      if header.include?('status')
        results = results.reject{|u| u[:status] != 'active'}
        results.each{|r| r.delete(:status)}
      end
      results
    end

end
