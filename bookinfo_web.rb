

require 'webrick'
require 'erb'
require 'dbi'

require './enc_patch'


config = {
	:Port => 8099,
	:DocumentRoot => '.',
}

WEBrick::HTTPServlet::FileHandler.add_handler("erb", WEBrick::HTTPServlet::ERBHandler)

server = WEBrick::HTTPServer.new(config)

server.config[:MimeTypes]["erb"] = "text/html"

server.mount_proc("/list") { |req, res|
	if /(.*)¥.(delete|edit)$/ =~ req.query['operation']
		target_id = $1
		operation = $2
		if operation == 'delete'
			template = ERB.new(File.read('delete.erb'))
		elsif operation == 'edit'
			template ERB.new(File.read('edit.erb'))
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
		dbh.do("insert into bookinfos values ('#{req.query['id']}', '#{req.query['title']}','#{req.query['author']}','#{req.query['page']}','#{req.query['publish_date']}' );")
		dbh.disconnect

		template = ERB.new(File.read('entried.erb'))
		res.body << template.result(binding)
	end
}


trap(:INT) do
	server.shutdown
end

server.start
















