require "../../src/term-spinner"

spinners = Term::Spinner::Multi.new "[:spinner] main", format: :pulse

sp1 = spinners.register "[:spinner] one", format: :classic
sp2 = spinners.register "[:spinner] two", format: :classic
sp3 = spinners.register "[:spinner] three", format: :classic

ch = Channel(Nil).new(3)

spawn { 20.times { sleep(0.2); sp1.spin }; ch.send(sp1.success) }
spawn { 40.times { sleep(0.2); sp2.spin }; ch.send(sp2.success) }
spawn { 80.times { sleep(0.2); sp3.spin }; ch.send(sp3.error) }

3.times { ch.receive }
