require 'active_support/notifications'

module ActiveRecordFormatterHelpers
  class Collector
    attr_reader :query_count, :objects_count, :total_queries, :total_objects,
                :query_names, :active_groups, :group_counts, :groups_encountered

    SKIP_QUERIES = ["SELECT tablename FROM pg_tables", "select sum(ct) from (select count(*) ct from"]

    def initialize
      #@unnamed_queries = []
      @query_count    = 0
      @groups_encountered = 0
      @objects_count  = 0
      @total_queries  = 0
      @total_objects  = 0
      @query_names    = Hash.new(0)
      @group_counts   = Hash.new(0)
      @active_groups  = []

      ActiveSupport::Notifications.subscribe("sql.active_record", method(:record_query))
    end

    def record_query(*_unused, data)
      return if SKIP_QUERIES.any? { |q| data[:sql].index(q) == 0 }

      inc_query
      inc_object if query_is_an_insert?(data[:sql])
      inc_query_name(data)
    end

    def most_common_query_names
      query_names.sort_by(&:last).reverse
    end

    def most_expensive_groups
      group_counts.sort_by(&:last).reverse
    end

    def reset_example(_)
      @query_count   = 0
      @objects_count = 0
    end

    def group_started(group)
      @groups_encountered += 1

      return unless group.parent_groups.length > 1

      active_groups.push(group_path(group))
    end

    def group_finished(group)
      active_groups.delete(group_path(group))
    end

    protected

    def inc_object
      @objects_count  += 1
      @total_objects  += 1

      active_groups.each do |group|
        @group_counts[group] += 1
      end
    end

    def inc_query
      @query_count    += 1
      @total_queries  += 1
    end

    def inc_query_name(data)
      name = data[:name] || "Unnamed"

      # In older versions of Rails, insert statements are just counted as SQL
      # queries, which means that all the queries are just bunchedup at the top.
      # Makes this data pretty useless. So anyway, try to suss out a name for
      # at least those insertions (which are much more frequent than, say,
      # updates in a test suite anyway).
      if data[:name] == "SQL" && query_is_an_insert?(data[:sql])
        table = data[:sql].scan(/INSERT INTO "(\w+)"/).first.first
        name = "#{table} Create"
      elsif query_is_a_full_table_delete?(data[:sql])
        table = data[:sql].scan(/DELETE FROM "(\w+)"/).first.first
        name = "Full Delete Table"
      # TODO: truncate table
      elsif query_is_transaction_management?(data[:sql])
        name = "Transaction Management"
      elsif query_is_schema_detection?(data[:sql])
        name = "SCHEMA"
      elsif query_is_trigger_management?(data[:sql])
        name = "Trigger Management"
      elsif query_refreshes_materialized_view?(data[:sql])
        name = "Refresh Materialized View"
      end


      # In older versions of Rails, insert statements are just counted as SQL
      # queries, which means that all the queries are just bunchedup at the top.
      # Makes this data pretty useless. So anyway, try to suss out a name for
      # at least those insertions (which are much more frequent than, say,
      # updates in a test suite anyway).
      #if data[:name].nil? && query_is_a_delete?(data[:sql])
      #  table = data[:sql].scan(/DELETE FROM "(\w+)"/).first.first
      #  name = "#{table} Delete"
      #end

      #@unnamed_queries << data if name == "Unnamed"

      query_names[name] += 1
    end

    def group_path(group)
      group.parent_groups.reverse.map(&:description).join(' ')
    end

    # TODO: what happens if we try to create many records at once?
    # TODO: are there any false positives we need to worry about? false negatives?
    def query_is_an_insert?(query)
      query =~ /^INSERT INTO/
    end

    def query_is_a_delete?(query)
      query =~ /^DELETE FROM/
    end

    def query_is_a_full_table_delete?(query)
      query =~ /^DELETE FROM [a-z_\."]*;$/i
    end

    def query_is_transaction_management?(query)
      query =~ /^(COMMIT|BEGIN|ROLLBACK|SAVEPOINT|RELEASE SAVEPOINT)/
    end

    def query_is_schema_detection?(query)
      query =~ /SELECT .* FROM pg_tables/m ||
        query =~ /SELECT .* FROM information_schema.views/
    end

    def query_is_trigger_management?(query)
      query =~ /(DISABLE|ENABLE) TRIGGER ALL/m
    end

    def query_refreshes_materialized_view?(query)
      query =~ /REFRESH MATERIALIZED VIEW/m
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
