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

    it "accepts injectable IO output" do
      output = TestIO.new
      spinner = Term::Spinner.new(output: output)

      spinner.spin

      output.output.empty?.should be_false
    end

    it "normalizes integer intervals as frames per second" do
      Term::Spinner.new(interval: 20, output: TestIO.new).interval.should eq 50.milliseconds
      Term::Spinner.new(interval: 10, output: TestIO.new).interval.should eq 100.milliseconds
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
    end

    it "replaces tokens in rendered output" do
      output = TestIO.new
      spinner = Term::Spinner.new(":spinner Loading :title", output: output)

      spinner.update(title: "file.txt")
      spinner.spin

      output.output.includes?("Loading file.txt").should be_true
    end
  end

  describe "#spin" do
    it "renders a frame into injectable IO" do
      output = TestIO.new
      spinner = Term::Spinner.new(output: output)

      spinner.spin

      output.output.empty?.should be_false
    end

    it "renders different frames as it progresses" do
      output = TestIO.new
      spinner = Term::Spinner.new(output: output)
      renders = [] of String

      3.times do
        output.clear
        spinner.spin
        renders << output.output
      end

      renders.uniq.size.should eq(3)
      renders[0].includes?("|").should be_true
      renders[1].includes?("/").should be_true
      renders[2].includes?("-").should be_true
    end

    it "allows callbacks to re-enter spinner methods" do
      output = TestIO.new
      spinner = Term::Spinner.new(":spinner :title", output: output)
      updated = false
      completed = Channel(Bool).new

      spinner.on(:spin) do |sp|
        sp.update(title: "x")
        updated = true
      end

      spawn do
        spinner.spin
        completed.send(true)
      end

      select
      when completed.receive
        updated.should be_true
      when timeout(100.milliseconds)
        raise "spin callback deadlocked"
      end
    end
  end

  describe "#auto_spin" do
    it "stops without waiting on an unreceived channel" do
      spinner = Term::Spinner.new(output: TestIO.new, interval: 1.millisecond)

      spinner.auto_spin
      spinner.stop
      sleep(spinner.interval + spinner.interval)
      Fiber.yield

      spinner.done?.should be_true
    end
  end

  describe "#stop" do
    it "emits done once when stopped repeatedly" do
      spinner = Term::Spinner.new(output: TestIO.new)
      done_count = 0

      spinner.on(:done) { done_count += 1 }
      spinner.stop
      spinner.stop

      done_count.should eq(1)
    end
  end

  describe "#success" do
    it "renders the success mark" do
      output = TestIO.new
      spinner = Term::Spinner.new(output: output)

      spinner.success

      output.output.includes?("✔").should be_true
    end
  end

  describe "#error" do
    it "renders the error mark" do
      output = TestIO.new
      spinner = Term::Spinner.new(output: output)

      spinner.error

      output.output.includes?("✖").should be_true
    end
  end

  describe "#pause and #resume" do
    it "transitions between paused and spinning states" do
      spinner = Term::Spinner.new(output: TestIO.new)

      spinner.spin
      spinner.pause
      spinner.state.should eq Term::Spinner::State::Paused
      spinner.resume
      spinner.state.should eq Term::Spinner::State::Spinning
    end
  end
end
