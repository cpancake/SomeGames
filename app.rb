require 'sinatra'
require 'sinatra/reloader' if development?
require 'net/http'
require 'swf_file'
require 'oj'

require_relative 'nicebytes'
require_relative 'to_slug'
require_relative 'download'
require_relative 'models'
require_relative 'sites/init'

config = Oj.load(File.open('config.json').read)

Dir.mkdir('./public/files/games') unless File.exists?('./public/files/games')
Dir.mkdir('./public/files/images') unless File.exists?('./public/files/images')

enable :sessions

def get_file_contents(url)
	return Net::HTTP.get_response(URI.parse(url)).body
end

def sanitize_filename(filename)
   return filename.gsub(/^.*(\\|\/)/, '').gsub(/[^0-9A-Za-z.\-]/, '_')
end

get '/' do
	@count = 0
	@items = Array.new
	DB[:items].where(:flash => true).each do |i|
		item = Hash.new
		item[:name] = i[:name]
		item[:thumb] = i[:thumb_file]
		item[:slug] = i[:slug]
		@items.push item
	end
	@items.reverse!
	erb :index
end

get '/apps' do
	@count = 0
	@items = Array.new
	DB[:items].where(:flash => false).each do |i|
		item = Hash.new
		item[:name] = i[:name]
		item[:thumb] = i[:thumb_file]
		item[:slug] = i[:slug]
		@items.push item
	end
	@items.reverse!
	erb :index
end

get '/game/:slug' do
	slug = params[:slug]
	game = DB[:items].where(:slug => slug).first
	if not game then
		erb :notfound
	else
		@name = game[:name]
		@file = game[:flash_file]
		@width = game[:width]
		@height = game[:height]
		@flash = game[:flash]
		@slug = game[:slug]
		@thumb = game[:thumb_file]
		@size = NiceBytes.nice_bytes(File.size('./public/files/games/' + @file)) if not @flash
		erb :game
	end
end

get '/game/:slug/admin' do
	slug = params[:slug]
	game = DB[:items].where(:slug => slug).first
	if not game then
		return erb :notfound
	end
	@nomenu = true
	redirect '/admin' if not session[:admin]
	@name = game[:name]
	@thumb = game[:thumb_file]
	@file = game[:flash_file]
	@type = game[:type]
	@slug = game[:slug]
	erb :'admin/edit'
end

post '/game/:slug/admin' do
	slug = params[:slug]
	game = DB[:items].where(:slug => slug).first
	if not game then
		return erb :notfound
	end
	@nomenu = true
	redirect '/admin' if not session[:admin]
	DB[:items].where(:slug => slug).update(:name => params[:name], :flash_file => params[:file], :thumb_file => params[:thumb], :flash => params[:type] == "flash")
	redirect '/game/' + slug
end

get '/game/:slug/admin/delete' do
	slug = params[:slug]
	game = DB[:items].where(:slug => slug).first
	if not game then
		return erb :notfound
	end
	@nomenu = true
	redirect '/admin' if not session[:admin]
	DB[:items].where(:slug => slug).delete
	redirect '/'
end

get '/download/:slug' do
	slug = params[:slug]
	game = DB[:items].where(:slug => slug).first
	if not game then
		erb :notfound
	else
		file = game[:flash_file]
		send_file('./public/files/games/' + file, :disposition => 'attachment', :filename => sanitize_filename(game[:name]) + File.extname(file))
	end
end

get '/admin' do
	@nomenu = true
	if not session[:admin] then
		erb :'admin/login'
	else
		redirect '/admin/add'
	end
end

post '/admin' do
	@nomenu = true
	username = params[:username]
	password = params[:password]
	if username and password and username == config["admin"]["username"] and password == config["admin"]["password"] then
		session[:admin] = true
		redirect '/admin/add'
	else
		@error = true
		erb :'admin/login'
	end
end

get '/admin/logout' do
	session[:admin] = nil
	redirect '/admin'
end

get '/admin/add' do
	@nomenu = true
	redirect '/admin' if not session[:admin]
	erb :'admin/add_file'
end

post '/admin/add' do
	@nomenu = true
	redirect '/admin' if not session[:admin]
	@errors = Array.new
	name = params[:name]
	file = params[:file]
	thumb = params[:thumb]
	flash = params[:type] == "flash"
	@errors.push "One or more fields are missing!" if not name or not file or not thumb
	@errors.push "File doesn't exist!" if file and not File.exists? "./public/files/games/" + file
	@errors.push "Thumb doesn't exist!" if thumb and not File.exists? "./public/files/images/" + thumb
	if @errors.length > 0 then
		erb :'admin/add_file'
	else
		if flash then
			header = SwfFile::FlashFile.header("./public/files/games/" + file)
			width = header.width
			height = header.height
		else
			width = height = 0
		end
		slug = name.to_slug
		DB[:items].insert(:name => name, :slug => slug, :flash_file => file, :thumb_file => thumb, :flash => flash, :width => width, :height => height)
		redirect '/game/' + slug
	end
end

get '/admin/add/url' do
	@nomenu = true
	redirect '/admin' if not session[:admin]
	erb :'admin/add_url'
end

post '/admin/add/url' do
	@nomenu = true
	redirect '/admin' if not session[:admin]
	@errors = Array.new
	url = params[:url]
	name = nil
	file = nil
	thumb = nil
	if not url or url.empty? then
		@errors.push "No URL provided!"
	else
		Sites.each do |s|
			if s.regex.match(url) then
				name = s.get_file_name(url)
				file_url = s.get_file_url(url)
				thumb_url = s.get_thumb_url(url)
				file_name = (Digest::MD5.hexdigest file_url) + File.extname(file_url)
				thumb_name = (Digest::MD5.hexdigest thumb_url) + File.extname(thumb_url)
				Downloader.download_file file_url, './public/files/games/' + file_name
				Downloader.download_file thumb_url, './public/files/images/' + thumb_name
				file = file_name
				thumb = thumb_name
				break
			end
		end
	end
	@errors.push "One or more details about this file could not be determined!" if not name or not file or not thumb 
	if @errors.length > 0 then
		erb :'admin/add_url'
	else
		@name = name
		@file = file
		@thumb = thumb
		erb :'admin/add_file'
	end
end