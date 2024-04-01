class Input
  attr_accessor :email, :password, :tn_file_location, :site_choice

  def initialize(username, passwd, file_location)
    @email = username
    @password = passwd
    @tn_file_location = file_location
    @site_choice = nil
  end

  class << self
    def build
      # puts "Checking environment for Leap Account Email"
      username  = ENV['LEAP_ACCOUNT_EMAIL'].to_s.blank? ? prompt_email() : (puts("Using the email from environment!"); ENV['LEAP_ACCOUNT_EMAIL'])

      # puts "Checking environment for Leap Account Password"
      passwd  = ENV['LEAP_ACCOUNT_PASSWORD'].to_s.blank? ? prompt_password() : (puts("Using the password from environment!"); ENV['LEAP_ACCOUNT_PASSWORD'])

      # puts "Please provide DID file location CSV"
      file_location  = ENV['DID_FILE_LOCATION'].to_s.blank? ? prompt_file_location() : (puts("Using the DID file location from environment!"); ENV['DID_FILE_LOCATION'])

      Input.new(username.strip, passwd.strip, file_location.strip)
    end

    def populate_site_choice(sites, input)
      site_choice = prompt_site_selection(sites)
      input.site_choice = site_choice
    end

    private
      def prompt_email()
        print "Please enter your Leap App email: "
        gets
      end

      def prompt_password()
        print "Please enter your Leap App password: "
        gets
      end

      def prompt_file_location
        print "Please enter the location to the numbers file: "
        gets
      end

      def prompt_site_selection(sites)
        puts "Please choose sites you want to assign the phone numbers to:"
        sites.each_with_index do |site, index|
          puts "#{index + 1} => #{site.dns_name}"
        end
        print "Please enter the serial number for the site: "
        site_selection = gets
        site_selection = site_selection.to_i

        site_choice = nil

        if site_selection > 0 && site_selection <= sites.length
          site_choice = sites[site_selection - 1]
          return site_choice
        else
          prompt_site_selection(sites)
        end
      end
  end # end of self block
end
