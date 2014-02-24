Bacon = require("baconjs")

setup = (app, controllers) ->

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
      when "delete" then app.del(path, cb)
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
  serveResource(router('put','/api/project/:id'), controllers.updateProject)
  serveResource(router('delete','/api/project/:id'), controllers.removeProject)
  serveResource(router('get','/api/project/:id'), controllers.findProject)


exports.setup = setup