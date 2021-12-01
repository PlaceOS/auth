# This removes any database entries that have a ttl column and have expired
Thread.new do
  past = 30.years.ago.to_i

  loop do
    sleep 10.minutes.to_i
    begin
      expired = 10.minutes.ago.to_i

      NoBrainer.run(db: 'rethinkdb') do |r|
        r.table('table_config').filter { |sys| sys['indexes'].contains('ttl') }
      end.map { |table| table['name'] }.each do |table|
        NoBrainer.run do |r|
          r.table(table).between(past, expired, index: 'ttl').delete
        end
      end
    rescue StandardError => e
      puts "error clearing expired ttl: #{e.message}"
    end
  end
end
