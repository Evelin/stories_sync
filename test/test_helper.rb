require "rubygems"
require "contest"
require "fileutils"

ROOT = File.expand_path(File.join(File.dirname(__FILE__), "..", "templates"))

$:.unshift ROOT

class Test::Unit::TestCase
  def root(*args)
    File.join(ROOT, *args)
  end

  def execute_at_root(args = nil)
    Dir.chdir root do
      `ruby -rubygems ../bin/stories #{args}` # 2>&1`
    end
  end

  def delete_all_stories
    Story.find(:all).each do |story|
      story.destroy
    end
  end

  def spawn_story(name, label)
    story = Story.create(:name => name, :labels => label)
    story.current_state = "unstarted"
    story.save
  end

  def create_test_file(label)
    File.open("#{STORIES_ROOT}/#{label}_test.rb", "w+") do |f|
      f.puts template(label)
    end
  end

  def template(label)
    File.read("#{STORIES_ROOT}/#{label}_test_template.rb")
  end
end
