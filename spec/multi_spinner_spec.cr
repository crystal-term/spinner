require "./spec_helper"

describe Term::Spinner::Multi do
  it "creates a multi-spinner without top level spinner" do
    multi = Term::Spinner::Multi.new
    multi.size.should eq(0)
  end

  it "creates a multi-spinner with top level spinner" do
    multi = Term::Spinner::Multi.new("Top level spinner")
    multi.size.should eq(1)
  end

  it "registers a new spinner" do
    multi = Term::Spinner::Multi.new
    spinner = multi.register("Test spinner")
    
    spinner.should be_a(Term::Spinner)
    multi.size.should eq(1)
  end

  it "registers multiple spinners" do
    multi = Term::Spinner::Multi.new
    
    sp1 = multi.register("Spinner 1")
    sp2 = multi.register("Spinner 2")
    sp3 = multi.register("Spinner 3")
    
    multi.size.should eq(3)
  end

  it "runs spinner with block and completes without error" do
    multi = Term::Spinner::Multi.new
    spinner = multi.register("Test spinner")
    
    completed = false
    spinner.run do
      completed = true
    end
    
    completed.should be_true
  end

  it "handles spinner events correctly" do
    multi = Term::Spinner::Multi.new
    spinner = multi.register("Test spinner")
    
    success_called = false
    multi.on("success") do |sp|
      success_called = true
    end
    
    spinner.success
    success_called.should be_true
  end

  it "handles error events" do
    multi = Term::Spinner::Multi.new
    spinner = multi.register("Test spinner")
    
    error_called = false
    multi.on("error") do |sp|
      error_called = true
    end
    
    spinner.error
    error_called.should be_true
  end

  it "handles done events" do
    multi = Term::Spinner::Multi.new
    spinner = multi.register("Test spinner")
    
    done_called = false
    multi.on("done") do |sp|
      done_called = true
    end
    
    spinner.stop
    done_called.should be_true
  end

  it "handles spin events" do
    multi = Term::Spinner::Multi.new
    spinner = multi.register("Test spinner")
    
    spin_called = false
    multi.on("spin") do |sp|
      spin_called = true
    end
    
    spinner.spin
    spin_called.should be_true
  end

  it "runs multiple spinners concurrently" do
    multi = Term::Spinner::Multi.new
    
    results = [] of String
    
    sp1 = multi.register("Task 1")
    sp2 = multi.register("Task 2")
    sp3 = multi.register("Task 3")
    
    sp1.run do
      results << "task1"
    end
    
    sp2.run do
      results << "task2"
    end
    
    sp3.run do
      results << "task3"
    end
    
    results.size.should eq(3)
    results.should contain("task1")
    results.should contain("task2")
    results.should contain("task3")
  end

  it "raises error for invalid event names" do
    multi = Term::Spinner::Multi.new
    
    expect_raises(ArgumentError, /does not exist/) do
      multi.on("invalid_event") { |sp| }
    end
  end

  it "auto-spins with job blocks" do
    multi = Term::Spinner::Multi.new("Main spinner")
    
    executed = [] of String
    
    multi.register("Job 1") do |spinner|
      executed << "job1"
      spinner.success
    end
    
    multi.register("Job 2") do |spinner|
      executed << "job2"
      spinner.success
    end
    
    multi.auto_spin
    
    executed.size.should eq(2)
    executed.should contain("job1")
    executed.should contain("job2")
  end

  it "correctly checks success state" do
    multi = Term::Spinner::Multi.new
    sp1 = multi.register("Spinner 1")
    sp2 = multi.register("Spinner 2")
    
    multi.success?.should be_false
    
    sp1.success
    multi.success?.should be_false
    
    sp2.success
    multi.success?.should be_true
  end

  it "correctly checks error state" do
    multi = Term::Spinner::Multi.new
    sp1 = multi.register("Spinner 1")
    sp2 = multi.register("Spinner 2")
    
    multi.error?.should be_false
    
    sp1.error
    multi.error?.should be_true
    
    sp2.success
    multi.error?.should be_true
  end

  it "correctly checks done state" do
    multi = Term::Spinner::Multi.new
    sp1 = multi.register("Spinner 1")
    sp2 = multi.register("Spinner 2")
    
    multi.done?.should be_false
    
    sp1.stop
    multi.done?.should be_false
    
    sp2.stop
    multi.done?.should be_true
  end

  # This is the specific test case from issue #3
  it "handles multi-spinner run without KeyError" do
    spinner = Term::Spinner::Multi.new(":spinner", format: :dots, interval: 0.2.seconds)
    sp1 = spinner.register ":spinner Test task..."
    
    # Should complete without raising KeyError
    sp1.run do
      # Simulate work
    end
  end
end