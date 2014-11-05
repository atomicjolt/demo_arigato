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
    @canvas_load = CanvasLoad.new(cartridge_courses: common_cartridge_courses)
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
    response.headers['Content-Type'] = 'text/event-stream'
    begin
      5.times do
        response.stream.write "done\n\n".html_safe
        sleep 1.second
      end
    rescue IOError # Raised when browser interrupts the connection
    ensure
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
      params.require(:canvas_load).permit(:lti_attendance, :lti_chat, :user_id, :suffix, :course_welcome, cartridge_courses_attributes: [:is_selected, :content])
    end

    def common_cartridge_courses
      drive = GoogleDrive.new(current_user.google_refresh_token || User.admin_user.google_refresh_token)
      courses = drive.load_spreadsheet(Rails.application.secrets.common_cartridge_courses_google_id)
      courses.map{|c| CartridgeCourse.new(content: c) }.find_all{|c| c.is_enabled}
    end

end
