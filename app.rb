require 'sinatra/base'
require 'sinatra/activerecord'
require './config/environments'
require './models/models'
require 'gchart'
require 'csv'
require 'bcrypt'
require 'chartkick'
require 'google_visualr'
require 'pony'
require 'date'

load 'Gtable.rb'


class Public < Sinatra::Base

	set :root, File.dirname(__FILE__)

	enable :sessions
	set :session_secret, 'super secret'
	set :protection, :except => :frame_options

	get '/' do
		erb :index
	end


	post '/mail' do
		p params
		Pony.mail :to => 'grantnicholas2015@u.northwestern.edu',
				  :from => params[:email],
				  :subject => 'A message from a kinetikloud user',
				  :body => params[:comments],
				  :via => :smtp,
				  :via_options =>{
				  	:address => 'smtp.sendgrid.net',
				  	:port => 587,
				  	:enable_starttls_auto => true,
				  	:user_name => 'kinetikloud',
				  	:password =>'badhatharry69',
				  	:authentication => :plain,
				  	:domain => 'HELO'
				  }
		@error   = false
		@message = "Your email was sent successfully"
		erb :login
	end


	post '/upload_memo' do 
		thestring = request.body.read
		p thestring

		lookup = {}
		CSV.parse(thestring) do |row|
			key,val = row
			lookup[key] = val
		end
		p lookup

		if !Memo.exists?({
					category: lookup["name"],  
					date: lookup["date"]}) 
			m = Memo.new
			m.category = lookup["name"].downcase
			m.count = 0
			m.time = lookup["time"]
			m.date = DateTime.strptime(lookup["date"], '%m/%d/%Y')
			p m
			m.save
		end
	end


	get '/login' do 
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
		p @machine
		@dropdown = Memo.select('DISTINCT category')
		options = {showRowNumber: true }
		@table = helper_table([@machine], 'table_div', options)
		@time_table = bar_chart_machine(params[:name].downcase, 'time_bar')

		p @table 
		p @time_table 
		erb :data
	end


	get '/machines' do 
		# @images = helper_images
		@images = []
		@machine = "machines"
		@dropdown = Memo.select('DISTINCT category')
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

	def helper_table(cats, css_id, options)
		p "cats"
		p cats
		data= []
		if cats.length == 1
			cats.each do |cat|
				dat = Memo.all.where({category: cat}).order('time ASC')
				p 'datt'
				p dat
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
		# table.add_column('number', 'Count')
		table.add_column('number', 'Time in use [min]')
		table.set_cssid(css_id)
		table.options = options
		table.add_rows(data)

		return table
	end
		
	def format(memo)
		arr = [memo.category, memo.date.strftime("%m-%d-%Y"), (memo.time/60.0).round(2)]
		p arr
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

	def bar_chart_machine(category, t_id)
		# count_arr = []
		time_arr = []
		data = Memo.all.where({category: category}).order('date ASC')
		data.each do |d|
			# ctmp = [d.date, d.count]
			ttmp = [d.date.strftime("%m-%d-%Y"), (d.time/60.0).round(2)]
			# count_arr.push(ctmp)
			time_arr.push(ttmp)
		end

  		time_table = Gtable.new
		time_table.add_column('string', 'Date')
		time_table.add_column('number', 'Time in use[min]')
		time_table.set_cssid(t_id)
		time_table.add_rows(time_arr)
		time_table.add_options({
    		title: category,
    		hAxis: {title: 'Date', titleTextStyle: {color: 'red'}}
  		})


		return time_table


	end



end

