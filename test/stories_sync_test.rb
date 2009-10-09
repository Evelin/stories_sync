require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'stories_sync.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper.rb'))

require "contest"

STORIES_ROOT = File.join("#{Dir.pwd}", "templates", "test", "stories")

class StorySyncTest < Test::Unit::TestCase
   context "Synchronization" do
    setup do
      create_test_file("label_1")
      create_test_file("label_2")
      delete_all_stories
      spawn_story("a", "label_1")
      spawn_story("c", "label_1")
      spawn_story("1", "label_2")
      spawn_story("3", "label_2")
    end

    should "Synchronize multi-files with Pivotal" do
      execute_at_root("sync")

      stories = Story.find(:all).inject({}) do |result, story|
        result[story.labels] ||= []
        result[story.labels] << story.name
        result
      end

      stories.each_pair do |key, value|
        file = File.read("#{STORIES_ROOT}/#{key}_test.rb")
        local_stories = file.scan(/\n\s*story[\s\n]*(?:"([^"]*)"|'([^']*)')/m).map(&:compact).flatten
        assert_equal(value.sort, local_stories.sort)
      end
    end
  end

  context "Updating local stories" do
    setup do
      create_test_file("label_1")
      create_test_file("label_2")
      delete_all_stories
      spawn_story("a", "label_1")
      spawn_story("c", "label_1")
      spawn_story("1", "label_2")
      spawn_story("3", "label_2")
    end

    should "Add pending stories" do
      execute_at_root("add_pending_stories")

      f = File.read("#{STORIES_ROOT}/label_1_test.rb")
      assert_match(/Pending stories/, f)
      assert_match(/a/, f)
      assert_match(/b/, f)
      assert_match(/c/, f)

      f = File.read("#{STORIES_ROOT}/label_2_test.rb")
      assert_match(/Pending stories/, f)
      assert_match(/1/, f)
      assert_match(/2/, f)
      assert_match(/3/, f)
    end
  end

  context "Uploading new stories" do
    setup do
      create_test_file("label_1")
      create_test_file("label_2")
      delete_all_stories
      spawn_story("a", "label_1")
      spawn_story("1", "label_2")
    end

    should "Upload any new story to pivotal, without repeating it" do
      execute_at_root("upload_new_stories")

      stories = Story.find(:all).inject({}) do |result, story|
        result[story.labels] ||= []
        result[story.labels] << story.name
        result
      end

      assert_equal(['a', 'b'], stories["label_1"].sort)
      assert_equal(['1', '2'], stories["label_2"].sort)
    end
  end

  context "Warning" do
    setup do
      delete_all_stories
      spawn_story("alpha", "label_3")
    end

    should "Add a pending story that doesn't have any test file" do
      assert_match(/The file .*label_3_test.rb. doesn't exist/, execute_at_root("add_pending_stories"))
    end
  end

end
