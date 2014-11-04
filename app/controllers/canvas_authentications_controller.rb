class CanvasAuthenticationsController < ApplicationController
  respond_to :html
  
  def new
  end

  def create
    if params[:canvas_url].blank?
      flash[:error] = "Please provide the url for your Canvas installation"
      render :new
      return
    end
    
    session[:canvas_url] = params[:canvas_url]

    begin
      canvas_url = URI.parse(params[:canvas_url])
      canvas_url.path  = ''
      canvas_url.query = nil
      redirect_to user_omniauth_authorize_path(:canvas, :canvas_url => canvas_url.to_s)
    rescue => ex
      flash[:error] = "We couldn't use the url you provided. Please check the url and try again."
      render :new
    end

  end

end
