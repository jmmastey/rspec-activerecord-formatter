module ActiveRecordFormatter
  class Collector
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
end
