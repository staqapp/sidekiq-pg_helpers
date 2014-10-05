require "spec_helper"
require "sidekiq/pg_helpers/middleware/connection_recovery"

shared_examples "helpful middleware" do
  before do
    subject.call(:worker_class,:msg,:queue,&block)
  end

  it "logs the issue" do
    expect(logger).to have_received(:warn).with(an_instance_of(String))
  end

  it "disconnects the bad connection" do
    expect(connection).to have_received(:disconnect!)
  end

  it "removes the bad connection from ActiveRecord's connection pool" do
    expect(connection_pool).to have_received(:remove).with(connection)
  end

  it "clears active connections, just in case" do
    expect(ActiveRecord::Base).to have_received(:clear_active_connections!)
  end
end

describe Sidekiq::PgHelpers::Middleware::ConnectionRecovery do
  let(:connection) { double(:connection,disconnect!: nil) }
  let(:connection_pool) { double(:connection_pool,remove: nil) }
  let(:logger) { double(:logger,warn: nil,error: nil) }
  let(:block) do
    lambda do
      next if @_times_called == 1
      @_times_called += 1
      raise exception
    end
  end

  before do
    @_times_called = 0

    ActiveRecord::Base.stub(connection: connection,connection_pool: connection_pool)
    ActiveRecord::Base.stub(:clear_active_connections!)
    Sidekiq.stub(logger: logger)
  end

  it "yields to a block" do
    expect { |b| subject.call(:worker_class,:msg,:queue,&b) }.to yield_control
  end

  context "with PG::ConnectionBad" do
    let(:exception) { PG::ConnectionBad.new("could not connect to server: Connection refused") }
    it_behaves_like "helpful middleware"
  end

  context "with PG::UnableToSend" do
    let(:exception) { PG::ConnectionBad.new("server closed the connection unexpectedly") }
    it_behaves_like "helpful middleware"
  end

  context "with ActiveRecord::StatementInvalid wrapping PG::ConnectionBad" do
    let(:exception) do
      ActiveRecord::StatementInvalid.new("ugh",PG::ConnectionBad.new)
    end
    it_behaves_like "helpful middleware"
  end

  context "with an unrecoverable problem" do
    let(:exception) { PG::ConnectionBad.new("server closed the connection unexpectedly") }

    let(:block) do
      lambda do
        @_times_called += 1
        next if @_times_called > 5 # prevent looping forever if the retry code breaks
        raise exception
      end
    end

    before do
      @_times_called = 0
    end

    it "gives up after 5 attempts" do
      subject.call(:worker_class,:msg,:queue,&block) rescue PG::ConnectionBad
      expect(@_times_called).to eq(5)
    end

    it "re-raises the exception after 5 attempts" do
      expect { subject.call(:worker_class,:msg,:queue,&block) }.to raise_error(exception)
    end
  end
end
