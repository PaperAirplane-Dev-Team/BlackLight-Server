request = require 'request'

config = require './config'

class Weibo
	constructor: ->
		@accessToken = config.weibo.accessToken
	setAccessToken: (@accessToken)->

	post: (content,callback)->
		opts  = 
			url: 'https://api.weibo.com/2/statuses/update.json'
			form: 
				access_token: @accessToken
				status: content
			method: 'POST'
		request opts,(e,r,body)->
			parsedBody = JSON.parse body
			if parsedBody.idstr
				callback null,parsedBody
			else
				if parsedBody.error_code?
					e = new Error parsedBody.error
					callback e,parsedBody
				else
					callback e,undefined

module.exports = new Weibo()
