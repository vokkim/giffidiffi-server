Bacon = require("baconjs")
_ = require("lodash")
express = require("express")

setup = (app, controllers) ->

  router = (method, path, middleware) ->
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
    #if middleware
    #  app.use('api/project/', middleware)
    bus

  determineSqlErrorCode = (errno) ->
    sqliteErrorCodes =
      "19": 409
      "16": 404
      "23": 403
    result =  if _.has(sqliteErrorCodes, errno) then sqliteErrorCodes[errno] else 500


  serveResource = (requestStream, controller) ->
    requestStream.flatMap (val) ->
      controller(val.request())
      .map (result) ->
        { response: val.response, result: result }
      .mapError (e) ->
        #console.log "ERRR ", e, val.request().path
        if _.has e, 'status'
          return { error: e, response: val.response }
        code = if _.has(e, 'errno') then determineSqlErrorCode(e.errno) else 500
        return { error: {status: code, cause: e}, response: val.response }
      
    .onValue (val) ->
      if val.error
        val.response().send val.error.status
      else 
        val.response().send val.result

  serveFile = (requestStream, controller) ->
    requestStream.flatMap (val) ->
      controller(val.request()).map (result) ->
        { response: val.response, result: result }
      .mapError (e) ->
        #console.error "Error: ", e
        { error: e, response: val.response }
    .onValue (val) ->
      if val.error
        val.response().send val.error.status
      else 
        val.response().type(val.result.contentType).send(val.result.data)

  serveResource(router('get','/api/project'), controllers.project.findAllProjects)
  serveResource(router('post','/api/project'), controllers.project.createProject)
  serveResource(router('put','/api/project/:id'), controllers.project.updateProject)
  serveResource(router('delete','/api/project/:id'), controllers.project.removeProject)
  serveResource(router('get','/api/project/:id'), controllers.project.findProject)

  serveResource(router('post','/api/project/:project/build'), controllers.build.createBuild)
  serveResource(router('get','/api/project/:project/build'), controllers.build.findAllBuilds)
  serveResource(router('get','/api/project/:project/build/:number'), controllers.build.findBuild)

  serveResource(router('post','/api/project/:project/build/:number/tests', express.multipart()), controllers.tests.createTests)
  serveResource(router('get','/api/project/:project/build/:number/tests'), controllers.tests.findTests)
  serveResource(router('post','/api/project/:project/build/:number/done'), controllers.build.markAsDone)
  
  serveFile(router('get','/api/project/:project/build/:number/tests/:test/:image'), controllers.tests.findTestImage)


exports.setup = setup