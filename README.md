# Leap PhoneNumber Assignment Client

A ruby based command line utility that connects to uc.leap.tel v1 API and assigns a DID(s) using a file to the customer's chosen instance.

## Requirements:
- Ruby 3.2.2 or higher

## Installation:
  `./bin/setup`

## Run
  `./bin/runner`

## Usage:
Once you run the application, the application will get some information from you for 1. Leap account email. 2. Leap account password 3. The file location which is a CSV where the TN is the first element. 4. Assign or Delete numbers
Once the information is entered.
1. The system authenticates against the Leap API.
2. On successful authentication the system fetches the instances and prompt the user to choose from.
3. Once the instance is selected successfully
4. The user fetches the existing phone numbers iterates through the CSV with the phone numbers that need to be assigned and calls the API endpoints to assign or delete one phone number at a time.
5. Finally the system writes the stats on the terminal and writes a file with the associated phone numbers.

