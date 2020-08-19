require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

def init_db
	@db = SQLite3::Database.new 'leprosorium.db'
	@db.results_as_hash = true
end


# before вызивается каждый раз при перезагрузке
# любой страницы
before do
	# инициализация БД
	init_db
end

# configure вызивается каждый раз при конфигурации приложения:
# когда изменился код програмы И перезагрузилась страница

configure do
 	# инициализация БД
	init_db

	# создает таблицу если она не существует
	@db.execute 'create table if not exists POSTS
	(
	      id INTEGER PRIMARY KEY AUTOINCREMENT, 
	      created_date DATE, 
	      content TEXT,
	      avtor TEXT
	 )'

	  #создает таблицу если она не существует
	@db.execute 'create table if not exists Comments
	(
	      id INTEGER PRIMARY KEY AUTOINCREMENT, 
	      created_date DATE, 
	      message TEXT,
	      post_id INTEGER
	 )'
end

get '/'  do
	#выбираем список постов из БД
	@results = @db.execute 'select * from Posts order by id desc'
	erb :index	

end

get '/new' do
	erb :new
end

post '/new' do
	# получаем переменную из post- запроса
	content = params[:content]
	avtor = params[:avtor]

	if content.length <= 0
		@error = 'Type post text'
		return erb :new
	end

	#Сохранение данных в БД
	@db.execute 'insert into Posts (content,created_date,avtor) values (?,datetime(),?)', [content,avtor]

	#перенаправление на главную страницу
	redirect to '/'
end

#вывод информации о посте
get '/details/:post_id' do
	#получаем переменную из url'a
	post_id = params[:post_id]

	#получаем список постов
	#(у нас будет только один пост)
	results = @db.execute 'select * from Posts where id = ?', [post_id]
	
	#выбираем этот один пост в переменную @row
	@row = results[0]

	#выбираем комментарии для нашего поста
	@comments = @db.execute 'select * from Comments where post_id = ? order by id',[post_id]

	erb :details
end

#обработчик post-запроса /details......
#(браузер отправляет данные на сервер,мы из принимаем)
post '/details/:post_id' do

	#получаем переменную из url'a
	post_id = params[:post_id]
	
	# получаем переменную из post- запроса
	message = params[:message]

	if message.length == ''
		@error = 'Введите комментарии'
		return erb :details
	end

	@db.execute 'insert into Comments
	(
		message,
		created_date,
		post_id
	) 
	values 
	(
		?,
		datetime(),
		?
		)',[message,post_id]

	# перенаправление на страницу поста
	redirect to ('/details/' + post_id)
end