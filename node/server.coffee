restify = require 'restify'
request = require 'request'

hook = require './hook'
issue = require './issue'

server = restify.createServer
	name: 'bl-support'
	version: '1.0.0'

server.use restify.acceptParser server.acceptable
server.use restify.queryParser()
server.use restify.bodyParser()

server.pre (req,res,next)->
	d = new Date()
	console.log '-----------------------------------------'
	console.log 'Incomming request.'
	console.log d.toString()
	console.log req.headers
	console.log '\n'
	res.setHeader 'content-type','text/plain'
	next()

server.post '/bl-hook',hook
server.post '/bl-crashlog',issue.handleCrashLog
server.post '/bl-feedback', issue.handleFeedback

server.listen 23324,->
	console.log 'Server is up and running.'
