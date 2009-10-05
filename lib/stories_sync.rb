#! /usr/bin/env ruby

require "rubygems"
require 'restclient'
require "activeresource"
require "thor"
require "yaml"
require File.join("#{File.dirname(__FILE__)}", "pivotal.rb")

# FIXME We are using both restclient and ARes at the moment.
# We should migrate everything to restclient, since it's way smaller.

class Stories < Thor
  include Thor::Actions

  desc "add_pending_stories", "Fetch stories and add them to the stories file"
  def add_pending_stories
    say_status(:fetch, "Fetching stories from Pivotal")
    new_stories = fetch_stories - local_stories
    say_status(:compare, "There are #{new_stories.size} new stories in Pivotal")

    return if new_stories.empty?
    add_new_stories(new_stories, stories_file)
    say_status(:append, "Pending stories added successfully.")
  end

  desc "upload_new_stories", "Upload new stories to pivotal"
  def upload_new_stories
    new_stories = local_stories - fetch_stories
    say_status(:compare, "You have #{new_stories.size} new local stories")

    return if new_stories.empty?
    new_stories.each do |name|
      upload_new_story(name)
      say_status(:append, "Added story: '#{name}'")
    end
    say_status(:completed, "Stories added to Pivotal successfully.")
  end

  desc "sync", "Synchronize your local stories with your Pivotal stories"
  def sync
    add_pending_stories
    upload_new_stories
  end

  desc "setup", "Fetch your Pivotal token and creates or updates your config file"
  def setup
    unless user_config
      say "You need to create a configuration file"
      create_config_file
    else
      say "This is your pivotal configuration"
      say user_config
      create_config_file if yes? "Do you want to change your configuration? (Y/N)"
    end
  end

private

  def fetch_stories
    Iteration.find(:last).stories.map(&:name)
    rescue NoMethodError; []
  end

  def fetch_token(user = PIVOTAL_CONFIG[:user][:name], pass = PIVOTAL_CONFIG[:user][:pass])
    token = RestClient::Resource.new("https://www.pivotaltracker.com/services/tokens/active/guid",
                                     :user => user,
                                     :password => pass).get
    token.match(/<guid>(.*)<.guid>/)[1]
  rescue RestClient::Unauthorized
    say_status :unauthorized, "Your credentials are invalid, You'll have to try again"
  end

  def create_config_file
    say_status :setup, "Gathering your Pivotal information"
    user = ask "What is your user name?"
    pass = ask "What is your password?"
    say_status :fetch, "Fetching your Pivotal token"
    token = fetch_token(user, pass)

    project_id = ask "What is your pivotal project id?"

    create_yaml(user, pass, token, project_id)
    say_status :create, "./config/pivotal.yaml"
  end

  def user_config
    File.read(CONFIG_FILE) if File.exists?(CONFIG_FILE)
  end

  # TODO we should consider making this a public method
  # and merging the extra options if given.
  def upload_new_story(name)
    # Other options are: requested_by, description, owned_by, labels
    story = Story.create(:name => name, :estimate => 1)
    move_to_backlog(story.id)
  end

  def move_to_backlog(story_id)
    story = Story.find(story_id)
    story.current_state = "unstarted"
    story.save
  end

  # TODO instead of this method we should use stories_root.
  # Then we could have a stories file per label.
  def stories_file
    File.join(File.dirname(__FILE__), "..", "test", "stories", "stories.rb")
  end

  # TODO we should extend this method to support multiple stories files.
  # Each file could be the name of a pivotal label, to make things easier.
  # e.g: local_stories[:admins] #=> [story1, story2, etc...]
  #      local_stories[:users]  #=> [storya, storyb, etc...]
  def local_stories
    File.read(stories_file).scan(/\n\s*story[\s\n]*(?:"([^"]*)"|'([^']*)')/m).map(&:compact).flatten
  end

  def add_new_stories(new_stories, file = stories_file)
    original_file = File.read(file).scan(/(.*)end/m)
    original_file << "\n  # Pending stories\n"

    File.open(stories_file, "w") do |f|
      f.puts original_file
      f.puts new_stories.map {|story| "  story \"#{story}\""}.join("\n")
      f.puts "end"
    end
  end

  def create_yaml(user, pass, token, project_id)
    config = { :user => { :name => user,
                          :pass => pass,
                          :token => token.to_s },
               :project => { :id => project_id } }

    File.open(CONFIG_FILE, "w+") do |f|
      f.puts config.to_yaml
    end
  end
end
