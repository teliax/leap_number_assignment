class LeapAuth
  attr_accessor :access_token, :refresh_token, :expires_in

  def initialize(access_token, refresh_token, expires_in)
    @access_token = access_token
    @refresh_toekn = refresh_token
    @expires_in = expires_in
  end
end
