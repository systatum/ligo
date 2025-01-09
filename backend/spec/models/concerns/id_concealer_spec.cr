require "../../spec_helper"

describe IdConcealer do
  describe ".encode" do
    it "obfuscates an integral ID" do
      # notice that the ID are so different from one another
      IdConcealer.encode(0).should eq "JKQ98NP8E7BL"
      IdConcealer.encode(1).should eq "KVXAYRE84P7M"
      IdConcealer.encode(2).should eq "E5D4YQ7YQBKX"
      IdConcealer.encode(3).should eq "LBWR85JYMJN9"
      IdConcealer.encode(4).should eq "RQ4LYWAYJPKD"
      IdConcealer.encode(10).should eq "5XPQ8VJ8BEVL"
      IdConcealer.encode(11).should eq "6EVD896YXAKP"
      IdConcealer.encode(12).should eq "KNAJYK7YWLB9"
      IdConcealer.encode(13).should eq "MV5AYDLY4N6P"
      IdConcealer.encode(14).should eq "9X54YAJ8JAQR"
    end
  end

  describe ".decode" do
    it "reveals an integer ID from the hash form" do
      IdConcealer.decode("JKQ98NP8E7BL").should eq 0
      IdConcealer.decode("KVXAYRE84P7M").should eq 1
      IdConcealer.decode("E5D4YQ7YQBKX").should eq 2
      IdConcealer.decode("LBWR85JYMJN9").should eq 3
      IdConcealer.decode("RQ4LYWAYJPKD").should eq 4
      IdConcealer.decode("5XPQ8VJ8BEVL").should eq 10
      IdConcealer.decode("6EVD896YXAKP").should eq 11
      IdConcealer.decode("KNAJYK7YWLB9").should eq 12
      IdConcealer.decode("MV5AYDLY4N6P").should eq 13
      IdConcealer.decode("9X54YAJ8JAQR").should eq 14
    end
  end
end
