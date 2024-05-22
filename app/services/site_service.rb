class SiteService
  include HTTParty

  attr_accessor :access_token, :sites

  def initialize(bearer_token)
    @access_token = bearer_token
    @sites = []
  end

  def fetch
    sites = []
    begin
      response = self.class.get("#{Input::HOST}/customer/sites",
        headers: {'Authorization' => "Bearer #{self.access_token}", 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
      )

      code  = response.code

      if 200 == code
        response['data'].each do |site|
          id  = site['id']
          dns_name = site['attributes']['name']
          sites << Site.new(id, dns_name)
        end

        sites
      end
    rescue => e
      puts(e)
    end
  end
end
