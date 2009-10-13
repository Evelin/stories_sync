CONFIG_FILE = File.join("#{Dir.pwd}", "config", "pivotal.yml")

PIVOTAL_CONFIG = File.exists?(CONFIG_FILE) ? YAML.load_file(CONFIG_FILE) : {:user => {:token => ""}, :project => {:id => 1}}

# Interaction with Pivotal
class Iteration < ActiveResource::Base
  self.site = "http://www.pivotaltracker.com/services/v2/projects/#{PIVOTAL_CONFIG[:project][:id]}"
  headers['X-TrackerToken'] = PIVOTAL_CONFIG[:user][:token]
end

class Story < ActiveResource::Base
  self.site = "http://www.pivotaltracker.com/services/v2/projects/#{PIVOTAL_CONFIG[:project][:id]}"
  headers['X-TrackerToken'] = PIVOTAL_CONFIG[:user][:token]

  def label
    labels
    rescue; "unlabeled"
  end
end
