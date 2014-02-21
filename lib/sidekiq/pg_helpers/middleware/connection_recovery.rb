require "sidekiq/pg_helpers"
require "active_record"
require "sidekiq"
require "pg"

module Sidekiq::PgHelpers
  class ConnectionRecovery
    def initialize
      @reconnection_attempts = 0
    end

    def call(worker_class,msg,queue)
      yield
    rescue PG::ConnectionBad, PG::UnableToSend => e
      if @reconnection_attempts >= 4
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

      @reconnection_attempts += 1
      retry
    end
  end
end
