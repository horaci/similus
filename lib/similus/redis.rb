module Similus
  def self.redis
    @redis ||= begin
      host, port = config.redis_server.split(':')
      ::Redis.new(:host => host, :port => port, :db => config.redis_db)
    rescue Exception => e
      config.logger.error "Error connecting redis server: #{e.message}"
      nil
    end
  end
  
  def self.clear_database!
    @cache = {}
    redis.flushdb
  end
end
