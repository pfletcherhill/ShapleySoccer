require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Soccer
  class Application < Rails::Application
    
    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += Dir[Rails.root.join('app', 'models', '{**}')]
    
    # Set local ENV variables
    config.before_configuration do
      env_file = File.join(Rails.root, 'config', 'credentials.yml')
      YAML.load(File.open(env_file)).each do |key, value|
        ENV[key.to_s] = value
      end if File.exists?(env_file)
    end
  end
end
