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

  describe "#recommended_for" do
    describe "User 1" do
      before(:all) do
        @recommended_for_user_1 = Similus.recommended_for(["User", 1])
      end

      it "should recommend SW5 and then Blade Runner" do
        @recommended_for_user_1[0][:id].should == "Star Wars 5"
        @recommended_for_user_1[0][:score].should == 4.0
        @recommended_for_user_1[1][:id].should == "Blade Runner"
        @recommended_for_user_1[1][:score].should == 3.0
      end

      it "should not recommend Casablanca" do
        @recommended_for_user_1.detect { |x| x[:id] == "Casablanca" }.should be_nil
      end
    end

    describe "other users" do
      before(:all) do
        @recommended_for_user_2 = Similus.recommended_for(["User", 2])
        @recommended_for_user_3 = Similus.recommended_for(["User", 3])
        @recommended_for_user_4 = Similus.recommended_for(["User", 4])
        @recommended_for_user_5 = Similus.recommended_for(["User", 5])
        @recommended_for_user_6 = Similus.recommended_for(["User", 6])
        @recommended_for_user_7 = Similus.recommended_for(["User", 7])
      end

      it "should recommend only SW1 and then SW2 to user2 but not blade runner" do
        @recommended_for_user_2[0][:id].should == "Star Wars 1"
        @recommended_for_user_2[0][:score].should == 4.0
        @recommended_for_user_2[1][:id].should == "Star Wars 2"
        @recommended_for_user_2[1][:score].should == 2.0
        @recommended_for_user_2.detect { |x| x[:id] == "Blade Runner" }.should be_nil
      end

      it "should recommend only BR and SW4 and SW2 to user3" do
        @recommended_for_user_3.detect { |x| x[:id] == "Blade Runner" }.should_not be_nil
        @recommended_for_user_3.detect { |x| x[:id] == "Star Wars 4" }.should_not be_nil
        @recommended_for_user_3.detect { |x| x[:id] == "Star Wars 2" }.should_not be_nil
      end

      it "should recommend first SW1 and then SW4 and BR to user4" do
        @recommended_for_user_4.first[:id].should == "Star Wars 1"
        @recommended_for_user_4.detect { |x| x[:id] == "Blade Runner" }.should_not be_nil
        @recommended_for_user_4.detect { |x| x[:id] == "Star Wars 4" }.should_not be_nil
      end

      it "should recommend first SW5 and then SW4 to user5" do
        @recommended_for_user_5[0][:id].should == "Star Wars 5"
        @recommended_for_user_5[0][:score].should == 4.0
        @recommended_for_user_5[1][:id].should == "Star Wars 4"
        @recommended_for_user_5[1][:score].should == 3.0
      end

      it "should recommend first SW3 and then SW2 to user6" do
        @recommended_for_user_6[0][:id].should == "Star Wars 3"
        @recommended_for_user_6[0][:score].should == 4.0
        @recommended_for_user_6[1][:id].should == "Star Wars 2"
        @recommended_for_user_6[1][:score].should == 2.0
      end

      it "should recommend nothing to user7" do
        @recommended_for_user_7.should be_empty
      end
    end
  end
end