class CanvasLoadsController < ApplicationController

  before_action :authenticate_user!
  before_action :set_canvas_load, only: [:show, :edit, :update, :destroy]

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
    byebug
    @canvas_load.canvas_domain = current_user.authentications.find_by_provider('canvas').provider_url
    if @canvas_load.save

      redirect_to @canvas_load, notice: 'Canvas load was successfully created.'
    else
      render :new
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
