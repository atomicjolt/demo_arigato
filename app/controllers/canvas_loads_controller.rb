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
        response.stream.write "Adding Sub Account -------------------------------\n\n"
        sub_account_id = sub_account['id']
        response.stream.write "Added sub account: #{subaccount_name}.\n\n"
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
        result = @canvas_load.find_or_create_course(course, sub_account_id)
        courses[course.course_code] = result[:course]
        migrations[course.course_code] = result[:migration] if result[:migration]
        if result[:existing]
          response.stream.write "#{course.name} already exists.\n\n"
        else
          response.stream.write "Added course: #{course.name}.\n\n"
        end
      end

      if users.present?
        response.stream.write "Adding Enrollments -------------------------------\n\n"
        
        if valid_teacher
          courses.each do |course_code, course|
            @canvas_load.ensure_enrollment(valid_teacher['id'], course['id'], 'teacher')
            response.stream.write "Enrolled #{valid_teacher[:name]} in #{course_code}\n\n"
          end
        end

        sample_enrollments.each do |enrollment|

          if user = users[enrollment[:email]]
             
            course = courses[enrollment[:course_code]]
            
            if !course
              if course = @canvas_load.find_course_by_course_code(sub_account_id, enrollment[:course_code])
                courses[enrollment[:course_code]] = course
              end
            end

            if course
              begin
                @canvas_load.ensure_enrollment(user['id'], course['id'], enrollment[:type])
                response.stream.write "Enrolled #{enrollment[:name]} (#{enrollment[:email]}) in #{enrollment[:course_code]}\n\n"
              rescue Canvas::ApiError => ex
                response.stream.write "Error #{enrollment[:name]} (#{enrollment[:email]}) in #{enrollment[:course_code]}: #{ex}\n\n"
              end
            else
              response.stream.write "Could not enroll #{enrollment[:name]} (#{enrollment[:email]}). #{enrollment[:course_code]} not available.\n\n"
            end
          else
            response.stream.write "Could not find #{enrollment[:name]} (#{enrollment[:email]}) to enroll in #{enrollment[:course_code]}\n\n"
          end
        end
      end

      completed_courses = {}
      while completed_courses.keys.length < migrations.keys.length
        migrations.each do |course_code, migration|
          if completed_courses[course_code].blank?
            progress = @canvas_load.check_progress(migration)
            case progress['workflow_state']
            when 'queued'
              response.stream.write "#{course_code} is queued.\n\n"
            when 'running'
              response.stream.write "#{course_code} is #{progress['completion']}% complete. #{progress['message']}\n\n"
            when 'completed'
              completed_courses[course_code] = true
              response.stream.write "#{course_code} is ready.\n\n"
            when 'failed'
              completed_courses[course_code] = true
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

    def sample_enrollments
      enrollments = google_drive.load_spreadsheet(Rails.application.secrets.enrollments_google_id, Rails.application.secrets.enrollments_google_gid)
      map_array(enrollments, [])
    end

    def map_array(data, reject_fields)
      header = data[0].map{|v| v.downcase}
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
