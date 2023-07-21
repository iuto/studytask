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
        @tasks_today = Task.none
        @tasks_tomorrow = Task.none
    elsif params[:list].nil?
        @tasks_today = current_user.tasks.select(&:due_today?)
        @tasks_tomorrow = current_user.tasks.select(&:due_tomorrow?)
    else
        tasks = List.find(params[:list]).tasks.had_by(current_user)
        @tasks_today = tasks.select(&:due_today?)
        @tasks_tomorrow = tasks.select(&:due_tomorrow?)
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

  exclude_days = params['exclude_days'].map(&:to_i) if params['exclude_days']

  if start_date <= due_date
    next_date = start_date
    while next_date <= due_date do
      unless exclude_days&.include?(next_date.wday)
        current_user.tasks.create(title: params[:title], due_date: next_date, list_id: list.id)

        # 復習タスクの作成
        review_days = params[:after].to_i
        if review_days > 0
          review_date = next_date + review_days
          current_user.tasks.create(title: "#{params[:title]}（復習）", due_date: review_date, list_id: list.id)
        end
      end
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
    @lists = List.all
    @task_counts = {}
    if current_user
        (0..6).each do |wday|
            @task_counts[wday] = { '負荷A' => 0, '負荷B' => 0, '負荷C' => 0 }
            current_user.tasks.where(completed: true).each do |task| # 完了したタスクのみ取得
                if task.due_on?(wday)
                    list = List.find(task.list_id)
                    @task_counts[wday][list.name] += 1
                end
            end
        end
    end
    erb :highlight
end

get '/top' do
    erb :top
end

# 復習タスクの作成
def create_review_task(original_task, review_days)
  review_date = Date.today + review_days
  reviewed_task = original_task.dup
  reviewed_task.title = "#{original_task.title}（復習）"
  reviewed_task.due_date = review_date
  reviewed_task.save
end

get '/tasks/review' do
    @lists = List.all
    if current_user
        @tasks_review = current_user.tasks.where("due_date > ?", Date.today).where("due_date <= ?", Date.today + 1)
    else
        @tasks_review = Task.none
    end
    erb :review_tasks
end
