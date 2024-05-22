require 'csv'

class PhoneNumberService
  include HTTParty

  ASSIGN = 1
  DELETE = 2
  ACTION_MAP = {ASSIGN => {label: "Assign Numbers", action: "assign"}, DELETE => {label: "Delete Numbers", action: "delete"}}

  attr_accessor :access_token, :site_id, :input

  def initialize(token, site_identifier, input)
    @access_token = token
    @site_id = site_identifier
    @input = input
  end

  def perform()
    if ASSIGN == input.action
      assign_phone_numbers
    elsif DELETE == input.action
      delete_phone_numbers
    end
  end

  def assign_phone_numbers
    stats = {existing_numbers: [], new_numbers: [], phone_numbers_details: [], errored_numbers: []}
    puts "Fetching the existing phone numbers for Site: #{site_id}"

    dids_map = fetch_site_phone_numbers_map

    puts "Assigning the phone numbers one at a time..."
    CSV.foreach(input.tn_file_location) do |row|
      process_row_for_assignment(dids_map, row, stats)
    end # end of csv loop

    write_all_phone_numbers
    write_phone_number_assignment_stats(stats)
  end # end of assign_phone numbers method

  def delete_phone_numbers
    stats = {success: [], failure: [], errors: []}
    phone_numbers_map = fetch_site_phone_numbers_map

    counter = 0
    CSV.foreach(input.tn_file_location) do |row|
      puts "Processing Row: #{counter += 1}"
      porocess_row_for_deletion(phone_numbers_map, row, stats)
    end

    write_phone_number_deletion_stats(stats)
  end

  private
    def write_phone_number_assignment_stats(stats)
      puts "-" * 100
      puts "Stats => Existing: #{stats[:existing_numbers].length} | New: #{stats[:new_numbers].length} | Errored: #{stats[:errored_numbers].length}"
      puts "-" * 100

      stats[:errored_numbers].each do |did|
        puts "Errored: #{did}"
      end
    end

    def write_all_phone_numbers
      puts "Writing all associated phone-numbers to Site: #{site_id}"
      rows = []
      phone_number_response = fetch_phone_number_list_response
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

    def process_row_for_assignment(dids_map, row, stats)
      raw_did = row[0]
      did = "1#{raw_did}" if raw_did.length == 10
      if dids_map[did]
        puts("The number: #{did} is already created....")
        stats[:existing_numbers] << did
      else
        response = create_phone_number(did)
        if 200 == response.code
          data = response['data']
          id = data['id']
          name = data['attributes']['name']
          number = data['attributes']['number']
          phone_number = PhoneNumber.new(id, name, number)
          stats[:phone_numbers_details] << phone_number
          stats[:new_numbers] << name
        elsif 401 == response.code
          renew_token
          return process_row_for_assignment(dids_map, row, stats)
        else
          stats[:errored_numbers] << "DID: #{raw_did} | Status: #{response.code} | Response: #{response}"
        end
      end # end of condition
    end

    def create_phone_number(did)
      response = self.class.post("#{Input::HOST}/customer/phone-numbers",
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

    def porocess_row_for_deletion(dids_map, row, stats)
      raw_did = row[0]
      did = "1#{raw_did}" if raw_did.length == 10

      did_detail = dids_map[did]
      if did_detail
        number = did_detail['name']
        id = did_detail['id']

        response = delete_phone_number(number, id)

        if 200 == response.code || 204 == response.code
          stats[:success] << "ID: #{id} | DID: #{number} | Reponse code: #{response.code}"
        elsif 401 == response.code
          renew_token
          return porocess_row_for_deletion(dids_map, row, stats)
        else
          stats[:errors] << "ID: #{id} | DID: #{raw_did} | Status: #{response.code} | Response: #{response}"
        end
      end
    end

    def delete_phone_number(did, id)
      response = self.class.delete("#{Input::HOST}/customer/phone-numbers/#{id}",
            headers: {'Authorization' => "Bearer #{self.access_token}", 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
        )

        puts "Deleting phone number entry for ID: #{id} | Number: #{did} | Response code: #{response.code}"

        response
    end

    def renew_token
      puts "-" * 100
      puts "Renewing Auth token..."
      puts "-" * 100
      auth_service = AuthenticationService.new(input.email, input.password)
      leap_auth = auth_service.fetch_token()
      self.access_token = leap_auth.access_token
    end

    def write_phone_number_deletion_stats(stats)
      puts "-" * 100
      puts "Stats => Success: #{stats[:success].length} | Failure: #{stats[:failure].length} | Errored: #{stats[:errors].length}"
      puts "-" * 100

      stats[:errors].each do |error|
        puts "Errored: #{error}"
      end
    end

    def
       fetch_phone_number_list_response
      self.class.get("#{Input::HOST}/customer/phone-numbers",
        query: {site_id: site_id},
        headers: {'Authorization' => "Bearer #{self.access_token}", 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
      )
    end

    def fetch_site_phone_numbers_map
      phone_number_response = fetch_phone_number_list_response

      dids_map = {}
      phone_number_response['data'].each do |phone_number|
        dids_map[phone_number['attributes']['name']] = {'name' => phone_number['attributes']['name'], 'id' => phone_number['id']}
      end

      dids_map
    end
end # end of PhoneNumberService class
