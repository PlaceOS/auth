# encoding: UTF-8

# This removes any database entries that have a ttl column and have expired
Thread.new do
  past = 30.years.ago.to_i

  loop do
    sleep 10.minutes.to_i
    begin
      expired = 10.minutes.ago.to_i

      NoBrainer.run(:db => 'rethinkdb') { |r|
        r.table('table_config').filter { |sys| sys["indexes"].contains('ttl') }
      }.map { |table| table['name'] }.each do |table|
        NoBrainer.run { |r|
          r.table(table).between(past, expired, index: 'ttl').delete
        }
      end
    rescue => error
      puts "error clearing expired ttl: #{error.message}"
    end
  end
end
