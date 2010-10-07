$: << File.join(File.dirname(__FILE__), "/../lib")
require 'similus'

describe "Similus" do
  before(:all) do
    # Clear redis
    Similus.clear_database!

    Similus.add_activity(["User", 1], :view, ["Movie", "Star Wars 1"])
    Similus.add_activity(["User", 1], :view, ["Movie", "Star Wars 2"])
    Similus.add_activity(["User", 1], :view, ["Movie", "Star Wars 3"])
    Similus.add_activity(["User", 1], :view, ["Movie", "Star Wars 4"])

    Similus.add_activity(["User", 2], :view, ["Movie", "Star Wars 3"])
    Similus.add_activity(["User", 2], :view, ["Movie", "Star Wars 4"])
    Similus.add_activity(["User", 2], :view, ["Movie", "Star Wars 5"])

    Similus.add_activity(["User", 3], :view, ["Movie", "Star Wars 1"])
    Similus.add_activity(["User", 3], :view, ["Movie", "Star Wars 3"])
    Similus.add_activity(["User", 3], :view, ["Movie", "Star Wars 5"])

    Similus.add_activity(["User", 4], :view, ["Movie", "Star Wars 2"])
    Similus.add_activity(["User", 4], :view, ["Movie", "Star Wars 3"])

    Similus.add_activity(["User", 5], :view, ["Movie", "Star Wars 1"])
    Similus.add_activity(["User", 5], :view, ["Movie", "Star Wars 2"])
    Similus.add_activity(["User", 5], :view, ["Movie", "Star Wars 3"])
    Similus.add_activity(["User", 5], :view, ["Movie", "Blade Runner"])

    Similus.add_activity(["User", 6], :view, ["Movie", "Star Wars 1"])
    Similus.add_activity(["User", 6], :view, ["Movie", "Star Wars 5"])
    Similus.add_activity(["User", 6], :view, ["Movie", "Blade Runner"])

    Similus.add_activity(["User", 7], :view, ["Movie", "Casablanca"])
  end

  describe "#similar_to" do
    describe "User 1" do
      before(:all) do
        @similar_to_user_1 = Similus.similar_to(["User", 1])
      end

      it "should be most similar to user 5 with score of 3.0" do
        @similar_to_user_1.first[:id].should == "5"
        @similar_to_user_1.first[:score].should == 3.0
      end

      it "should not include itself" do
        @similar_to_user_1.detect { |x| x[:id] == "1" }.should be_nil
      end

      it "should not be similar to users with just 1 similarity" do
        @similar_to_user_1.detect { |x| x[:id] == "6" }.should be_nil
      end

      it "should be similar to users even if they will not have new recommendations" do
        @similar_to_user_1.detect { |x| x[:id] == "4" }.should_not be_nil
      end

      it "should be similar to users 2, 3 and 4 with 2 similarities " do
        @similar_to_user_1.select { |x| x[:score] == 2.0 }.size.should == 3
      end
    end

    describe "the other users" do
      before(:all) do
        @similar_to_user_2 = Similus.similar_to(["User", 2])
        @similar_to_user_3 = Similus.similar_to(["User", 3])
        @similar_to_user_4 = Similus.similar_to(["User", 4])
        @similar_to_user_5 = Similus.similar_to(["User", 5])
        @similar_to_user_6 = Similus.similar_to(["User", 6])
        @similar_to_user_7 = Similus.similar_to(["User", 7])
      end

      it "shall have the expected similarities and scores for the rest of users" do
        @similar_to_user_2.size.should == 2
        @similar_to_user_2.select { |x| x[:score] == 2.0 }.size.should == 2
        @similar_to_user_2.select { |x| %w(1 3).include? x[:id]}.size.should == 2

        @similar_to_user_3.size.should == 4
        @similar_to_user_3.select { |x| %w(1 2 5 6).include? x[:id]}.size.should == 4
        @similar_to_user_3.select { |x| x[:score] == 2.0}.size.should == 4

        @similar_to_user_4.size.should == 2
        @similar_to_user_4.select { |x| %w(1 5).include? x[:id]}.size.should == 2
        @similar_to_user_4.select { |x| x[:score] == 2.0}.size.should == 2

        @similar_to_user_5.first[:score].should == 3.0
        @similar_to_user_5.size.should == 4
        @similar_to_user_5.select { |x| %w(1 3 4 6).include? x[:id]}.size.should == 4
        @similar_to_user_5.select { |x| x[:score] == 2.0}.size.should == 3

        @similar_to_user_6.size.should == 2
        @similar_to_user_6.select { |x| %w(3 5).include? x[:id]}.size.should == 2
        @similar_to_user_6.select { |x| x[:score] == 2.0}.size.should == 2
      end

      it "shall have no similarities for user 7" do
        @similar_to_user_7.size.should == 0
      end
    end
  end
end