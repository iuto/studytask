require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?

require 'sinatra/activerecord'
require './models'

enable :sessions

helpers do
    def current_user
        User.find_by(id: session[:user])
    end
end

before '/tasks' do
    if current_user.nil?
        redirect '/'
    end
end

get '/' do
    erb :top
end

get '/index' do
    @lists = List.all
    if current_user.nil?
        @tasks = Task.none
    elsif params[:list].nil? then
        @tasks = current_user.tasks
    else
        @tasks = List.find(params[:list]).tasks.had_by(current_user)
    end
    erb :index
end

get '/signup' do
    erb :sign_up
end

post '/signup' do
    user = User.create(
        name: params[:name],
        password: params[:password],
        password_confirmation: params[:password_confirmation]
    )
    if user.persisted?
        session[:user] = user.id
    end
    redirect '/index'
end

get '/signin' do
    erb :sign_in
end

post '/signin' do
    user = User.find_by(name: params[:name])
    if user && user.authenticate(params[:password])
        session[:user] = user.id
    end
    redirect '/index'
end

get '/signout' do
    session[:user] = nil
    redirect '/'
end

get '/tasks/new' do
    erb :new
end

post '/tasks' do
  start_date = Date.parse(params[:start_date])
  due_date = Date.parse(params[:due_date])
  list = List.find(params[:list])

  if start_date <= due_date
    next_date = start_date
    while next_date <= due_date do
      current_user.tasks.create(title: params[:title], due_date: next_date, list_id: list.id)
      next_date = next_date.next_day
    end
    redirect '/index'
  else
    redirect '/tasks/new'
  end
end


post '/tasks/:id/done' do
    task = Task.find(params[:id])
    task.completed = true
    task.save
    redirect '/index'
end

post '/tasks/:id/delete' do
    task = Task.find(params[:id])
    task.destroy
    redirect '/index'
end

get '/tasks/over' do
    @lists = List.all
    @tasks = current_user.tasks.due_over
    erb :index
end

get '/tasks/done' do
    @lists = List.all
    @tasks = current_user.tasks.where(completed: true)
    erb :index
end

get '/list' do
    erb :index
end

get '/highlight' do
  erb :highlight
end

get '/highlight' do
  erb :index
end

get '/top' do
    erb :top
end
