require "../../src/term-spinner"

spinners = Term::Spinner::Multi.new "[:spinner] top"

sp1 = spinners.register("[:spinner] one") { |sp| sleep(2.seconds); sp.success("... yes") }
sp2 = spinners.register("[:spinner] two") { |sp| sleep(3.seconds); sp.error("... no") }
sp3 = spinners.register("[:spinner] three") { |sp| sleep(1.seconds); sp.success("... yes") }

spinners.auto_spin
