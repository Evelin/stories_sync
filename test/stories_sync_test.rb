require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'stories_sync.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper.rb'))

require "contest"

STORIES_ROOT = File.join(File.dirname(__FILE__), "stories")

class StorySyncTest < Test::Unit::TestCase
   context "Synchronization" do
    setup do
      create_test_file
      delete_all_stories
      spawn_story("0")
      spawn_story("1")
      spawn_story("2")
    end

    should "Synchronize 2 stories in Pivotal with 2 local stories, with one in common" do
      execute_at_root("sync")

      file = File.read("#{STORIES_ROOT}/stories.rb")
      local_stories = file.scan(/\n\s*story[\s\n]*(?:"([^"]*)"|'([^']*)')/m).map(&:compact).flatten

      stories_names = Story.find(:all).inject([]) do |names, story|
        names << story.name
      end

      assert stories_names.include?("a")
      assert stories_names.include?("b")
      assert_match(/1/, file)
      assert_match(/2/, file)
      assert (local_stories.uniq.size == 5)
      assert (stories_names.uniq.size == 5)
    end
  end

  context "Updating local stories" do
    setup do
      create_test_file
      delete_all_stories
      spawn_story("0")
      spawn_story("1")
      spawn_story("2")
    end

    should "Add pending stories" do
      execute_at_root("add_pending_stories")
      f = File.read("#{STORIES_ROOT}/stories.rb")
      assert_match(/Pending stories/, f)
      assert_match(/0/, f)
      assert_match(/1/, f)
      assert_match(/2/, f)
    end
  end

  context "Uploading new stories" do
    setup do
      create_test_file
      delete_all_stories
    end

    should "Upload any new story to pivotal, without repeating it" do
      execute_at_root("upload_new_stories")
      assert_equal(3, Story.find(:all).size)
    end
  end
end
