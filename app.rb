require 'sinatra'
require 'sinatra/activerecord'
require './config/environments'
require './models/machine'
require 'gchart'
require 'csv'

enable :sessions

get '/' do
	erb :index
end


get '/machines/:name' do 
	stuff = 0
	if params[:name] == "treadmill"
		stuff = Treadmill.all.order("time ASC")
	end
	if params[:name] == "nustep"
		stuff = Nustep.all.order("time ASC")
	end

	if stuff ==0
		redirect '/instruments'
	else	
		timedata = []
		xdata = []
		ydata = []
		zdata = []
		stuff.each do |x|
			timedata.push(x.time)
			xdata.push(x.xdata)
			ydata.push(x.ydata)
			zdata.push(x.zdata)
		end

		name = :name.to_s
		filename = '/img/' + name + '.png'
		mod_filename = 'public/' + filename

		line_chart = Gchart.new(
	            :type => 'line',
	            :size => '600x400',
	            :line_colors => ['000000', '0088FF', 'FF0000'],
	            :title => "Treadmill usage",
	            :bg => 'EFEFEF',
	            :legend => ['xdata', 'ydata', 'zdata'],
	            :legend_position => 'bottom',
	            :data => [timedata, xdata, ydata, zdata],
	            :filename => mod_filename,
	            :axis_with_labels => [['x'], ['y']]
	            )

		line_chart.file

		@count,@timetotal = process_data(get_vars(stuff))
		@images  = [filename]

		@machine = params[:name]
		@dropdown = Machine.select('DISTINCT type')

		erb :data
	end
end

get '/machines' do 
	@machine = "machine"
	@images  = ['img/line_chart.png', 'img/line_chart.png']
	@dropdown = Machine.select('DISTINCT type')
	erb :data
end

get '/login' do 
	# erb :login, :layout => :login_layout
	erb :login
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
			puts row.inspect
			if params[:model][:type] == "treadmill"
				@model = Treadmill.new
				@model.time  = row[0]
				@model.xdata = row[1]
				@model.ydata = row[2]
				@model.zdata = row[3]
				@model.save
			end

			if params[:model][:type] == "nustep"
				@model = Nustep.new
				@model.time  = row[0]
				@model.xdata = row[1]
				@model.ydata = row[2]
				@model.zdata = row[3]
				@model.save
			end

		end
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
	z_cut_up = stdev(z)
	z_cut_down = -z_cut_up


	time_total =0;
	time_start =0;
	i_start    =1;
	i_recent   =1;
	time_recent =0;
	time_cut   =3;
	top_cut    =z_cut_up
	bot_cut    =z_cut_down;
	count = 0;

	(0...z.size).each do |i|
	    if (z[i]> top_cut or z[i] < bot_cut) 
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
	time_total = time_total + (time_recent-time_start);

	return count, time_total

end

