class ActiveRecordFormatter < RSpec::Core::Formatters::DocumentationFormatter
  # This registers the notifications this formatter supports, and tells
  # us that this was written against the RSpec 3.x formatter API.
  RSpec::Core::Formatters.register self, :example_started, :example_passed,
                                         :example_failed, :start, :dump_summary

  def initialize(output)
    super
    @colorizer = ::RSpec::Core::Formatters::ConsoleCodes
  end

  def start(start_notification)
    ActiveRecordProfiler.init

    output.puts "Recording and reporting ActiveRecord select and creation counts."
  end

  def example_started(example)
    ActiveRecordProfiler.reset_example
  end

  def dump_summary(summary)
    formatted = "\nFinished in #{summary.formatted_duration} " \
      "(files took #{summary.formatted_load_time} to load)\n" \
      "#{colorized_expanded_totals(summary)}\n"

    unless summary.failed_examples.empty?
      formatted << summary.colorized_rerun_commands(@colorizer) << "\n"
    end

    output.puts formatted
  end

  protected

  def passed_output(example)
    "#{current_indentation}#{ActiveRecordProfiler.example_counts}" +
      @colorizer.wrap(example.description.strip, :success)
  end

  def failure_output(example)
    "#{current_indentation}#{ActiveRecordProfiler.example_counts}" +
      @colorizer.wrap("#{example.description.strip} (FAILED - #{next_failure_index})", :failure)
  end


  def colorized_expanded_totals(summary)
    if summary.failure_count > 0
      @colorizer.wrap(expanded_totals_line(summary), RSpec.configuration.failure_color)
    elsif summary.pending_count > 0
      @colorizer.wrap(expanded_totals_line(summary), RSpec.configuration.pending_color)
    else
      @colorizer.wrap(expanded_totals_line(summary), RSpec.configuration.success_color)
    end
  end

  def expanded_totals_line(summary)
    summary_text = ::RSpec::Core::Formatters::Helpers.pluralize(summary.example_count, "example")
    summary_text << ", " << ::RSpec::Core::Formatters::Helpers.pluralize(summary.failure_count, "failure")
    summary_text << ", #{summary.pending_count} pending" if summary.pending_count > 0

    [summary_text, ActiveRecordProfiler.totals_line].compact.join(", ")
  end
end

module ActiveRecordProfiler
  extend ActiveSupport::Concern

  SKIP_QUERIES = ["SELECT tablename FROM pg_tables", "select sum(ct) from (select count(*) ct from"]

  @@total_queries = 0
  @@query_count   = 0
  @@total_objects = 0

  @@show_queries  = false
  @@ar_queries    = []

  def self.init
    ActiveSupport::Notifications.subscribe("sql.active_record", method(:record_query))

    @@total_objects = 0
    @@total_queries = 0
  end

  def self.active_record_count
    tables =  (ActiveRecord::Base.connection.tables - ["ar_internal_metadata", "schema_migrations"])
    rows   = tables.map { |t| "select count(*) ct from #{t}" }.join(" union ")
    value  = "select sum(ct) from (#{rows}) t"

    response = ActiveRecord::Base.connection.execute(value)
    response.to_a.first["sum"].to_i
  end

  def self.record_query(*_unused, data)
    return if SKIP_QUERIES.any? { |q| data[:sql].index(q) == 0 }

    @@query_count +=1
    @@ar_queries << [data[:name], data[:sql]].compact.join(": ") if @@show_queries
  end

  def self.example_counts(suffix: " ")
    output = "(%02d, %02d)#{suffix}" % [active_record_count, @@query_count]

    @@total_objects += active_record_count
    @@total_queries += @@query_count

    # TODO is there a sane way to do this?
    #pp @@ar_queries if @@show_queries
    @@ar_queries = []
    output
  end

  def self.reset_example
    @@query_count = 0
  end

  def self.totals_line
    "#{@@total_objects} AR objects, #{@@total_queries} AR queries"
  end

  def self.show_ar_queries
    @@show_queries = true
  end
end
