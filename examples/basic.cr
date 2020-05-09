require "../src/term-spinner"

spinner = Term::Spinner.new("Loading :spinner ... ", format: :spin_2)

20.times do
  spinner.spin
  sleep(0.1)
end

spinner.stop("done")
