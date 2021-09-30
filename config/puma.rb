# encoding: UTF-8

threads_count = (ENV.fetch("RAILS_WORKER_THREADS") { 32 }).to_i
threads threads_count, threads_count

worker_count = (ENV.fetch("RAILS_WORKER_COUNT") { 4 }).to_i
workers worker_count

preload_app!
