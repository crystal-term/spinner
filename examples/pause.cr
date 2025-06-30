require "../src/term-spinner"

spinner = Term::Spinner.new("[:spinner] Task name")

spinner.auto_spin

sleep(2.seconds)

spinner.pause

sleep(2.seconds)

spinner.resume

sleep(2.seconds)

spinner.stop

puts
