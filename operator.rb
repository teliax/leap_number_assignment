require_relative './config/environment.rb'

input = Input.build()

auth_service = AuthenticationService.new(input.email, input.password)
leap_auth = auth_service.fetch_token()

site_service = SiteService.new(leap_auth.access_token)
sites = site_service.fetch

Input.populate_site_choice(sites, input)

phone_number_service = PhoneNumberService.new(leap_auth.access_token, input.site_choice.id, input)
phone_number_service.perform
