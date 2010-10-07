module Similus
  def self.config
    @config ||= Config.new
    block_given? ? yield(@config) : @config
  end
  
  class Config
    attr_accessor :backend
    attr_accessor :redis_server
    attr_accessor :redis_db
    attr_accessor :logfile

    def initialize #:nodoc:
      self.backend      = :redis
      self.redis_server = "localhost:6379"
      self.redis_db     = 9
      self.logfile      = STDOUT
    end

    def logger
      @logger ||= Logger.new(logfile)
    end
  end
end
