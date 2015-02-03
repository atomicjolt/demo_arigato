class SessionsController < Devise::SessionsController
  
  def destroy
    debugger
    current_user.authentications.where(provider: 'canvas').destroy_all

    logger.info "#{ current_user.email } signed out"
    super
  end

end