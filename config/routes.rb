class CustomDomain
  def matches?(request)
    return false if request.subdomain.length <= 0 || request.subdomain == 'www'
    true
  end
end

Rails.application.routes.draw do

  root :to => "canvas_loads#new"

  devise_for :users, :controllers => {
    :registrations => "registrations",
    :omniauth_callbacks => "omniauth_callbacks"
  }
  
  resources :users
  resources :canvas_authentications
  resources :canvas_loads

  mount MailPreview => 'mail_view' if Rails.env.development?

end
