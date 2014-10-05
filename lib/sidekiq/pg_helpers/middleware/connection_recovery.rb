require "sidekiq/pg_helpers"
require "active_record"
require "sidekiq"
require "pg"

module Sidekiq::PgHelpers::Middleware
  # Helps keep ActiveRecord's connection pool healthy by detecting common Postgres errors
  class ConnectionRecovery
    def initialize
      @reconnection_attempts = 0
    end

    # Detects commons problems with Postgres connections and forces ActiveRecord to close and re-open
    # the offending connection, then automatically retries the error
    def call(*)
      yield
    rescue *PG_CONNECTION_ERRORS => e
      clean_up_connection(e)
      retry
    rescue ActiveRecord::StatementInvalid => e
      raise unless PG_CONNECTION_ERRORS.include?(e.original_exception.class)
      clean_up_connection(e)
      retry
    end

    private

    def clean_up_connection(e)
      if reconnection_attempts >= 4
        Sidekiq.logger.error "Unable to re-establish Postgres connection after five attempts, giving up"
        raise
      end

      Sidekiq.logger.warn "Received #{e.class}, disconnecting and cleaning up our Postgres connection before re-trying"

      # Probably due to an abrupt disconnection: https://devcenter.heroku.com/articles/postgres-logs-errors#pgerror-ssl-syscall-error-eof-detected
      # The next time we access an ActiveRecord connection, it should automatically check out a fresh connection to replace this one
      connection = ActiveRecord::Base.connection
      connection.disconnect!
      ActiveRecord::Base.connection_pool.remove(connection)

      # Ensure we get a fresh connection the next time we access an activerecord object
      ActiveRecord::Base.clear_active_connections!

      self.reconnection_attempts = reconnection_attempts + 1
    end

    attr_accessor :reconnection_attempts

    PG_CONNECTION_ERRORS = [PG::ConnectionBad, PG::UnableToSend].freeze
  end
end
