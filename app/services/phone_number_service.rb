require 'csv'

class PhoneNumberService
  include HTTParty

  attr_accessor :access_token, :site_id, :input

  def initialize(token, site_identifier, input)
    @access_token = token
    @site_id = site_identifier
    @input = input
  end

  def assign_phone_numbers
    stats = {existing_numbers: [], new_numbers: [], phone_numbers_details: [], errored_numbers: []}
    puts "Fetching the existing phone numbers for Site: #{site_id}"
    phone_number_response = fetch_phone_number_response

    dids_map = {}
    phone_number_response['data'].each do |phone_number|
      dids_map[phone_number['attributes']['name']] = phone_number['attributes']['name']
    end

    puts "Assigning the phone numbers one at a time..."
    CSV.foreach(input.tn_file_location) do |row|
      process_row(dids_map, row, stats)
    end # end of csv loop
    stats
  end # end of assign_phone numbers method

  def write_all_phone_numbers
    puts "Writing all associated phone-numbers to Site: #{site_id}"
    rows = []
    phone_number_response = fetch_phone_number_response
    phone_number_response['data'].each do |phone_number_map|
      attrs = phone_number_map['attributes']

      rows << [phone_number_map['id'], attrs['name'], attrs['number'], attrs['destination'], attrs['site-id']].join(",")
    end

    headers = ["id","name","number","destination","site_id"].join(",")
    rows.unshift(headers)
    File.open('assigned_phone_numbers.csv', 'w') do |file|
      file.puts(rows.join("\n"))
    end
  end

  private

    def process_row(dids_map, row, stats)
      raw_did = row[0]
      did = "1#{raw_did}" if raw_did.length == 10
      if dids_map[did]
        puts("The number: #{did} is already created....")
        stats[:existing_numbers] << did
      else
        response = create_phone_number(did)
        if 200 == response.code
          populate_phone_number(response)
        elsif 401 == response.code
          renew_token
          response = create_phone_number(did)
          return process_row(dids_map, row, stats)
        else
          stats[:errored_numbers] << "DID: #{raw_did} | Status: #{response.code} | Response: #{response}"
        end
      end # end of condition
    end

    def create_phone_number(did)
      response = self.class.post("https://uc.leap.tel/customer/phone-numbers",
        body: { data: {
          type: "phone-numbers",
          attributes: {
                            name: did,
                            number: did,
                            :'site-id' => site_id
                          }
                        }
          }.to_json,
          headers: {'Authorization' => "Bearer #{self.access_token}", 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
          )

        puts "Creating a phone number entry for number: #{did} | Response code: #{response.code}"

        response
    end

    def populate_phone_number(response)
      data = response['data']
      id = data['id']
      name = data['attributes']['name']
      number = data['attributes']['number']
      phone_number = PhoneNumber.new(id, name, number)
      stats[:phone_numbers_details] << phone_number
      stats[:new_numbers] << name
    end

    def renew_token
      puts "-" * 100
      puts "Renewing Auth token..."
      puts "-" * 100
      auth_service = AuthenticationService.new(input.email, input.password)
      leap_auth = auth_service.fetch_token()
      self.access_token = leap_auth.access_token
    end

    def fetch_phone_number_response
      self.class.get("https://uc.leap.tel/customer/phone-numbers",
        query: {site_id: site_id},
        headers: {'Authorization' => "Bearer #{self.access_token}", 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
      )
    end
end # end of PhoneNumberService class
