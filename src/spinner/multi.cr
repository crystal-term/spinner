module Term
  class Spinner
    # Used for managing multiple terminal spinners
    class Multi
      include Enumerable(Spinner)

      delegate :each, :empty?, :size, to: @spinners

      DEFAULT_INSET = {
        top:    "\u250c ",
        middle: "\u251c\u2500\u2500 ",
        bottom: "\u2514\u2500\u2500 ",
      }

      # The current count of all rendered rows
      getter rows : Int32

      @top_spinner : Spinner?
      @last_spin_at : Time?

      # Initialize a multispinner
      #
      # Example:
      # ```
      # spinner = TTY::Spinner::Multi.new
      # ```
      def initialize(message = nil, style = DEFAULT_INSET, **options)
        @inset_opts = style
        @rows = 0
        @spinners = [] of Spinner
        @top_spinner = nil
        @last_spin_at = nil
        @fired = false
        @mutex = Mutex.new

        @callbacks = {
          "success" => [] of Proc(Spinner, Nil),
          "error"   => [] of Proc(Spinner, Nil),
          "done"    => [] of Proc(Spinner, Nil),
          "spin"    => [] of Proc(Spinner, Nil),
        }

        unless message.nil?
          @top_spinner = register(message, **options, observable: false, row: next_row)
        end
      end

      # Register a new spinner
      def register(pattern_or_spinner, observable = true, job = nil, **options)
        spinner = create_spinner(pattern_or_spinner, **options)
        spinner.attach_to(self)
        spinner.job(&job) if job
        observe(spinner) if observable
        @spinners << spinner
        if @top_spinner
          @spinners.each { |sp| sp.redraw_indent if sp.spinning? || sp.done? }
        end
        spinner
      end

      # ditto
      def register(pattern_or_spinner, observable = true, **options, &job : Spinner ->)
        register(pattern_or_spinner, observable, job, **options)
      end

      # Create a spinner instance
      def create_spinner(pattern_or_spinner, **options)
        case pattern_or_spinner
        when ::String
          Term::Spinner.new(pattern_or_spinner, **options)
        when ::Term::Spinner
          pattern_or_spinner
        else
          raise ArgumentError.new("Expected a pattern or spinner, got: #{pattern_or_spinner.class}")
        end
      end

      # Increase a row count
      def next_row
        @rows += 1
      end

      # Get the top level spinner if it exists
      def top_spinner
        raise "No top level spinner" if @top_spinner.nil?
        @top_spinner.not_nil!
      end

      # Auto spin the top level spinner & all child spinners
      # that have scheduled jobs
      def auto_spin
        raise "No top level spinner" if @top_spinner.nil?

        job_count = @spinners.reduce(0) { |acc, s| acc + (s.job ? 1 : 0) }
        jobs = Channel(Nil).new(job_count)

        @spinners.each do |spinner|
          if spinner.job?
            spinner.auto_spin
            spawn do
              jobs.send(spinner.execute_job)
            end
          end
        end

        job_count.times { jobs.receive }
      end

      # Perform a single spin animation
      def spin
        raise "No top level spinner" if @top_spinner.nil?
        throttle { @top_spinner.not_nil!.spin }
      end

      # Pause all spinners
      def pause
        @spinners.each(&.pause)
      end

      # Resume all spinners
      def resume
        @spinners.each(&.resume)
      end

      # Find the number of characters to move into the line
      # before printing the spinner
      def line_inset(line_no)
        return "" if @top_spinner.nil?

        if line_no == 1
          @inset_opts[:top]
        elsif line_no == @spinners.size
          @inset_opts[:bottom]
        else
          @inset_opts[:middle]
        end
      end

      # Check if all spinners are done
      def done?
        (@spinners - [@top_spinner].compact).all?(&.done?)
      end

      # Check if all spinners succeeded
      def success?
        (@spinners - [@top_spinner].compact).all?(&.success?)
      end

      # Check if any spinner errored
      def error?
        (@spinners - [@top_spinner].compact).any?(&.error?)
      end

      # Stop all spinners
      def stop
        @spinners.each(&.stop)
      end

      # Stop all spinners with success status
      def success
        @spinners.each(&.success)
      end

      # Stop all spinners with error status
      def error
        @spinners.each(&.error)
      end

      # Listen on event
      def on(key, &callback : Spinner ->)
        unless @callbacks.has_key?(key)
          raise ArgumentError.new("The event #{key} does not exist. " \
                                  " Use :spin, :success, :error, or :done instead")
        end
        @callbacks[key] << callback
        self
      end

      def synchronize(&block)
        @mutex.lock
        yield
        @mutex.unlock
      end

      # Check if this spinner should revolve to keep constant speed
      # matching top spinner interval
      private def throttle(&block)
        if top_spinner = @top_spinner
          sleep_time = top_spinner.interval
          if @last_spin_at && Time.local - @last_spin_at.not_nil! < sleep_time
            return
          end
        end
        yield
        @last_spin_at = Time.local
      end

      # Fire an event
      private def emit(key, spinner)
        @callbacks[key].each do |block|
          block.call(spinner)
        end
      end

      # Observe spinner for events to notify top spinner of current state
      private def observe(spinner)
        spinner.on("spin") { spin_handler(spinner) }
        spinner.on("success") { success_handler(spinner) }
        spinner.on("error") { error_handler(spinner) }
        spinner.on("done") { done_handler(spinner) }
      end

      # Handle spin event
      private def spin_handler(spinner)
        spin if @top_spinner
        emit("spin", spinner)
      end

      # Handle the success state
      private def success_handler(spinner)
        if success?
          @top_spinner.not_nil!.success if @top_spinner
          emit("success", spinner)
        end
      end

      # Handle the error state
      private def error_handler(spinner)
        if error?
          @top_spinner.not_nil!.error if @top_spinner
          unless @fired
            emit("error", spinner) # fire once
            @fired = true
          end
        end
      end

      # Handle the done state
      private def done_handler(spinner)
        if done?
          @top_spinner.not_nil!.stop if @top_spinner && !error? && !success?
          emit("done", spinner)
        end
      end
    end # MultiSpinner
  end   # Spinner
end     # TTY
