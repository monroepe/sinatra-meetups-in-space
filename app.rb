require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/flash'
require 'omniauth-github'

require_relative 'config/application'

Dir['app/**/*.rb'].each { |file| require_relative file }

helpers do
  def current_user
    user_id = session[:user_id]
    @current_user ||= User.find(user_id) if user_id.present?
  end

  def signed_in?
    current_user.present?
  end
end

  def set_current_user(user)
    session[:user_id] = user.id
  end

  def authenticate!
    unless signed_in?
      flash[:notice] = 'You need to sign in if you want to do that!'
      redirect '/'
    end
  end

  def field_empty?(field)
    field == ''
  end

  def valid_form?(name, description, location)
    if field_empty?(name)
      flash.now[:notice] = 'Name cannot be empty'
      false
    elsif field_empty?(description)
      flash.now[:notice] = 'Description cannot be empty'
      false
    elsif field_empty?(location)
      flash.now[:notice] = 'Location cannot be empty'
      false
    end
  end

  def already_member?(user_id, meetup_id)
    Membership.where(user_id: user_id, meetup_id: meetup_id).exists?
  end

get '/' do
  @meetups = Meetup.all.order(:name)
  erb :index
end

get '/auth/github/callback' do
  auth = env['omniauth.auth']

  user = User.find_or_create_from_omniauth(auth)
  set_current_user(user)
  flash[:notice] = "You're now signed in as #{user.username}!"

  redirect '/'
end

get '/sign_out' do
  session[:user_id] = nil
  flash[:notice] = "You have been signed out."

  redirect '/'
end

get '/example_protected_page' do
  authenticate!
end

get '/meetups/:id' do
  @meetup = Meetup.find(params[:id])
  @members = Membership.where('meetup_id = ?', params[:id])
  if signed_in?
    @already_member = already_member?(current_user.id, @meetup.id)
  end

  erb :'meetups/show'
end

get '/add' do
  authenticate!
  erb :'meetups/add'
end

post '/add' do
  @name = params[:name]
  @description = params[:description]
  @location = params[:location]

  if !valid_form?(@name, @description, @location)
    erb :'meetups/add'
  else

    if !Meetup.exists?(name: @name, description: @description, location: @location)
      flash[:notice] = "You have created a new meetup."
    end

    meetup = Meetup.find_or_create_by(name: @name, description: @description, location: @location)
    redirect "/meetups/#{meetup.id}"
  end

end

post '/join' do
  @fields = {user_id: params[:user_id], meetup_id: params[:meetup_id], role: params[:role]}
  Membership.find_or_create_by(@fields)
  flash[:notice] = "You have joined the meetup."
  redirect "/meetups/#{@fields[:meetup_id]}"
end

post '/leave' do
  authenticate!
  @fields = {user_id: params[:user_id], meetup_id: params[:meetup_id], role: params[:role]}
  Membership.where(@fields).destroy_all
  flash[:notice] = "You have left the meetup."
  redirect "/meetups/#{@fields[:meetup_id]}"
end
