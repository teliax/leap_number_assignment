require 'bundler'
Bundler.require

require 'active_support/all'

# require initialiazers configurations
APP_ROOT = File.expand_path("..", __dir__)
CONFIG = {}

CONFIG['leap_api_base_uri'] = 'https://uc.leap.tel'

Dir.glob(File.join(APP_ROOT, 'app', 'services', '*.rb')).each { |file| require file }

Dir.glob(File.join(APP_ROOT, 'app', 'models', '*.rb')).each { |file| require file }

Dir.glob(File.join(APP_ROOT, 'app', '*.rb')).each { |file| require file }
