require "colorize"
require "../src/term-spinner"

format = "[#{":spinner".colorize(:yellow)}] " + "Task name".colorize(:yellow).to_s
spinner = Term::Spinner.new(format, success_mark: "+".colorize(:green).to_s)

20.times do
  spinner.spin
  sleep(0.1)
end

spinner.success("(successful)".colorize(:green).to_s)
