require "term-cursor"

require "./spinner/formats"
require "./spinner/multi"
require "./spinner/version"

module Term
  class Spinner
    # Raised when attempting to join dead thread
    class NotSpinningError < Exception; end

    ECMA_CSI = "\x1b["

    MATCHER = /:spinner/
    TICK    = "✔"
    CROSS   = "✖"

    # The object that responds to print call defaulting to stderr
    getter output : IO::FileDescriptor

    # Whether to show or hide the cursor
    getter hide_cursor : Bool

    # The message to print before the spinner
    getter message : String

    # The animation frames
    getter frames : Array(String)

    # The animation interval
    getter interval : Time::Span

    # Tokens for the message
    getter tokens : Hash(String, String)

    # The current row inside a multi spinner
    getter row : Int32?

    # Whether the spinner has completed spinning
    getter? done : Bool

    # Whether this is the first time this spinner has ran
    getter? first_run : Bool

    # The current spinner state
    getter state : Symbol

    getter multispinner : Multi?

    @succeeded : Bool?
    @started_at : Time?
    @callbacks : Hash(String, Array(Proc(Spinner, Nil)))
    @channel : Channel(Nil)?
    @work : Channel(Nil)?
    @job : Proc(Spinner, Nil)?
    @mutex : Mutex

    def initialize(*args, **options)
      @mutex = Mutex.new
      @message = args[0]? || options[:message]? || ":spinner"
      @tokens = {} of String => String

      format = FORMATS[options.fetch(:format, :classic).to_s]
      @frames = options[:frames]? || format[:frames]
      interval = options[:interval]? || format[:interval]? || 10
      @interval = interval.is_a?(Time::Span) ? interval : (interval * 10).milliseconds

      @output = options[:output]? || STDERR
      @hide_cursor = options[:hide_cursor]? || false
      @clear = options[:clear]? || false
      @success_mark = options[:success_mark]? || TICK
      @error_mark = options[:error_mark]? || CROSS
      @row = options[:row]?
      @callbacks = Hash(String, Array(Proc(Spinner, Nil))).new { |h, k| h[k] = [] of Proc(Spinner, Nil) }
      @channel = nil
      @job = nil
      @multispinner = nil
      @current = 0
      @done = false
      @state = :stopped
      @succeeded = nil
      @first_run = true
      @started_at = nil
    end

    def reset
      @current = 0
      @done = false
      @state = :stopped
      @succeeded = false
      @first_run = true
    end

    # Notifies the `Spinner` that it is running under a multispinner
    def attach_to(multispinner : Multi)
      @multispinner = multispinner
    end

    # Whether the spinner is spinning
    def spinning?
      @state == :spinning
    end

    # Whether the spinner is paused
    def paused?
      @state == :paused
    end

    # Pause the spinner
    def pause
      return if paused?
      @mutex.synchronize do
        @state = :paused
      end
    end

    # Resume spinner
    def resume
      return unless paused?
      @mutex.synchronize do
        @state = :spinning
      end
    end

    # Whether spinner is stopped
    def stopped?
      @state == :stopped
    end

    # Stop the running spinner
    def stop(stop_message = "")
      return if done?

      clear_line
      return if @clear

      data = message.gsub(MATCHER, next_char)
      data = replace_tokens(data)

      unless stop_message.empty?
        data += " " + stop_message
      end

      write(data, false)
      write("\n", false) unless @clear || @multispinner
    ensure
      @done = true
      @state = :stopped
      @started_at = nil

      if @hide_cursor
        write(Term::Cursor.show, false)
      end

      emit(:done)
      # kill
      # @mutex.unlock
    end

    # Whether the spinner is in the success state.
    # When true the spinner is marked with a success mark.
    def success?
      @succeeded == true
    end

    # Whether the spinner is in the error state. This is only true
    # temporarily while it is being marked with a failure mark.
    def error?
      @succeeded == false
    end

    # Register a callback
    def on(name, &block : Spinner ->)
      @mutex.synchronize do
        @callbacks[name.to_s] << block
      end
    end

    # Start timer and unlock spinner
    def start
      @started_at = Time.local
      @done = false
      reset
    end

    # Add job to the spinner
    def job(&work : Spinner ->)
      @mutex.synchronize do
        @job = work
      end
    end

    # Get the current job
    def job
      @job
    end

    # Execute this spinner job
    def execute_job
      if job = @job
        job.call(self)
      end
    end

    # Check if this spinner has a scheduled job
    def job?
      !@job.nil?
    end

    # Start automatic spinning animation
    def auto_spin
      start
      sleep_time = @interval

      spin
      @channel = Channel(Nil).new.tap do |ch|
        spawn(same_thread: true) do
          sleep(sleep_time)
          until stopped?
            sleep(sleep_time)
            spin unless paused?
          end
          ch.send(nil)
        end
      end
    ensure
      if @hide_cursor
        write(Term::Cursor.show, false)
      end
    end

    # Runspinner while executing job
    def run(stop_message = "", &block : Spinner ->)
      job(&block)
      auto_spin
      yield self
    ensure
      stop(stop_message)
    end

    # Duration of the spinning animation
    def duration
      if started_at = @started_at
        Time.local - started_at
      end
    end

    # Perform a spin
    def spin
      @mutex.synchronize do
        return if @done
        emit(:spin)

        if @hide_cursor && !spinning?
          write(Term::Cursor.hide)
        end

        data = message.gsub(MATCHER, @frames[@current])
        data = replace_tokens(data)
        write(data, true)
        @current = (@current + 1) % @frames.size
        @state = :spinning
        data
      end
    end

    # Redraw the indent for this spinner, if it exists
    def redraw_indent
      if @hide_cursor && !spinning?
        write(Term::Cursor.hide)
      end

      write("", false)
    end

    # Retrieve next character
    def next_char
      if success?
        @success_mark
      elsif error?
        @error_mark
      else
        @frames[@current - 1]
      end
    end

    # Finish spinning and set state to :success
    def success(stop_message = "")
      return if done?

      @mutex.synchronize do
        @succeeded = true
        stop(stop_message)
        emit(:success)
      end
    end

    # Finish spinning and set state to :error
    def error(stop_message = "")
      return if done?

      @mutex.synchronize do
        @succeeded = false
        stop(stop_message)
        emit(:error)
      end
    end

    # Clear the current line
    def clear_line
      write(ECMA_CSI + "0m" + Term::Cursor.clear_line)
    end

    # Update string formatting tokens
    def update(**tokens)
      @mutex.synchronize do
        clear_line if spinning?
        @tokens = @tokens.merge(tokens.to_h.transform_keys(&.to_s).transform_values(&.to_s))
      end
    end

    def tty?
      output.responds_to?(:tty?) ? output.tty? : false
    end

    def execute_on_line(&block)
      if multispinner = @multispinner
        multispinner.synchronize do
          if @first_run
            @row ||= multispinner.next_row
            yield
            output.print "\n"
            @first_run = false
          else
            lines_up = (multispinner.rows + 1) - @row.not_nil!
            output.print Term::Cursor.save
            output.print Term::Cursor.up(lines_up)
            yield
            output.print Term::Cursor.restore
          end
        end
      else
        yield
      end
    end

    private def emit(name)
      @callbacks[name.to_s].each do |cb|
        cb.call(self)
      end
    end

    # Write data out to output
    private def write(data, clear_first = false)
      return unless tty? # write only to terminal

      execute_on_line do
        output.print(Term::Cursor.column(1)) if clear_first
        # If there's a top level spinner, print with inset
        if multispinner = @multispinner
          characters_in = multispinner.line_inset(@row.not_nil!)
          output.print("#{characters_in}#{data}")
        else
          output.print(data)
        end
        output.flush
      end
    end

    # Replace any token inside string
    private def replace_tokens(string)
      @tokens.each do |name, val|
        string = string.gsub(/\:#{name}/, val)
      end
      string
    end
  end
end
