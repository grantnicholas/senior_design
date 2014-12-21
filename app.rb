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

end

class Protected < Sinatra::Base

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
		# stuff = 0

		# @cats = Machine.select('DISTINCT category')
		# @cats.each do |t|
		# 	puts t.get_category
		# 	puts params[:name].downcase
		# 	if t.get_category.downcase==params[:name].downcase
		# 		stuff = Machine.all.where({category: t.get_category}).order("time ASC")
		# 	end
		# end

		# if stuff ==0
		# 	redirect '/machines'
		# else	
		# 	timedata = []
		# 	xdata = []
		# 	ydata = []
		# 	zdata = []
		# 	size = []
		# 	output = {}
		# 	outarr = []
		# 	stuff.each do |x|
		# 		timedata.push(x.time)
		# 		xdata.push(x.xdata)
		# 		ydata.push(x.ydata)
		# 		zdata.push(x.zdata)
		# 		size.push(2)
		# 		output[x.time] = x.zdata
		# 		arr = []
		# 		arr.push([x.time.to_f,x.zdata.to_f])
		# 		outarr.push(arr)
		# 	end


		# 	name = :name.to_s
			# filename = '/img/' + name + '.png'
			# mod_filename = 'public/' + filename

			# line_chart = Gchart.new(
		 #            :type => 'line_xy',
		 #            :size => '600x400',
		 #            # :line_colors => ['000000', '0088FF', 'FF0000'],
		 #            :title => "Treadmill usage",
		 #            :bg => 'EFEFEF',
		 #            # :legend => ['xdata', 'ydata', 'zdata'],
		 #            # :legend_position => 'bottom',
		 #            # :data => [[timedata,xdata], [timedata,ydata], [timedata, zdata] ],
		 #            :data => [timedata, zdata],
		 #            :filename => mod_filename,
		 #            :axis_with_labels => [['x'], ['y']]
		 #            )

			# line_chart.file

			# @count,@timetotal = process_data(get_vars(stuff))


			# @images  = [filename]

			@machine = params[:name]
			@dropdown = Machine.select('DISTINCT category')

  			@table = helper_table

  			@count_table, @time_table = bar_chart_machine(params[:name].downcase, 'count_bar', 'time_bar')

			erb :data
		# end
	end


	get '/machines' do 
		@table = helper_table
		@images = helper_images
		@machine = "machines"
		@dropdown = Machine.select('DISTINCT category')
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


	def helper_table 
		@data_arr = []
		cats = Machine.select('DISTINCT category')
		cats.each do |machine|
			name = machine.category
			dat = Machine.all.where({ category: name}).order('time ASC')
			count,time = process_data(get_vars(dat))
			tmp = [name, count, time]
			@data_arr.push(tmp)
		end

		@table = Gtable.new
		@table.add_column('string', 'Machine')
		@table.add_column('number', 'Count')
		@table.add_column('number', 'Time in use')
		@table.set_cssid('table_div')
		@table.add_rows(@data_arr)

		return @table
	end

	def helper_images
		@images = []
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

