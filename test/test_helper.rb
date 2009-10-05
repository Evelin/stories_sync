require "rubygems"
require "contest"
require "fileutils"

ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))

$:.unshift ROOT

class Test::Unit::TestCase
  def root(*args)
    File.join(ROOT, *args)
  end

  def execute_at_root(args = nil)
    `ruby -rubygems #{root "bin/stories"} #{args} 2>&1`
  end

  def delete_all_stories
    Story.find(:all).each do |story|
      story.destroy
    end
  end

  def spawn_story(name)
    story = Story.create(:name => name)
    story.current_state = "unstarted"
    story.save
  end

  def create_test_file
    File.open("#{STORIES_ROOT}/stories.rb", "w+") do |f|
      f.puts stories_test_template
    end
  end

  def stories_test_template
    File.read File.join(File.dirname(__FILE__), "stories", "stories_test_template.rb")
  end
end
