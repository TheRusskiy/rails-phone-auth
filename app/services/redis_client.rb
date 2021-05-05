class RedisClient
  class << self
    def instance
      @instance ||= Redis.new(url: 'redis://localhost:6379/1')
    end
  end
end
