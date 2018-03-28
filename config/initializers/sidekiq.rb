if Rails.env.production?
	Sidekiq.configure_server do |config|
  		config.redis = { url: 'redis://192.168.1.7:6379' }
	end

	Sidekiq.configure_client do |config|
  		config.redis = { url: 'redis://192.168.1.7:6379' }
	end
end

# Sidekiq.options.merge!({
#   fetch: DynamicFetch
# })