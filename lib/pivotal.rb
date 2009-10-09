CONFIG_FILE = File.join("#{Dir.pwd}", "config", "pivotal.yml")

# Failsafe in case there's no config file
raise "You don't have a configuration file yet, try running 'stories setup'" unless File.exists?(CONFIG_FILE)

PIVOTAL_CONFIG = YAML.load_file(CONFIG_FILE)

# Interaction with Pivotal
class Iteration < ActiveResource::Base
  self.site = "http://www.pivotaltracker.com/services/v2/projects/#{PIVOTAL_CONFIG[:project][:id]}"
  headers['X-TrackerToken'] = PIVOTAL_CONFIG[:user][:token]
end

class Story < ActiveResource::Base
  self.site = "http://www.pivotaltracker.com/services/v2/projects/#{PIVOTAL_CONFIG[:project][:id]}"
  headers['X-TrackerToken'] = PIVOTAL_CONFIG[:user][:token]
end
