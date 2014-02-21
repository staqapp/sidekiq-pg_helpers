require "bundler/gem_tasks"

#http://erniemiller.org/2014/02/05/7-lines-every-gems-rakefile-should-have/
task :console do
  require "irb"
  require "irb/completion"
  require "sidekiq/pg_helpers"
  ARGV.clear
  IRB.start
end
