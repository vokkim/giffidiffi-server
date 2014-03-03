Bacon = require("baconjs")
_ = require("lodash")
express = require("express")

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
        if _.has(result, 'result')
          return { response: val.response, result: result.result, status: result.status, contentType: result.contentType, additionalHeaders: result.additionalHeaders }
        else
          return { response: val.response, result: result }
      .mapError (e) ->
        if _.has e, 'status'
          return { response: val.response, result: e.result, status: e.status }
        else
          code = if _.has(e, 'errno') then determineSqlErrorCode(e.errno) else 500
          return { response: val.response, result: "Error", status: code  }
    .onValue (val) ->
      status = if val.status then val.status else 200
      contentType = if val.contentType then val.contentType else 'application/json'
      if val.additionalHeaders
        val.response().set(val.additionalHeaders)
      val.response().status(status).type(contentType).send(val.result)


  serveResource(router('get','/api/project'), controllers.project.findAllProjects)
  serveResource(router('post','/api/project'), controllers.project.createProject)
  serveResource(router('put','/api/project/:id'), controllers.project.updateProject)
  serveResource(router('delete','/api/project/:id'), controllers.project.removeProject)
  serveResource(router('get','/api/project/:id'), controllers.project.findProject)

  serveResource(router('post','/api/project/:project/build'), controllers.build.createBuild)
  serveResource(router('get','/api/project/:project/build'), controllers.build.findAllBuilds)
  serveResource(router('get','/api/project/:project/build/:number'), controllers.build.findBuild)

  serveResource(router('post','/api/project/:project/build/:number/tests'), controllers.tests.createTests)
  serveResource(router('get','/api/project/:project/build/:number/tests'), controllers.tests.findTests)
  serveResource(router('post','/api/project/:project/build/:number/done'), controllers.build.markAsDone)

  serveResource(router('post','/api/project/:project/build/:number/tests/:test/bad'), controllers.tests.markAsBad)
  serveResource(router('post','/api/project/:project/build/:number/tests/:test/good'), controllers.tests.markAsGood)
  serveResource(router('get','/api/project/:project/build/:number/tests/:test/:image'), controllers.tests.findTestImage)


exports.setup = setup