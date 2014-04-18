# sidekiq-pg_helpers

Helper code for using Sidekiq with Postgres. Extracted from our production code.

### ConnectionRecovery

This middleware helps Sidekiq bad Postgres connections on the fly, whenever they fail:
```ruby
require "sidekiq/pg_helpers/middleware/connection_recovery"

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.insert_after Sidekiq::Middleware::Server::ActiveRecord, Sidekiq::PgHelpers::Middleware::ConnectionRecovery
  end
end
```
