threads_count = (ENV.fetch('RAILS_WORKER_THREADS') { 32 }).to_i
threads threads_count, threads_count

worker_count = (ENV.fetch('RAILS_WORKER_COUNT') { 4 }).to_i
workers worker_count

# We need to prevent these threads from launching until after the fork if we are
# going to use preload_app (forking is dangerous)
# [1] ! #<Thread:0x00007f16f3e9f578 /app/config/initializers/cleanup_ttls.rb:4 sleep> - /app/config/initializers/cleanup_ttls.rb:8:in `sleep'
# [1] ! #<Thread:0x00007f16f18f2d70 /app/vendor/bundle/ruby/2.7.0/gems/rethinkdb-2.4.0.0/lib/net.rb:1025 sleep> - /app/vendor/bundle/ruby/2.7.0/gems/rethinkdb-2.4.0.0/lib/net.rb:1016:in `read'
# preload_app!
