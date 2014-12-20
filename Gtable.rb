class Gtable
	def initialize()	
		@columns = []
		@rows    = []
		@id      = []
		@show_num  =true
		@options = nil 
	end

	def add_column(type,name)
		arr = [type,name]
		@columns.push(arr)
	end

	def add_rows(arr)
		@rows = arr
	end

	def set_cssid(id)
		@id = id
	end

	def show_rownum(bool)
		@show_num = bool
	end

	def add_options(ops)
		@options = ops
	end

	def columns
		return @columns
	end

	def rows
		return @rows
	end

	def id
		return @id
	end

	def show_num
		return @show_num
	end

	def options
		return @options
	end

end