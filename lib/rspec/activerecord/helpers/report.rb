module ActiveRecordFormatterHelpers
  class Report
    attr_reader :report_path, :default_path, :report_dir, :collector

    def initialize(collector)
      @collector = collector

      @report_dir   = Rails.root.join("tmp", "profile")
      @report_path  = report_dir.join(timestamped_filename)
      @default_path = report_dir.join('ar_most_recent.txt')
    end

    def write
      write_file(file_path: report_path)
      write_file(file_path: default_path)
    end

    private

    def timestamped_filename
      Time.now.strftime("ar_%Y_%m_%d_%H_%m_%S.txt")
    end

    def write_file(file_path:)
      Dir.mkdir(report_dir) unless File.exists?(report_dir)

      File.open(file_path, "wb") do |f|
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
  end
end
