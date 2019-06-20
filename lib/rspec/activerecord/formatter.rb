require_relative "helpers/collector"

class ActiveRecordFormatter < ::RSpec::Core::Formatters::DocumentationFormatter
  attr_reader :collector, :colorizer, :configuration

  ::RSpec::Core::Formatters.register self, :start, :dump_summary,
                                           :example_started, :example_group_started,
                                           :example_group_finished

  def initialize(output)
    super

    @colorizer      = ::RSpec::Core::Formatters::ConsoleCodes
    @collector      = ActiveRecordFormatterHelpers::Collector.new
  end

  def start(start_notification)
    output.puts "Recording and reporting ActiveRecord select and creation counts."
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
    formatted = "\nFinished in #{summary.formatted_duration} " \
      "(files took #{summary.formatted_load_time} to load)\n" \
      "#{colorized_expanded_totals(summary)}\n"

    unless summary.failed_examples.empty?
      formatted << summary.colorized_rerun_commands(colorizer) << "\n"
    end

    output.puts formatted
    write_profile_summary
  end

  def write_profile_summary
    output_report_filename = Time.now.strftime("ar_%Y_%m_%d_%H_%m_%S.txt")
    report_dir = Rails.root.join("tmp", "profile")
    output_report_path = report_dir.join(output_report_filename)

    output.puts "\nOutputting Detailed Profile Data to #{output_report_path}"
    Dir.mkdir(report_dir) unless File.exists?(report_dir)
    File.open(output_report_path, "wb") do |f|
      f.puts "#{collector.total_objects} AR objects, #{collector.total_queries} AR queries"

      f.puts ""
      f.puts "Worst Example Groups by Object Creation"
      collector.most_expensive_groups.first(50).each do |name, count|
        f.puts "%-5s %s" % [count, name]
      end

      f.puts ""
      f.puts "Most Common Queries"
      collector.most_common_query_names.first(50).each do |name, count|
        f.puts "%-5s %s" % [count, name]
      end
    end
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
