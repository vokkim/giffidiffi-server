express = require("express")
Bacon = require("baconjs")
_ = require("lodash")

controllers = require("./libs/controllers")

initExpressApplication = () ->
  application = express()
   
  application.use express.json()
  application.use express.urlencoded()
  application.use express.multipart()
  application

controllers = controllers()
app = initExpressApplication()

router = (method, path) ->
  bus = new Bacon.Bus()
  cb = (req, res) ->
    bus.push
      request: -> req
      response: -> res
  switch method
    when "get" then app.get(path, cb)
    when "post" then app.post(path, cb)
    when "put" then app.put(path, cb)
    else
      throw new Error "Unrecognized method: "+method
  bus
 

serveResource = (requestStream, controller) ->
  requestStream.flatMap (val) ->
    controller(val.request()).map (result) ->
      { response: val.response, result: result }
    .mapError (e) ->
      { error: e, response: val.response }
  .onValue (val) ->
    if val.error
      val.response().send val.error.status
    else 
      val.response().send val.result

serveResource(router('get','/api/project'), controllers.findAllProjects)
serveResource(router('post','/api/project'), controllers.createProject)
serveResource(router('get','/api/project/:id'), controllers.findProject)
 
 
app.listen 3000
console.log "Listening on port 3000"

