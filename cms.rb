require 'sinatra'
require 'tilt/erubis'
require 'redcarpet'

if development?
  require 'pry'
  require 'sinatra/reloader'
end

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

ROOT = File.expand_path('..', __FILE__)

def data_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('../test/data', __FILE__)
  else
    File.expand_path('../data', __FILE__)
  end
end

def file_path(file_name)
  File.join(data_path, file_name)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when '.md'
    render_markdown content
  when '.txt'
    headers['Content-Type'] = 'text/plain'
    content
  end
end

def error_for_new_file(file_name)
  unless(1..100).cover? file_name
    'File name must be between 1 and 100 characters'
  end

  nil
end

def data_files
  @files = Dir.entries(data_path)
  @files.select! { |file| !File.directory? file }
  @files.sort!
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text).prepend('<body>').concat('</body>')
end

get '/' do
  @files = data_files

  erb :index
end

get '/new' do
  erb :new
end

get '/:file_name' do
  file_name = params[:file_name]

  if File.exist? file_path(file_name)
    return load_file_content(file_path(file_name))
  else
    session[:message] = "#{file_name} does not exist."

    redirect '/'
  end
end

get '/:file_name/edit' do
  @file_name = params[:file_name]
  @file_content = File.read(file_path(@file_name))

  erb :edit
end

post '/:file_name' do
  file_name = params[:file_name]
  File.write(file_path(file_name), params[:content])
  session[:message] = "#{file_name} has been updated."

  redirect '/'
end

post '/' do
  file_name = params[:file_name]

  error = error_for_new_file(file_name)
  if error
    session[:message] = error
    redirect '/new'
  else
    file = File.new(file_path(file_name), 'w')
    file.close
    session[:message] = "#{file_name} was created."

    redirect '/'
  end
end