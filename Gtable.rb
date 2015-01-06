class Gtable

	attr_accessor :columns
	attr_accessor :rows
	attr_accessor :id
	attr_accessor :show_num
	attr_accessor :options

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

end