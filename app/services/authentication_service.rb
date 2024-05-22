class AuthenticationService
  include HTTParty

  attr_accessor :email, :password

  def initialize(username, password)
    @email = username
    @password = password
  end

  def fetch_token
    begin
      response = self.class.post("#{Input::HOST}/users/sign_in",
        body: {
          username: email,
          password: password,
          grant_type: 'password'
        }.to_json,
        headers: {'Content-Type' => 'application/json', 'Accept' => 'application/json'}
      )
      code = response.code

      if 200 == code
        puts("Successfully fetched authentication token from Leap")
        LeapAuth.new(response['access_token'], response['refresh_token'], response['expires_in'])
      elsif 400 == code
        raise Quickbooks::OAuthRegtrationFailed.new("Registration with QBOAuth services failed!!")
      end
    rescue => e
      puts("Could not fetch the authentication token from Leap")
      puts(e)
    end
  end
end
