require "../src/spinner"

Term::Spinner::FORMATS.keys.each do |token|
  spinner = Term::Spinner.new("#{token}: :spinner", format: token, hide_cursor: true)
  20.times do
    spinner.spin
    sleep(0.1)
  end
  spinner.stop
end
