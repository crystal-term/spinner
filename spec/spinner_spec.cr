require "./spec_helper"

describe Term::Spinner do
  describe "#new" do
    it "creates a spinner with default message" do
      spinner = Term::Spinner.new
      spinner.message.should eq ":spinner"
    end

    it "creates a spinner with custom message" do
      spinner = Term::Spinner.new("Loading...")
      spinner.message.should eq "Loading..."
    end

    it "initializes with stopped state" do
      spinner = Term::Spinner.new
      spinner.state.should eq Term::Spinner::State::Stopped
    end
  end

  describe "#spinning?" do
    it "returns false when stopped" do
      spinner = Term::Spinner.new
      spinner.spinning?.should be_false
    end
  end

  describe "#paused?" do
    it "returns false when not paused" do
      spinner = Term::Spinner.new
      spinner.paused?.should be_false
    end
  end

  describe "#stopped?" do
    it "returns true when stopped" do
      spinner = Term::Spinner.new
      spinner.stopped?.should be_true
    end
  end

  describe "#success?" do
    it "returns false when not successful" do
      spinner = Term::Spinner.new
      spinner.success?.should be_false
    end
  end

  describe "#error?" do
    it "returns false when not in error state" do
      spinner = Term::Spinner.new
      spinner.error?.should be_false
    end
  end

  describe "#update" do
    it "updates tokens" do
      spinner = Term::Spinner.new(":spinner Loading :title")
      spinner.update(title: "file.txt")
      # We can't easily test the output without mocking IO
      # but at least ensure it doesn't crash
    end
  end
end