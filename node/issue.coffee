request = require 'request'
ys = require 'ys-hash'
fs = require 'fs'
util = require 'util'

config = require './config'

if '-D' in process.argv
	config.repo = config.debug_repo

api = "https://api.github.com/repos/#{config.repo.owner}/#{config.repo.name}/issues"

options =
	headers:
		'User-Agent': config.github.userAgent
		'Authorization':"token #{config.github.accessToken}"

exports.handleCrashLog = (req,res,next)->
	fs.readFile './blacklist.json',encoding:'utf8',(err,data)->
		blacklist = JSON.parse data
		for keyword in blacklist.log_keywords
			if (req.params.log.search keyword) isnt -1
				res.writeHead 200
				res.write 'Bye!'
				res.end()
				return

		logHash = ys.hash req.params.log
		hasIssue logHash,(num)->
			if num is -1
				res.writeHead 200
				res.end()
				next()
			else if num?
				date = new Date()
				cmt = "#{date.toString()} #{defaultString req,'user'} <#{defaultString req,'contact'}> reported the same issue."
				createIssueComment cmt,num,(okay)->
					if okay
						res.writeHead 200
						res.end "successfully created issue comment on issue #{num}"
					else
						res.writeHead 503
						res.end 'Unable to create issue comment'
					next()
			else
				issueBody = "User:#{defaultString req,'user'} <#{defaultString req,'contact'}>
				\nLatest crash log:
				\n#{req.params.log}"

				date = new Date()
				labels = ['crash_log',logHash ]
				createIssue "[Crash Log] #{date.toUTCString()}",issueBody,labels,(okay,b)->
					if okay
						closeIssue b.number,(okay)->
							if okay
								res.writeHead 200
								res.end()
							else
								res.end 503
					else
						res.writeHead 503
						res.end 'Unable to create new issue.'
					next()

exports.handleFeedback = (req,res,next)->
	fs.readFile './blacklist.json',encoding:'utf8',(err,data)->
		blacklist = JSON.parse data
		for keyword in blacklist.keywords
			c = req.params.title.concat req.params.feedback
			if (c.search keyword) isnt -1
				console.log 'blocked'
				res.writeHead 400
				res.end()
				return
		uid = (req.params.contact.split '/')[4]
		if uid in blacklist.uids
			console.log 'blocked'
			res.writeHead 400
			res.end()
		else
			issueBody = "User:#{defaultString req,'user'} <#{defaultString req,'contact'}>
			\nVersion: #{req.params.version}\n#{defaultString req,'deviceInfo'}\nFeedback:
			\n#{req.params.feedback}"

			if req.params.title is '' and req.params.feedback is ''
				res.writeHead 400
				res.end()
			else
				createIssue "[Feedback] #{req.params.title}",issueBody,['user_feedback'],(okay)->
					if okay
						res.writeHead 200
					else
						res.writeHead 503
					res.end()
					next()

createIssue = (title,body,label,cb)->
	requestParams =
		title: title
		body: body
		labels: label
	opts = options
	opts.json = requestParams

	request.post api,opts,(e,r,body)->
		console.log 'createIssue,body:%s',util.inspect body
		if r.statusCode is 201
			res = eval body
			cb okay,res
		else
			cb false

hasIssue = (hash,cb)->
	query =
		state: 'all'
		labels: hash
	opt = options
	opt.qs = query
	request.get api,opt,(e,r,body)->
		console.log 'hasIssue,body:%s',util.inspect body
		if e
			cb null
		else
			parsedBody = eval body
			if parsedBody.length is 0
				cb null
			else
				
				if parsedBody[0].state is 'open'
					cb parsedBody[0].number
				else
					cb -1

createIssueComment = (cmt,number,cb)->
	cmtApi = "https://api.github.com/repos/#{config.repo.owner}/#{config.repo.name}/issues/#{number}/comments"
	opts = options
	opts.json =
		body: cmt
	request.post cmtApi,opts,(e,r,body)->
		console.log 'createIssueComment body:%s',util.inspect body
		if r.statusCode is 201
			cb true
		else cb false
	
exports.closeIssue = closeIssue = (number,cb)->
	closeApi = "https://api.github.com/repos/#{config.repo.owner}/#{config.repo.name}/issues/#{number}"
	opts = options
	opts.method = 'PATCH'
	opts.json =
		state: 'closed'
	request.post closeApi,opts,(e,r,body)->
		console.log 'closed issue %d',number
		if r.statusCode is 201
			cb true
		else cb false

defaultString = (req,field)->
	if req.params[field]?
		req.params[field]
	else
		''
