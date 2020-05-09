require "../../src/term-spinner"

spinners = Term::Spinner::Multi.new "[:spinner] top"

sp1 = spinners.register("[:spinner] one") { |sp| sleep(2); sp.success("... yes") }
sp2 = spinners.register("[:spinner] two") { |sp| sleep(3); sp.error("... no") }
sp3 = spinners.register("[:spinner] three") { |sp| sleep(1); sp.success("... yes") }

spinners.auto_spin
