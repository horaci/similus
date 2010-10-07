$: << File.join(File.dirname(__FILE__), "/../lib")

require 'similus'

describe "Similus" do
  describe "Add activity" do
    before(:all) do
      # Clear redis
      Similus.clear_database!

      # Activity
      Similus.add_activity(["User", 1], :view, ["Movie", "Star Wars 1"])
    end

    def redis_object(type,object)
      object_hash = Digest::SHA1.hexdigest(object)
      Similus.redis.get("#{type}:#{object_hash}:id")
    end

    it "should create classes in redis" do
      redis_object("class", "User").should_not be_nil
      redis_object("class", "Movie").should_not be_nil
      redis_object("class", "Other").should be_nil
    end

    it "should create objects in redis" do
      redis_object("object", "User:1").should_not be_nil
      redis_object("object", "Movie:Star Wars 1").should_not be_nil
      redis_object("object", "User:2").should be_nil
    end

    it "should create actions in redis" do
      redis_object("action", "view").should_not be_nil
      redis_object("action", "like").should be_nil
    end
  end
end