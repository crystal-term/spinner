require "../../src/term-spinner"

spinners = Term::Spinner::Multi.new "[:spinner] Top level spinner"

sp1 = spinners.register("[:spinner] one")
sp2 = spinners.register("[:spinner] two")
sp3 = spinners.register("[:spinner] three")

sp1.auto_spin
sp2.auto_spin
sp3.auto_spin

sleep(1.seconds)

spinners.pause

sleep(1.seconds)

spinners.resume

sleep(1.seconds)

sp1.stop
sp2.stop
sp3.stop
spinners.stop
