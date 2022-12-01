require 'socket'
require 'digest/md5'

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  class Retry < RuntimeError; end

  BASE_TABLE = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".freeze

  TIME_OFFSET = Time.utc(2014, 01, 01).to_i

  # 30 bits timestamp with 1s resolution -> We overflow in year 2048. Good enough.
  # Math.log(Time.parse('2048-01-01').to_f - TIME_OFFSET)/Math.log(2) = 29.999
  TIMESTAMP_BITS = 30

  # 14 bits of sequence number. max 16k values per 1s slices.
  # We want something >10k because we want to be able to do high speed inserts
  # on a single process for future benchmarks.
  SEQUENCE_BITS = 14

  # 24 bits of machine id
  # 0.1% of chance to have a collision with 183 servers:
  # Math.sqrt(-2*(2**24)*Math.log(0.999)) = 183.2
  # 1% of chance to have a collision with ~580 servers.
  # When using more than 500 machines, it's therefore a good
  # idea to set the machine_id manually to avoid collisions.
  # XXX This is referenced in nobrainer/config.rb#default_machine_id
  MACHINE_ID_BITS = 24

  # 15 bits for the current pid. We wouldn't need it if the sequence number was
  # on a piece of shared memory :)
  PID_BITS = 15

  # Total: 83 bits
  # With 14 digits in [A-Za-z0-9], we can represent 83 bits:
  # Math.log(62**14)/Math.log(2) = 83.35
  ID_STR_LENGTH = 14

  TIMESTAMP_MASK  = (1 <<  TIMESTAMP_BITS)-1
  SEQUENCE_MASK   = (1 <<   SEQUENCE_BITS)-1
  MACHINE_ID_MASK = (1 << MACHINE_ID_BITS)-1
  PID_MASK        = (1 <<        PID_BITS)-1

  PID_SHIFT        = 0
  MACHINE_ID_SHIFT = PID_SHIFT + PID_BITS
  SEQUENCE_SHIFT   = MACHINE_ID_SHIFT + MACHINE_ID_BITS
  TIMESTAMP_SHIFT  = SEQUENCE_SHIFT + SEQUENCE_BITS

  def self._default_machine_id
    return ENV['MACHINE_ID'] if ENV['MACHINE_ID']

    host = Socket.gethostname
    if host.in? %w(127.0.0.1 localhost)
      raise "Please configure ENV['MACHINE_ID'] due to lack of appropriate hostname (Socket.gethostname = #{host})"
    end

    Digest::MD5.digest(host).unpack("N")[0] & MACHINE_ID_MASK
  end

  @@machine_id = _default_machine_id
  @@last_timestamp = 0
  @@sequence = @@first_sequence = rand(SEQUENCE_MASK/2)

  def self._generate
    timestamp = (Time.now.to_i - TIME_OFFSET) & TIMESTAMP_MASK

    unless @@last_timestamp == timestamp
      # more noise is better in the ID, but we prefer to avoid
      # wrapping the sequences so that Model.last on a single
      # machine returns the latest created document.
      @@first_sequence = sequence = rand(SEQUENCE_MASK/2)
      @@last_timestamp = timestamp
    else
      sequence = (@@sequence + 1) & SEQUENCE_MASK
      raise Retry if @@first_sequence == sequence
    end
    @@sequence = sequence

    pid = Process.pid & PID_MASK

    (timestamp << TIMESTAMP_SHIFT) | (sequence << SEQUENCE_SHIFT) |
      (@@machine_id << MACHINE_ID_SHIFT) | (pid << PID_SHIFT)
  rescue Retry
    sleep 0.1
    retry
  end

  def self.convert_to_alphanum(id)
    result = []
    until id.zero?
      id, r = id.divmod(BASE_TABLE.size)
      result << BASE_TABLE[r]
    end
    result.reverse.join.rjust(ID_STR_LENGTH, BASE_TABLE[0])
  end

  @@lock = Mutex.new
  def self.generate
    convert_to_alphanum(@@lock.synchronize { _generate })
  end

  before_create :generate_id
  def generate_id
    self.id = "#{self.class.table_name}-#{self.class.generate}"
  end
end
