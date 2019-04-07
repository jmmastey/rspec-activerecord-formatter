require 'active_support/notifications'

module ActiveRecordFormatterHelpers
  class Collector
    attr_reader :query_count, :objects_count, :total_queries, :total_objects, :query_names
    SKIP_QUERIES = ["SELECT tablename FROM pg_tables", "select sum(ct) from (select count(*) ct from"]

    def initialize
      @query_count    = 0
      @objects_count  = 0
      @total_queries  = 0
      @total_objects  = 0
      @query_names    = Hash.new(0)

      ActiveSupport::Notifications.subscribe("sql.active_record", method(:record_query))
    end

    def record_query(*_unused, data)
      return if SKIP_QUERIES.any? { |q| data[:sql].index(q) == 0 }

      @query_count    += 1
      @total_queries  += 1

      if query_is_an_insert?(data[:sql])
        @objects_count  += 1
        @total_objects  += 1
      end

      name = data[:name] || "Unnamed"
      @query_names[name] += 1
    end

    def most_common_query_names
      @query_names.sort_by(&:last).reverse
    end

    def reset_example
      @query_count   = 0
      @objects_count = 0
    end

    protected

    # TODO: what happens if we try to create many records at once?
    # TODO: are there any false positives we need to worry about? false negatives?
    def query_is_an_insert?(query)
      query =~ /INSERT INTO/
    end
  end
end

# This is actually a really nice way to count records, but sadly
# we have no way to hook a before action that preceeds DatabaseCleaner.
# That makes it awfully tough to count anything at all.
# def self.active_record_count
#   tables =  (ActiveRecord::Base.connection.tables - ["ar_internal_metadata", "schema_migrations"])
#   rows   = tables.map { |t| "select count(*) ct from #{t}" }.join(" union ")
#   value  = "select sum(ct) from (#{rows}) t"
#
#   response = ActiveRecord::Base.connection.execute(value)
#   response.to_a.first["sum"].to_i
# end
