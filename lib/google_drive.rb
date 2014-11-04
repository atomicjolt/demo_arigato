require 'google/api_client'

@@discovery_document = nil

class GoogleDrive

  def initialize(refresh_token = nil)
    @refresh_token = refresh_token
  end

  def client
    return @client if @client
    @client = GoogleDrive.google_client(@refresh_token)
    @client.authorization.fetch_access_token!
    @client.retries = 10
    @client.connection.options[:timeout] = 500

    if @@discovery_document
      @client.register_discovery_document('drive', 'v2', discovery_document.value)
    else
      @drive = client.discovered_api('drive', 'v2')
      @@discovery_document = @client.discovery_document('drive', 'v2')
    end

    @client
  end

  def drive
    @drive ||= client.discovered_api('drive', 'v2')
  end

  def self.google_client(refresh_token)
    client = Google::APIClient.new(
        :application_name => Rails.application.secrets.application_name,
        :application_version => '1.0')
    client.authorization.client_id = Rails.application.secrets.google_id
    client.authorization.client_secret = Rails.application.secrets.google_secret
    client.authorization.scope = Rails.application.secrets.google_scope
    client.authorization.refresh_token = refresh_token
    client
  end

  def load_spreadsheet(google_id)
    # Can use this to get the url where the document can be downloaded
    # result = client.execute(
    #   :api_method => drive.files.get,
    #   :parameters => { 'fileId' => google_id })
    result = HTTParty.get("https://docs.google.com/spreadsheets/export?id=#{google_id}&exportFormat=csv")
    raise "Error loading Spreadsheet from Google: #{result.body}" unless result.code == 200
    CSV.parse(result.body)
  end

end
