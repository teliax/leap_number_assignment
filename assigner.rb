require_relative './config/environment.rb'

input = Input.build()

auth_service = AuthenticationService.new(input.email, input.password)
leap_auth = auth_service.fetch_token()

site_service = SiteService.new(leap_auth.access_token)
sites = site_service.fetch

Input.populate_site_choice(sites, input)

phone_number_service = PhoneNumberService.new(leap_auth.access_token, input.site_choice.id, input)
stats = phone_number_service.assign_phone_numbers
phone_number_service.write_all_phone_numbers

puts "-" * 100
puts "Stats => Existing: #{stats[:existing_numbers].length} | New: #{stats[:new_numbers].length} | Errored: #{stats[:errored_numbers].length}"
puts "-" * 100

stats[:errored_numbers].each do |did|
  puts "Errored: #{did}"
end
