class CustomDomain
  def matches?(request)
    return false if request.subdomain.length <= 0 || request.subdomain == 'www'
    true
  end
end

Rails.application.routes.draw do

  devise_for :users, :controllers => {
    :registrations => "registrations",
    :omniauth_callbacks => "omniauth_callbacks"
  }
  
  authenticate :user do
    resources :canvas_loads do
      member do
        get :setup_course
      end
    end
    root :to => "canvas_loads#new", as: "root"
  end

  resources :users
  resources :canvas_authentications
  
  mount MailPreview => 'mail_view' if Rails.env.development?

end
