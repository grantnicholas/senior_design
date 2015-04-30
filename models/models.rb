require 'bcrypt'

class Machine < ActiveRecord::Base
	def get_category
		return category
	end
end

# class Treadmill < Machine
# end

# class Nustep < Machine
# end

class User < ActiveRecord::Base


    def check_password(str)
      if BCrypt::Password.new(self.password) == str 
      	return true
      else
      	return false
      end
    end

	def set_password(new_password)
      self.password = BCrypt::Password.create(new_password)
    end

end

class Memo < ActiveRecord::Base
end