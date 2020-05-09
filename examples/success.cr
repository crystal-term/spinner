require "../src/term-spinner"

spinner = Term::Spinner.new("[:spinner] Task name")

20.times do
  spinner.spin
  sleep(0.1)
end

spinner.success("(success)")
