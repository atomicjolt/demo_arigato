class CanvasWrapper

  include HTTParty

  attr_accessor :account_id, :is_account_admin

  def initialize(canvas_uri, canvas_api_key)

    @canvas_uri = canvas_uri
    @canvas_api_key = canvas_api_key

    @canvas_api = Canvas::API.new(host: canvas_uri, token: canvas_api_key)
    @per_page = 100
    self.is_account_admin = false
    begin
      result = api_get_request("accounts/self")
      self.account_id = result['id']
      self.is_account_admin = true
    rescue Canvas::ApiError => ex
      if CanvasWrapper.authorized_fail?(ex)
        accounts = api_get_request("course_accounts")
        self.account_id = accounts.first['id']
      else
        raise ex
      end
    end
  end

  def headers
    {
      "Authorization" => "Bearer #{@canvas_api_key}",
      "content_type" => "json"
    }
  end

  def full_url(api_url)
    "/api/v1/#{api_url}"
  end

  def full_url_with_domain(api_url)
    "#{@canvas_uri}/api/v1/#{api_url}"
  end

  def api_post_request(api_url, payload)
    @canvas_api.post(full_url(api_url), payload)
  end

  def api_get_request(api_url)
    @canvas_api.get(full_url(api_url))
  end

  def api_put_request(api_url, payload)
    # The Canvas api gem fails on every put request. (Canvas returns a 100). Use HTTParty directly
    # @canvas_api.put(full_url(api_url), payload)
    HTTParty.put(full_url_with_domain(api_url), :headers => headers, :body => payload)
  end

  def current_account
    api_get_request("accounts/self")
  end

  def course_accounts
    api_get_request("course_accounts")
  end

  def accounts
    api_get_request("accounts")
  end
  
  def create_subaccount(params)
    api_post_request("accounts/#{account_id}/sub_accounts", params)
  end

  def sub_accounts
    api_get_request("accounts/#{account_id}/sub_accounts")
  end

  def create_course(params, sub_account_id = nil)
    api_post_request("accounts/#{sub_account_id || account_id}/courses?enroll_me=true", params)
  end

  def update_course(params, course_id = nil)
    api_put_request("courses/#{course_id}", params)
  end

  def migrate_content(course_id, params)
    api_post_request("courses/#{course_id}/content_migrations", params)
  end

  def get_progress(progress_id)
    api_get_request("progress/#{progress_id}")
  end

  def get_courses_for_account(sub_account_id = nil, search_term = nil)
    url = "accounts/#{sub_account_id || account_id}/courses?per_page=#{@per_page}"
    url << "&search_term=#{ERB::Util.url_encode(search_term)}" if search_term.present?
    api_get_request(url)
  end

  def assignments(course_id)
    api_get_request("courses/#{course_id}/assignments")
  end

  def discussion_topics(course_id)
    api_get_request("courses/#{course_id}/discussion_topics")
  end

  def get_courses(user_id = nil)
    request = "courses"
    request << "?as_user_id=#{user_id}" if user_id
    api_get_request(request)
  end

  def list_users(sub_account_id = nil)
    api_get_request("accounts/#{sub_account_id || account_id}/users")
  end

  def recent_logins(course_id)
    api_get_request("courses/#{course_id}/recent_students")
  end

  def students(course_id)
    api_get_request("courses/#{course_id}/users?enrollment_type=student")
  end

  def enroll_user(course_id, params)
    api_post_request("courses/#{course_id}/enrollments", params)
  end

  def course_participation(course_id, student_id)
    api_get_request("courses/#{course_id}/analytics/users/#{student_id}/activity")
  end

  def quiz_submissions(course_id, quiz_id)
    api_get_request("courses/#{course_id}/submissions")
  end

  def quizzes(course_id)
    api_get_request("courses/#{course_id}/quizzes")
  end

  def assignment_submissions(course_id)
    api_get_request("courses/#{course_id}/students/submissions?student_ids[]=all")
  end

  def student_assignment_data(course_id, student_id)
    api_get_request("courses/#{course_id}/analytics/users/#{student_id}/assignments")
  end

  def create_user(params, sub_account_id = nil)
    api_post_request("accounts/#{sub_account_id || account_id}/users", params)
  end

  def update_user(user_id, params)
    # The canvas-api gem refuses to work with the parameters needed to update a user.
    # Use Httparty instead. Eventually transition all the code back to using Httparty instead of the canvas gem
    HTTParty.put(full_url_with_domain("users/#{user_id}"), :headers => headers, :body => params)
    #api_put_request("users/#{user_id}", params)
  end

  def get_profile(user_id)
    api_get_request("users/self/profile?as_user_id=#{user_id}")
  end

  def get_profile_by_sis_id(sis_id)
    api_get_request("users/sis_user_id:#{sis_id}/profile")
  rescue Canvas::ApiError => ex
    if CanvasWrapper.no_exist_fail?(ex)
      nil
    else
      raise ex
    end
  end

  def user_activity(user_id)
    api_get_request("users/activity_stream?as_user_id=#{user_id}")
  end
    
  def create_conversation(recipients, subject, body)
    api_post_request("conversations", {
      recipients: recipients,
      subject: subject,
      body: body,
      scope: 'unread'
    })
  end

  def get_conversation(conversation_id)
    api_get_request("conversations/#{conversation_id}")
  end

  def add_message(conversation_id, recipients, body)
    api_post_request("conversations/#{conversation_id}/add_message", {
      recipients: recipients,
      body: body,
      scope: 'unread'
    })
  end

  def create_discussion(user_id, course_id, title, message)
    api_post_request("courses/#{course_id}/discussion_topics?as_user_id=#{user_id}", {
      title: title,
      message: message,
      published: true
    })
  end

  def create_discussion_entry(user_id, course_id, topic_id, message)
    api_post_request("courses/#{course_id}/discussion_topics/#{topic_id}/entries?as_user_id=#{user_id}", {
      message: message,
      published: true
    })
  end

  def get_discussion_entries(course_id, topic_id)
    api_get_request("courses/#{course_id}/discussion_topics/#{topic_id}/entries")
  end

  def create_discussion_reply(user_id, course_id, topic_id, entry_id, message)
    api_post_request("courses/#{course_id}/discussion_topics/#{topic_id}/entries/#{entry_id}/replies?as_user_id=#{user_id}", {
      message: message,
      published: true
    })
  end

  def get_assignments(course_id)
    api_get_request("courses/#{course_id}/assignments")
  end

  def create_assignment_submission(course_id, assignment_id, comment, submission_type, body = nil, url = nil)
    request = {
      comment: comment,
      assignment: {
        submission_type: submission_type
      }
    }
    request[:assignment][:body] = body if body.present?
    request[:assignment][:url] = url if url.present?
    
    api_post_request("courses/#{course_id}/assignments/#{assignment_id}", request)
  end

  def create_quiz(user_id, course_id, title, quiz_type)
    api_post_request("courses/#{course_id}/quizzes", {
      title: title,
      quiz_type: quiz_type,
      published: true,
    })
  end

  def create_conversation(user_id, course_id, subject, body)
    api_post_request("courses/#{course_id}/quizzes", {
      subject: subject,
      body: body
    })
  end

  def get_account_lti_tools(sub_account_id = nil)
    api_get_request("accounts/#{sub_account_id || account_id}/external_tools")
  end

  def get_course_lti_tools(course_id)
    api_get_request("courses/#{course_id}/external_tools")
  end

  def create_account_lti_tool(params, sub_account_id = nil)
    api_post_request("accounts/#{sub_account_id || account_id}/external_tools", params)
  end

  def create_course_lti_tool(params, course_id)
    api_post_request("courses/#{course_id}/external_tools", params)
  end

  def self.authorized_fail?(ex)
    ex.message == "[{\"message\"=>\"user not authorized to perform that action\"}]"
  end

  def self.no_exist_fail?(ex)
    ex.message == "[{\"message\"=>\"The specified resource does not exist.\"}]"
  end

  def self.server_error?(ex)
    ex.message == "[{\"message\"=>\"An error occurred.\", \"error_code\"=>\"internal_server_error\"}]"
  end

  def self.sis_taken_error?(ex)
    ex.message.include?("sis_source_id") && ex.message.include?("is already in use")
  end

end
