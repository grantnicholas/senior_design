require 'sinatra/base'
require 'sinatra/activerecord'
require './config/environments'
require './models/models'
require 'gchart'
require 'csv'
require 'bcrypt'
require 'chartkick'
require 'google_visualr'
load 'Gtable.rb'


class Public < Sinatra::Base

	set :root, File.dirname(__FILE__)

	enable :sessions
	set :session_secret, 'super secret'

	get '/' do
		erb :index
	end

	get '/about' do 
		erb :about
	end

	get '/upload' do
		erb :upload
	end

	post '/upload' do
		#p params.inspect
		#p params
		thestring = request.body.read

		@model = Machine.new

		dacount    = 0
		dacategory = nil
		dadate     = nil
		CSV.parse(thestring) do |row|
			if dacount ==0
				dacategory = row[0].downcase
				dadate     = row[1]
				dacount +=1
			elsif !row.empty?
				@model = Machine.new
				@model.category = dacategory.downcase
				@model.date     = dadate
				@model.time  = row[0]/1000
				@model.xdata = row[1]
				@model.ydata = row[2]
				@model.zdata = row[3]
				@model.save 
				p 'data start'
				p row[0]
				p row[1]
				p row[2]
				p row[3]
				p 'data end'
			end
		end
		puts dacategory
		puts dadate

		stuff = Machine.all.where({category: dacategory.downcase, date: dadate}).order("time ASC")

		stuff.each do |s|
			p s
		end
		if stuff == nil
			redirect '/process'
		end

		thecount,thetime = process_data(get_vars(stuff))

		if !Memo.exists?({category: dacategory, date: dadate }) 
			m = Memo.new
			m.category = dacategory
			m.count = thecount
			m.time = thetime
			m.date = dadate
			m.save
		end


		erb :upload
	end

	get '/login' do 
		# erb :login, :layout => :login_layout
		if session[:user]
			redirect '/logout'
		else	
			@error   = false
			@message = "Please login or register"
			erb :login
		end
	end

	post '/register' do 
		@user = User.new
		puts params[:email]
		puts params[:password]

		@user.email = params[:email]
		@user.set_password(params[:password])
		if @user.save
			puts "worked"
			@message = "Account created: please login"
			@error = false 
			erb :login
		else
			puts "fuck didnt work"
			@message = "Unsuccessful account creation: try again"
			@error = true
			erb :login
		end

	end

	post '/login' do 
		@user = User.find_by_email(params[:email])
		if !@user
			@error = true
			@message = "Incorrect username"
			erb :login

		elsif @user.check_password(params[:password])
			session[:user] = params[:email]
			redirect '/machines'
		else
			@error = true
			@message = "Incorrect login information"
			erb :login
		end

	end


	def mean(x)
		sum = 0.0
		x.each do |v|
			sum += v
		end

		sum = sum/x.size
		return sum
	end

	def stdev(x)
		m = mean(x)
		sum = 0.0
		x.each do |v|
			sum+= (v-m)**2
		end
		return Math.sqrt(sum/x.size)
	end

	def get_vars(stuff)
		timedata = []
		zdata = []
		stuff.each do |x|
			timedata.push(x.time)
			zdata.push(x.zdata)
		end
		return timedata,zdata
	end

		
	def process_data(stuff)

		t,z = stuff
		z_cut_up = mean(z) + stdev(z)
		z_cut_down = mean(z) - stdev(z)


		time_total =0
		time_start =0
		i_start    =1
		i_recent   =1
		time_recent =0
		time_cut   = 5 #5000 in ms
		top_cut    =z_cut_up
		bot_cut    =z_cut_down
		count = 0;

		(0...z.size).each do |i|
		    if (z[i]> top_cut || z[i] < bot_cut) 
		        if t[i] - time_recent> time_cut
		            if time_recent - time_start > time_cut #%time_cut
		                count = count+1
		            end
		            time_total = time_total + (time_recent-time_start);
		            time_start =t[i]
		            i_start    =i
		            time_recent =t[i]
		        else
		            time_recent = t[i]
		            i_recent    = i
		        end
		    end
		end

		count = count+1
		if time_recent != 0
			time_total = time_total + (time_recent-time_start)
		end


		return count, time_total

	end

	def helper_table(cats, css_id, options)
		data= []
		if cats.length == 1
			cats.each do |cat|
				dat = Memo.all.where({category: cat}).order('time ASC')
				dat.each do |d|
					data.push(format(d))
				end
			end
		else
			cats.each do |cat|
				dat = Memo.all.where({category: cat}).order('date DESC').first
				data.push(format(dat))
			end
		end

		table = Gtable.new
		table.add_column('string', 'Machine')
		table.add_column('string', 'Date')
		table.add_column('number', 'Count')
		table.add_column('number', 'Time in use')
		table.set_cssid(css_id)
		table.options = options
		table.add_rows(data)

		return table
	end
		
	def format(memo)
		arr = [memo.category, memo.date, memo.count, memo.time]
		return arr
	end	

	def helper_images
		@images = []

		#REGEX MAGIC: remove the public portion of the filename as sinatra
		#automagically looks in /public for static files
		Dir.glob('public/img/machines/*.jpg') do |file|
			re = /public\/(\S+)/
			match = file.match(re)
 	 		@images.push(match[1])
		end
		return @images
	end

	def bar_chart_machine(category, c_id, t_id)
		count_arr = []
		time_arr = []
		data = Memo.all.where({category: category}).order('date ASC')
		data.each do |d|
			ctmp = [d.date, d.count]
			ttmp = [d.date, d.time]
			count_arr.push(ctmp)
			time_arr.push(ttmp)
		end

		count_table = Gtable.new
		count_table.add_column('string', 'Date')
		count_table.add_column('number', 'Count')
		count_table.set_cssid(c_id)
		count_table.add_rows(count_arr)
		count_table.add_options({
    		title: category,
    		hAxis: {title: 'Date', titleTextStyle: {color: 'red'}}
  		})

  		time_table = Gtable.new
		time_table.add_column('string', 'Date')
		time_table.add_column('number', 'Time')
		time_table.set_cssid(t_id)
		time_table.add_rows(time_arr)
		time_table.add_options({
    		title: category,
    		hAxis: {title: 'Date', titleTextStyle: {color: 'red'}}
  		})


		return count_table, time_table


	end


