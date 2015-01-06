require 'sinatra'
#The environment variable DATABASE_URL should be in the following format:
# => postgres://{user}:{password}@{host}:{port}/path


# ActiveRecord::Base.establish_connection(
# 		:adapter => 'postgresql',
# 		:host     => '',
# 		:username => 'grant',
# 		:password => 'password',
# 		:database => 'bme_data',
# 		:encoding => 'utf8'
# )



configure :development do 
	ActiveRecord::Base.establish_connection(
		:adapter => 'postgresql',
		:host     => '',
		:username => 'grant',
		:password => 'password',
		:database => 'bme_data',
		:encoding => 'utf8'
	)
end

configure :production do 
	db = URI.parse(ENV['DATABASE_URL'] || 'postgres:///localhost/mydb')
	 
	 ActiveRecord::Base.establish_connection(
	   :adapter  => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
	   :host     => db.host,
	   :username => db.user,
	   :password => db.password,
	   :database => db.path[1..-1],
	   :encoding => 'utf8'
	 )
end