class ActiveRecordFormatterBase
  attr_reader :colorizer, :summary, :collector

  def initialize(summary, collector)
    @colorizer  = ::RSpec::Core::Formatters::ConsoleCodes
    @summary    = summary
    @collector  = collector
  end

  def colorized_summary
    formatted = "\nFinished in #{summary.formatted_duration} " \
      "(files took #{summary.formatted_load_time} to load)\n" \
      "#{colorized_expanded_totals}\n"

    unless summary.failed_examples.empty?
      formatted << summary.colorized_rerun_commands(colorizer) << "\n"
    end

    formatted
  end

  private

  def colorized_expanded_totals
    if summary.failure_count > 0
      colorizer.wrap(expanded_totals_line, RSpec.configuration.failure_color)
    elsif summary.pending_count > 0
      colorizer.wrap(expanded_totals_line, RSpec.configuration.pending_color)
    else
      colorizer.wrap(expanded_totals_line, RSpec.configuration.success_color)
    end
  end

  def expanded_totals_line
    summary_text = ::RSpec::Core::Formatters::Helpers.pluralize(summary.example_count, "example")
    summary_text << ", " << ::RSpec::Core::Formatters::Helpers.pluralize(summary.failure_count, "failure")
    summary_text << ", #{summary.pending_count} pending" if summary.pending_count > 0
    summary_text << ", #{collector.total_objects} AR objects"
    summary_text << ", #{collector.total_queries} AR queries"

    summary_text
  end
end