end

class Protected < Sinatra::Base

	helpers do 
		def table_chart(table)
			@table = table
			erb(:_gtable, :layout => false)
		end

		def bar_chart(table)
			@table = table
			erb(:_gbar, :layout => false)
		end
	end

	set :root, File.dirname(__FILE__)

	use Public

	before do 
		unless session[:user]
			@error = true
			@message = "Access denied: please login"
			halt erb :login
		end
	end


	get '/logout' do 
		session[:user] = nil
		@error = false
		@message = "You have been successfully logged out"
		erb :login
	end

	get '/machines/:name' do 
		@machine = params[:name]
		@dropdown = Machine.select('DISTINCT category')
		options = {showRowNumber: true }
		@table = helper_table([@machine], 'table_div', options)
		@count_table, @time_table = bar_chart_machine(params[:name].downcase, 'count_bar', 'time_bar')

		erb :data
	end


	get '/machines' do 
		@images = helper_images
		@machine = "machines"
		@dropdown = Machine.select('DISTINCT category')
		cats = []
		@dropdown.each do |m|
			cats.push(m.category)
		end
		options = {showRowNumber: true }
		@table = helper_table(cats, 'table_div', options)
		erb :data
	end


	get '/test' do 
		erb :test
	end


	get '/models' do
		@models = Model.all 
		erb :models
	end

	post '/process' do 
		CSV.foreach(params[:file][:tempfile]) do |row|
			if !row.empty? 
				@model = Machine.new
				@model.category  = params[:model][:category]
				@model.time  = row[0]
				@model.xdata = row[1]
				@model.ydata = row[2]
				@model.zdata = row[3]
				@model.date  = params[:model][:date]
				@model.save
			end
		end

		stuff = 0
		category = 0
		@cats = Machine.select('DISTINCT category')
		@cats.each do |t|
			puts t.get_category
			puts params[:model][:category].downcase
			if t.get_category.downcase==params[:model][:category].downcase
				category = t.get_category
				stuff = Machine.all.where({category: t.get_category, date: params[:model][:date]}).order("time ASC")
			end
		end

		stuff.each do |s|
			p s
		end
		if stuff == 0
			redirect '/process'
		end

		thecount,thetime = process_data(get_vars(stuff))

		if !Memo.exists?({category: category, date: params[:model][:date] }) 
			m = Memo.new
			m.category = category
			m.count = thecount
			m.time = thetime
			m.date = params[:model][:date]
			m.save
		end
		# Memo.create({type: type, count: thecount, time: thetime, date: params[:model][:date]})

		# Memo.where({type: type}).update_all("count = count + #{thecount}" )
		# Memo.where({type: type}).update_all("time = time + #{thetime}" )



	end


	def mean(x)
		sum = 0.0
		x.each do |v|
			sum += v
		end

		sum = sum/x.size
		return sum
	end

	def stdev(x)
		m = mean(x)
		sum = 0.0
		x.each do |v|
			sum+= (v-m)**2
		end
		return Math.sqrt(sum/x.size)
	end

	def get_vars(stuff)
		timedata = []
		zdata = []
		stuff.each do |x|
			timedata.push(x.time)
			zdata.push(x.zdata)
		end
		return timedata,zdata
	end

		
	def process_data(stuff)

		t,z = stuff
		z_cut_up = mean(z) + stdev(z)
		z_cut_down = mean(z) - stdev(z)


		time_total =0
		time_start =0
		i_start    =1
		i_recent   =1
		time_recent =0
		time_cut   = 5
		top_cut    =z_cut_up
		bot_cut    =z_cut_down
		count = 0;

		(0...z.size).each do |i|
		    if (z[i]> top_cut || z[i] < bot_cut) 
		        if t[i] - time_recent> time_cut
		            if time_recent - time_start > time_cut #%time_cut
		                count = count+1
		            end
		            time_total = time_total + (time_recent-time_start);
		            time_start =t[i]
		            i_start    =i
		            time_recent =t[i]
		        else
		            time_recent = t[i]
		            i_recent    = i
		        end
		    end
		end

		count = count+1
		if time_recent != 0
			time_total = time_total + (time_recent-time_start)
		end


		return count, time_total

	end

	def helper_table(cats, css_id, options)
		data= []
		if cats.length == 1
			cats.each do |cat|
				dat = Memo.all.where({category: cat}).order('time ASC')
				dat.each do |d|
					data.push(format(d))
				end
			end
		else
			cats.each do |cat|
				dat = Memo.all.where({category: cat}).order('date DESC').first
				data.push(format(dat))
			end
		end

		table = Gtable.new
		table.add_column('string', 'Machine')
		table.add_column('string', 'Date')
		table.add_column('number', 'Count')
		table.add_column('number', 'Time in use')
		table.set_cssid(css_id)
		table.options = options
		table.add_rows(data)

		return table
	end
		
	def format(memo)
		arr = [memo.category, memo.date, memo.count, memo.time]
		return arr
	end	

	def helper_images
		@images = []

		#REGEX MAGIC: remove the public portion of the filename as sinatra
		#automagically looks in /public for static files
		Dir.glob('public/img/machines/*.jpg') do |file|
			re = /public\/(\S+)/
			match = file.match(re)
 	 		@images.push(match[1])
		end
		return @images
	end

	def bar_chart_machine(category, c_id, t_id)
		count_arr = []
		time_arr = []
		data = Memo.all.where({category: category}).order('date ASC')
		data.each do |d|
			ctmp = [d.date, d.count]
			ttmp = [d.date, d.time]
			count_arr.push(ctmp)
			time_arr.push(ttmp)
		end

		count_table = Gtable.new
		count_table.add_column('string', 'Date')
		count_table.add_column('number', 'Count')
		count_table.set_cssid(c_id)
		count_table.add_rows(count_arr)
		count_table.add_options({
    		title: category,
    		hAxis: {title: 'Date', titleTextStyle: {color: 'red'}}
  		})

  		time_table = Gtable.new
		time_table.add_column('string', 'Date')
		time_table.add_column('number', 'Time')
		time_table.set_cssid(t_id)
		time_table.add_rows(time_arr)
		time_table.add_options({
    		title: category,
    		hAxis: {title: 'Date', titleTextStyle: {color: 'red'}}
  		})


		return count_table, time_table


	end



end

