class ActiveRecordDocumentationFormatter < ::RSpec::Core::Formatters::DocumentationFormatter
  attr_reader :collector, :colorizer, :report

  ::RSpec::Core::Formatters.register self, :start, :dump_summary,
                                           :example_started, :example_group_started,
                                           :example_group_finished

  def initialize(output)
    super

    @colorizer  = ::RSpec::Core::Formatters::ConsoleCodes
    @collector  = ActiveRecordFormatterHelpers::Collector.new
    @report     = ActiveRecordFormatterHelpers::Report.new(collector)
  end

  def start(_start_notification)
    output.puts "Recording and reporting ActiveRecord select and creation counts."
    super
  end

  def example_group_started(example_group)
    collector.group_started(example_group.group)
    super
  end

  def example_group_finished(example_group)
    collector.group_finished(example_group.group)
    super
  end

  def example_started(example)
    collector.reset_example(example)
  end

  def dump_summary(summary)
    base = ActiveRecordFormatterBase.new(summary, collector)
    output.puts base.colorized_summary

    output.puts "\nOutputting Detailed Profile Data to #{report.report_path}"
    report.write
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
end
