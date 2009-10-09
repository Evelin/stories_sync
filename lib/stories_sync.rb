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
    say_status(:fetch, "Fetching stories from Pivotal.")
    new_external_stories = difference(fetch_stories, local_stories)

    if new_external_stories.empty?
      say_status(:complete, "Pivotal stories up to date.")
    else
      new_external_stories.each_pair do |label, stories|
        say_status(:compare, "There are #{stories.size} new stories in Pivotal with the label '#{label}'.")
      end
      add_new_stories(new_external_stories)
    end
  end

  desc "upload_new_stories", "Upload new stories to pivotal"
  def upload_new_stories
    new_local_stories = difference(local_stories, fetch_stories)

    new_local_stories.each_pair do |label, stories|
      say_status(:compare, "You have #{stories.size} new local stories in #{label}_test.rb.")
    end

    if new_local_stories.empty?
      say_status(:completed, "Your stories up to date.")
    else
      new_local_stories.each_pair do |label, stories|
        stories.each do |story|
          upload_new_story(story, label)
          say_status(:append, "Added story: '#{story}'")
        end
      end
      say_status(:completed, "Stories added to Pivotal successfully.")
    end
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
  def difference(hash_a ,hash_b)
    new_stories = {}
    hash_a.each_pair do |label, stories|
      new_stories[label] = stories - hash_b[label].to_a
    end
    new_stories
  end

  # Returns {"label_1" => [story_1, story_2, ..], "label_2" => [story_1, story_2, ..]}
  def fetch_stories
    Iteration.find(:last).stories.inject({}) do |result, story|
      result[story.labels] ||= []
      result[story.labels] << story.name
      result
    end
    rescue NoMethodError; []
  end

  def fetch_token(user = PIVOTAL_CONFIG[:user][:name], pass = PIVOTAL_CONFIG[:user][:pass])
    token = RestClient::Resource.new("https://www.pivotaltracker.com/services/tokens/active/guid",
                                     :user => user,
                                     :password => pass).get
    token.match(/<guid>(.*)<.guid>/)[1]
  rescue RestClient::Unauthorized
    say_status :unauthorized, "Your credentials are invalid, You'll have to try again", :red
  end

  def create_config_file
    say_status :setup, "Gathering your Pivotal information"
    user = ask "What is your user name?"
    pass = ask "What is your password?"
    say_status :fetch, "Fetching your Pivotal token"
    token = fetch_token(user, pass)
    return if token.nil?
    project_id = ask "What is your pivotal project id?"
    create_yaml(user, pass, token, project_id)
    say_status :create, "./config/pivotal.yml"
  end

  def user_config
    File.read(CONFIG_FILE) if File.exists?(CONFIG_FILE)
  end

  # TODO we should consider making this a public method
  # and merging the extra options if given.
  def upload_new_story(name, key)
    # Other options are: requested_by, description, owned_by, labels
    story = Story.create(:name => name, :estimate => 1, :labels => key)
    story.current_state = "unstarted"
    story.save
  end

  def story_file(label)
    File.join("#{Dir.pwd}", "test", "stories", "#{label}_test.rb")
  end

  def files
    Dir.entries(File.join("#{Dir.pwd}", "test", "stories")).delete_if do |name|
      name.match(/_test.rb/).nil?
    end
  end

  def labels
    files.inject([]) do |labels, name|
      labels << name.scan(/(.*)_test.rb/).to_s
      labels
    end
  end

  def local_stories
    labels.inject({}) do |result, label|
      result[label] ||= []
      result[label] = File.read(story_file(label)).scan(/\n\s*story[\s\n]*(?:"([^"]*)"|'([^']*)')/m).map(&:compact).flatten
      result
    end
  end

  def add_new_stories(new_stories)
    new_stories.each_pair do |label, stories|
      file = story_file(label)
      if File.exists?(file)
        original_file = File.read(file).scan(/(.*)end/m)
        original_file << "\n  # Pending stories\n"

        File.open(story_file(label), "w") do |f|
          f.puts original_file
          f.puts stories.map {|story| "  story \"#{story}\""}.join("\n")
          f.puts "end"
        end
      else
        say_status(:warning, "The file '#{file}' doesn't exist", :yellow)
      end
    end
    say_status(:append, "Pending stories added successfully.")
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
