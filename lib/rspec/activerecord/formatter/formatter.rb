module ActiveRecordFormatter
  class Formatter < ::RSpec::Core::Formatters::DocumentationFormatter
    attr_reader :collector, :colorizer, :configuration

    ::RSpec::Core::Formatters.register self, :start, :dump_summary,
                                             :example_started, :example_passed, :example_failed

    def initialize(output)
      super

      @colorizer      = ::RSpec::Core::Formatters::ConsoleCodes
      @collector      = ActiveRecordFormatter::Collector.new
    end

    def start(start_notification)
      output.puts "Recording and reporting ActiveRecord select and creation counts."
    end

    def example_started(example)
      collector.reset_example
    end

    def dump_summary(summary)
      formatted = "\nFinished in #{summary.formatted_duration} " \
        "(files took #{summary.formatted_load_time} to load)\n" \
        "#{colorized_expanded_totals(summary)}\n"

      unless summary.failed_examples.empty?
        formatted << summary.colorized_rerun_commands(colorizer) << "\n"
      end

      output.puts formatted
    end

    protected

    def passed_output(example)
      "#{current_indentation}#{example_counts}" +
        colorizer.wrap(example.description.strip, :success)
    end

    def failure_output(example)
      "#{current_indentation}#{example_counts}" +
        colorizer.wrap("#{example.description.strip} (FAILED - #{next_failure_index})", :failure)
    end

    def example_counts(suffix: " ")
      "(%02d, %02d)#{suffix}" % [collector.objects_count, collector.query_count]
    end

    def colorized_expanded_totals(summary)
      if summary.failure_count > 0
        colorizer.wrap(expanded_totals_line(summary), RSpec.configuration.failure_color)
      elsif summary.pending_count > 0
        colorizer.wrap(expanded_totals_line(summary), RSpec.configuration.pending_color)
      else
        colorizer.wrap(expanded_totals_line(summary), RSpec.configuration.success_color)
      end
    end

    def expanded_totals_line(summary)
      summary_text = ::RSpec::Core::Formatters::Helpers.pluralize(summary.example_count, "example")
      summary_text << ", " << ::RSpec::Core::Formatters::Helpers.pluralize(summary.failure_count, "failure")
      summary_text << ", #{summary.pending_count} pending" if summary.pending_count > 0
      summary_text << ", #{collector.total_objects} AR objects"
      summary_text << ", #{collector.total_queries} AR queries"

      summary_text
    end
  end
end
