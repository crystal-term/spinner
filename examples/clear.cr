require "../src/term-spinner"

spinner = Term::Spinner.new("[:spinner] Task name", format: :bouncing_ball)

20.times do
  spinner.spin
  sleep(0.1.seconds)
end

spinner.success
