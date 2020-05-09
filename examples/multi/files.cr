require "../../src/term-spinner"

spinners = Term::Spinner::Multi.new "[:spinner] Downloading files..."

["file 1", "file 2", "file 3"].each do |file|
  spinners.register("[:spinner] #{file}") do |sp|
    sleep(rand * 5)
    sp.success("success")
  end
end

spinners.auto_spin
