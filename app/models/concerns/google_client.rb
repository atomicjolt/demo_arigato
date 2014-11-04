module GoogleClient
  extend ActiveSupport::Concern

  def google_refresh_token
    if auth = self.authentications.find_by_provider('google_oauth2')
      auth.refresh_token
    else
      nil
    end
  end

end
