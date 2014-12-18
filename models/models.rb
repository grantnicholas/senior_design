require 'bcrypt'

class Machine < ActiveRecord::Base
end

class Treadmill < Machine
end

class Nustep < Machine
end

class User < ActiveRecord::Base

	def check_password(pass)
		self.password ||= BCrypt::Password.create(pass)
	end

	def set_password(new_password)
		@password = BCrypt::Password.create(new_password)
		self.password = @password
	end
end