weibo = require './weibo'
issue = require './issue'
request = require 'request'

weiboCallback = (res,next)->
	(e,body)->
		if not e
			res.writeHead(200)
			res.write "Weibo successfullly posted."
		else
			if body.error_code?
				res.writeHead(503)
				res.write "Error requesting Weibo API. Error Code: #{body.error_code}. Error: #{body.error}"
			else
				res.writeHead(500)
				res.write "Internal Error. Error: #{e}"
		res.end()
		next()

module.exports = (req,res,next)->
	switch req.headers['x-github-event']
		when 'push'
			handlePushEvent req,res,next
		when 'create'
			handleCreateEvent req,res,next
		when 'issues'
			handleIssueEvent req,res,next
		when 'release'
			handleReleaseEvent req,res,next
		when 'issue_comment'
			handleIssueCommentEvent req,res,next
		else
			res.writeHead(204)
			res.end()

handlePushEvent = (req,res,next)->
	pusher = req.params.pusher.name
	branch = req.params.ref
	url = req.params.compare
	headCommit = req.params.head_commit
		.message.split('\n')[0]
	commits = req.params.commits.length

	weiboContent = "[PUSH] #{pusher} pushed
	#{commits} #{if commits is 1 then 'commit' else 'commits'}
	to #{branch}. Head is now '#{headCommit}'. Compare:
	#{url}"

	weibo.post weiboContent,weiboCallback res,next

handleCreateEvent = (req,res,next)->
	if req.params.ref_type isnt 'tag'
		content = "[CREATE] #{req.params.sender.login} created a new
		#{req.params.ref_type} '#{req.params.ref}'."

		weibo.post content, weiboCallback res,next

handleIssueEvent = (req,res,next)->
	switch req.params.action
		when (not "labeled") and (not "closed") and (not "assigned")
			content = "[ISSUE #{req.params.action.toUpperCase()}] #{req.params.sender.login}
			#{req.params.action} an issue '#{req.params.issue.title}'. #{req.params.issue.html_url}"
			weibo.post content, weiboCallback res,next
		else
			res.writeHead(204)
			res.end()

handleIssueCommentEvent = (req,res,next)->
	commentBody = req.params.comment.body
	if commentBody.indexOf('&close') >= 0
		issue.closeIssue req.params.issue.number,(result)->
			console.log result

	if req.params.issue.title.indexOf("[Feedback]")!=-1 and commentBody.indexOf("^")!=-1
		reply = req.params.comment.body.slice(req.params.comment.body.indexOf("^")+1)
		reply = reply.slice(0,reply.indexOf("^"))
		user = ((req.params.issue.body.split("\n",1))[0].split(" ",1))[0].slice(5)
		title = req.params.issue.title.slice(11)
		developer = switch req.params.comment.user.login
			when "PeterCxy" then "@颠倒的阿卡林型次元"
			when "xavieryao" then "@一抔学渣"
			when "Harry-Chen" then "@HarryChen-SIGKILL-"
			when "fython" then "@你烧饼吗"
			when "2q1w1997" then "@七只小鸡1997"
			else req.params.comment.user.login
		content = "[反馈回复] @#{user} 您好，开发者#{developer} 对反馈\"#{title}\"的回复是\"#{reply}\" 回复请转发此微博 #{req.params.issue.html_url}"
		console.log content
		weibo.post content, weiboCallback res,next
	else
		res.writeHead 204
		res.end()


handleReleaseEvent = (req,res,next)->
	getApkUrl req.params.release.assets_url,(err,url)->
		content = "[RELEASE] #{req.params.sender.login} published a new
		#{if req.params.release.prerelease then 'pre-release' else 'release'}
		. #{req.params.release.html_url}
		Download apk: #{url}"

	weibo.post content, weiboCallback res,next

getApkUrl = (assetsUrl,callback)->
	request assetsUrl,(err,res,body)->
		if err
			callback err,null
		else
			response = JSON.parse body
			if response.length > 0
				callback null,response[0].browser_download_url
			else
				callback 'no apk'
