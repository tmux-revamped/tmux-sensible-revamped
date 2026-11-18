# frozen_string_literal: true

require "bashcov"

Bashcov.parse_options!(ARGV)

require "bashcov/runner"
require "io/nonblock"
require_relative "bashcov-lexer"

blocking_pipe = Module.new do
  define_method(:initialize) do |field_stream|
    super(field_stream)
    @write.nonblock = false
  end
end
Bashcov::Xtrace.prepend(blocking_pipe)

record_reader = Module.new do
  define_method(:read) do
    @field_stream.read = @read
    start = Bashcov::Xtrace::PS4_START_REGEXP
    width = Bashcov::Xtrace::FIELDS.length + 1
    fields = @field_stream.each_field(Bashcov::Xtrace.delimiter)
    previous = nil
    fields.slice_before { |field| field.match?(start) }.each do |record|
      count_record(previous, width) if previous
      previous = record
    end
    count_record(previous.length == width + 1 ? previous.first(width) : previous, width) if previous
    @files
  rescue StandardError
    IO.copy_stream(@read, IO::NULL)
    raise
  ensure
    @read.close unless @read.closed?
  end

  define_method(:count_record) do |record, width|
    return unless record.length == width && record.first.match?(Bashcov::Xtrace::PS4_START_REGEXP)

    parse_hit!(*record.drop(1))
  rescue Bashcov::XtraceError
    nil
  end
end
Bashcov::Xtrace.prepend(record_reader)

Thread.report_on_exception = false
runner = Bashcov::Runner.new(Bashcov.command)
status, coverage = File.open(File.join(Bashcov.root_directory, "coverage", "bashcov-warnings.log"), "a") do |quiet|
  original_stderr = $stderr
  $stderr = quiet
  [runner.run, runner.result]
ensure
  $stderr = original_stderr
end

require "simplecov"

SimpleCov.print_error_status = false
SimpleCov.start
SimpleCov.command_name(Bashcov.command_name)
SimpleCov.root(Bashcov.root_directory)
SimpleCov::ResultMerger.store_result(SimpleCov::Result.new(coverage))
SimpleCov.at_exit { :quiet }

exit(status.exitstatus)
