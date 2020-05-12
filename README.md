<div align="center">
  <img src="./assets/term-logo.png" alt="term logo">
</div>

# Term::Spinner

![spec status](https://github.com/crystal-term/spinner/workflows/specs/badge.svg)

> A terminal spinner for tasks that have non-deterministic time frame.

**Term::Screen** provides an independent spinner component for crystal-term.

<div align="center">
  <img src="./assets/demo.gif" alt="formats demo">
</div>

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     term-spinner:
       github: crystal-term/spinner
   ```

2. Run `shards install`

## Usage

First the library must be required:

```crystal
require "term-spinner"
```

`Term::Spinner` by default requires no arguments and defaults to the `:classic` formatter:

```crystal
spinner = Term::Spinner.new
```

In addition you can provide a format message with a `:spinner` token where you would like the spinner to appear:

```crystal
spinner = Term::Spinner.new("[:spinner] Loading ...", format: :pulse_2)

spinner.auto_spin # Automatic animation with default interval

sleep(2) # Perform task

spinner.stop("Done!") # Stop animation
```

This would produce an animation in your terminal that looks something like this:

```crystal
[|] Loading ...
```

and when finished:

```crystal
[✖] Loading ... Done!
```

## API

### `#spin`

This is the main workhorse of the spinner. Looping over the `spin` method will animate a given spinner.

```crystal
loop do
  spinner.spin
end
```

### `#auto_spin`

The `auto_spin` method performs automatic spinning in its own dedicated fiber.

```
spinner.auto_spin
```

The speed at which the spinning occurs is determined by the `interval` parameter, or defaults to the given `format` interval. The interval is a number in hertz, or `(n * 100) milliseconds`.

### `#pause`

Pauses a spinner that's using `auto_spin`:

```crystal
spinner.pause
```

### `#resume`

Resumes a paused spinner:

```crystal
spinner.resume
```

### `#run`

Use `run`, passing a block with a job that will run and display the spinning animation. From within the block you can call `stop`, `success`, or `error` to finish the animation, or just allow the animation to finish when the block exits:

```crystal
spinner.run do |spinner|
  ...
end
```

Optionally you can pass a stop message to the `run` command to display when the animation is finished:

```crystal
spinner.run("Done!") do |spinner|
  ...
end
```

The stop message passed to `run` is overridden if you use `stop`, `success`, or `error`.

### `#start`

To set a start time or reuse the same spinner after it has stopped, call `start`:

```crystal
spinner.start
```

### `#stop`

In order to stop the spinner, call `stop`. This will finish drawing the spinning animation and go to a new line:

```crystal
spinner.stop
```

You can also pass a message to stop, which will be displayed after the animation:

```crystal
spinner.stop("Done!")
```

#### `#success`

Use `success` to stop the spinning animation and replace the spinning symbol with `success_mark` (defaults to `✔`) to indicate successful completion:

```crystal
spinner = Term::Spinner.new("[:spinner] Task name")
spinner.success("(successful)")
```

This will produce:

```crystal
[✔] Task name (successful)
```

#### `#error`

Use `error` to stop the spinning animation and replace the spinning symbol with `error_mark` (defaults to `✖`) to indicate a failed completion:

```crystal
spinner = Term::Spinner.new("[:spinner] Task name")
spinner.error("(error)")
```

This will produce:

```crystal
[✖] Task name (error)
```

### `#update`

Use `update` to dynamically change label name(s). Labels can be used like `:spinner`, allowing you to inject a value into a format string while the spinner is running.

Provide arbitrary token name(s) in the message string, such as `:status`:

```crystal
spinner = TTY::Spinner.new("[:spinner] :status")
```

and then pass token name and value:

```crystal
spinner.update(status: "Downloading File 1")
```

next start the animation:

```crystal
spinner.run { ... }
# => | Downloading File 1
```

Once the animation finishes, or even while it's still running, you can update the status to whatever you want:

```crystal
spinner.update(status: "Downloading File 2")
```

### `#reset`

Reset the spinner to its initial state:

```crystal
spinner.reset
```

## Configuration

These are the values that can be supplied to `Term::Spinner.new` to customize the behavior of the spinner.

### :format

Use one of the prefefined spinner styles by passing the formatting token `:format`:

```crystal
spinner = Term::Spinner.new(format: :pulse_2)
```

All accepted formats are located in [/src/spinner/format.cr](https://github.com/crystal-term/spinner/blob/master/src/spinner/format.cr)

If you want an example of each of the formats in action, you can try running [/examples/formats.cr](https://github.com/crystal-term/spinner/blob/master/examples/formats.cr)

### :frames

You can always set your own custom frames using the `frames` option:

```crystal
spinner = Term::Spinner.new(frames: [".", "o", "0", "@", "*"])
```

### :interval

The `interval` option accepts a number representing `Hz`. For instance, a value of `10`, the default, will result in 10 animation frames per second. You can also pass in a `Time::Span` ti use as a delay between frames.

```crystal
spinner = Term::Spinner.new(interval: 20) # 20 Hz (20 times per second)
```

### :hide_cursor

Hides cursors whens pinning animation is running. Defaults to `false`.

```crystal
spinner = Term::Spinner.new(hide_cursor: true)
```

### :clear

After spinner is finished, clears its output. Defaults to `false`.

```crystal
spinner = Term::Spinner.new(clear: true)
```

### :success_mark

To change marker indicating successful completion use the `success_mark` option:

```crystal
spinner = Term::Spinner.new(success_mark: "+")
```

### :error_mark

To change marker indicating an error completion use the `error_mark` option:

```crystal
spinner = Term::Spinner.new(error_mark: "x")
```

### :output

The spinner only outputs to a console and when output is redirected to a file or a pipe it does nothing. This is so, for example, your error logs do not overflow with spinner output.

You can change where console output is streamed with `output` option:

```crystal
spinner = Term::Spinner.new(output: STDOUT)
```

## Term::Spinner::Multi API

### `#register`

Create and register a `Term::Spinner` under the multispinner

```crystal
new_spinner = multi_spinner.register("[:spinner] Task 1 name", **options)
# or
#   spinner = Term::Spinner.new("[:spinner] one")
#   sp1 = multi_spinner.register(spinner)
```

If no options are given it will use the options given to the multi_spinner when it was initialized to create the new spinner. If options are passed, they will override any options given to the top level spinner.

### `#auto_spin`

To create a top level spinner that tracks the activity of all the registered spinners, the multispinner has to be given a message on initialization:

```crystal
spinners = Term::Spinner::Multi.new("[:spinner] Top level spinner")
```

The top level multi spinner will perform spinning animation automatically when at least one of the registered spinners starts spinning.

If you register spinners without any tasks then you will have to manually control when the multispinner finishes by calling `stop`, `success` or `error`.

Alternatively, you can register spinners with tasks that will automatically animate and finish spinners when respective tasks are done.

The speed with which the spinning happens is determined by the `:interval` parameter. All the spinner formats have their default intervals specified.

#### manual async

In the case where you wish to have complete control over multiple spinners, you will need to perform all actions manually.

For example, create a multispinner that will track the status of all registered spinners:

```crystal
spinners = Term::Spinner::Multi.new("[:spinner] top")
```

and then register all spinners with their formats:

```crystal
sp1 = spinners.register "[:spinner] one"
sp2 = spinners.register "[:spinner] two"
```

Once registered, you can set spinners running in separate threads:

```crystal
sp1.auto_spin
sp2.auto_spin
```

Finally, you need to stop each spinner manually, in our case we mark the second spinner as failure which in turn will stop the top level multi spinner automatically and mark it as failure:

```crystal
sp1.success
sp2.error
```

The result may look like this:

```crystal
┌ [✖] top
├── [✔] one
└── [✖] two
```

#### auto async tasks

In the case when you wish to execute async tasks and update individual spinners automatically, in any order, about their task status use `#register` and pass additional block parameter with the job to be executed.

For example, create a multi spinner that will track status of all registered spinners:

```crystal
spinners = TTY::Spinner::Multi.new("[:spinner] top")
```

and then register spinners with their respective tasks:

```crystal
spinners.register("[:spinner] one") { |sp| sleep(2); sp.success("yes 2") }
spinners.register("[:spinner] two") { |sp| sleep(3); sp.error("no 2") }
```

Finally, call `#auto_spin` to kick things off:

```crystal
spinners.auto_spin
```

If any of the child spinners stop with an error then the top level spinner will be marked as failure.

### `#stop`

In order to stop the multi spinner call stop. This will stop the top level spinner, if it exists, and any sub-spinners are still spinning.

```crystal
spinners.stop
```

### `#success`

Use success call to stop the spinning animation and replace the spinning symbol with a check mark character to indicate successful completion. This will also call `#success` on any sub-spinners that are still spinning.

```crystal
spinners.success
```

### `#error`

Use error call to stop the spinning animation and replace the spinning symbol with cross character to indicate error completion. This will also call `#error` on any sub-spinners that are still spinning.

```crystal
spinners.error
```

### `:style`

In addition to all the standard `Spinner` configuration options you can style a multispinner like so:

```crystal
spinner = Term::Spinner::Multi.new("[:spinner] parent", style: {
  top: ". "
  middle: "|-> "
  bottom: "|__ "
})
```

## Events

`Term::Spinner` emits `:done`, `:success`, and `:error` events. You can listen for these using the `#on` method.

```crystal
spinner.on(:done) { ... }
spinner.on(:error) { ... }
spinner.on(:success) { ... }
```

## Contributing

1. Fork it (<https://github.com/watzon/spinner/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Chris Watson](https://github.com/watzon) - creator and maintainer
