require 'webrick'
require 'erb'
require 'dbi'

config = {
	:Port => 8099,
	:DocumentRoot => '.',
}

WEBrick::HTTPServlet::FileHandler.add_handler("erb", WEBrick::HTTPServlet::ERBHandler)

server = WEBrick::HTTPServer.new(config)

server.config[:MimeTypes]["erb"] = "text/html"

server.mount_proc("/list") { |req, res|
	if /(.*)\.(delete|edit)$/ =~ req.query['operation']
		target_id = $1
		operation = $2
		if operation == 'delete'
			template = ERB.new(File.read('delete.erb'))
		elsif operation == 'edit'
			template = ERB.new(File.read('edit.erb'))
		end
		res.body << template.result(binding)
	else
		template = ERB.new(File.read('noselected.erb'))
		res.body << template.result(binding)
	end
}

server.mount_proc("/entry") { |req, res|

	p req.query
	dbh = DBI.connect('DBI:SQLite3:bookinfo_sqlite.db')

	rows = dbh.select_one("select * from bookinfos where id='#{req.query['id']}';")
	if rows then
		dbh.disconnect

		template = ERB.new(File.read('noentried.erb'))
		res.body << template.result(binding)
	else
    dbh.do("insert into bookinfos values ('#{req.query['id'].force_encoding("utf-8")}', '#{req.query['title'].force_encoding("utf-8")}','#{req.query['author'].force_encoding("utf-8")}','#{req.query['page'].force_encoding("utf-8")}','#{req.query['publish_date'].force_encoding("utf-8")}' );")
		dbh.disconnect

		template = ERB.new(File.read('entried.erb'))
		res.body << template.result(binding)
	end
}

server.mount_proc("/retrieve") { |req, res|

	p req.query

	a = ['id', 'title', 'author', 'page', 'publish_date']
	a.delete_if {|name| req.query[name] == ""}

	if a.empty?
		where_data = ""
	else
		a.map! {|name| "#{name}='#{req.query[name]}'"}
		where_data = "where " + a.join(' or')
	end

	template = ERB.new(File.read('retrieved.erb'))
	res.body << template.result(binding)
}

server.mount_proc("/edit") { |req, res|

	p req.query

	dbh = DBI.connect('DBI:SQLite3:bookinfo_sqlite.db')

	dbh.do("update bookinfos set id='#{req.query['id'].force_encoding("utf-8")}',title='#{req.query['title'].force_encoding("utf-8")}',author='#{req.query['author'].force_encoding("utf-8")}',page='#{req.query['page'].force_encoding("utf-8")}',publish_date='#{req.query['publish_date'].force_encoding("utf-8")}' where id='#{req.query['id'].force_encoding("utf-8")}';")

	dbh.disconnect

	template = ERB.new(File.read('edited.erb'))
	res.body << template.result(binding)
}

server.mount_proc("/delete") { |req, res|

	p req.query

	dbh = DBI.connect('DBI:SQLite3:bookinfo_sqlite.db')

	dbh.do("delete from bookinfos where id='#{req.query['id'].force_encoding("utf-8")}';")

	dbh.disconnect

	template = ERB.new(File.read('deleted.erb'))
	res.body << template.result(binding)
}

trap(:INT) do
	server.shutdown
end

server.start

