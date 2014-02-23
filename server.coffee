express = require("express")
Bacon = require("baconjs")
PouchDB = require("pouchdb")
_ = require("lodash")

initExpressApplication = () ->
  application = express()
   
  application.use express.json()
  application.use express.urlencoded()
  application.use express.multipart()
  application

initDatabase = () ->
  database = new PouchDB "giffidiffi"
  database

db = initDatabase()

app = initExpressApplication()


router = (method, path) ->
  bus = new Bacon.Bus()
  cb = (req, res) ->
    bus.push
      request: -> req
      response: -> res
  switch method
    when "get" then app.get path, cb
    when "post" then app.post path, cb
    when "put" then app.put path, cb
    else 
      throw new Error "Unrecognized method: "+method
  bus
 
 
#createProject = router('post','/api/project')
#getProject = router('get','/api/project/:id')

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

createProject = (request) ->
  project = {
    name: request.body.name,
    displayName: request.body.displayName
    type: "project"
  }
  Bacon.fromNodeCallback(db.post, project).map (result) ->
    project.id = result.id
    project

findProject = (request) ->
  Bacon.fromNodeCallback(db.get, request.params.id)

findAllProjects = () ->
  Bacon.fromNodeCallback(db.allDocs, {include_docs: true}).map (result) ->
    _.map _.pluck(result.rows, "doc"), (doc) ->
      _.omit(doc, ['_id', '_rev'])

serveResource(router('get','/api/project'), findAllProjects)
serveResource(router('post','/api/project'), createProject)
serveResource(router('get','/api/project/:id'), findProject)
 
#r1.filter( (con) -> con.req().params.a == '1' ).flatMap(map_data).log().onValue (con) -> con.res().end con.incr_a.toString()
#r1.filter( (con) -> con.req().params.a != '1' ).onValue (con) -> con.res().end con.req().params.a
 
app.listen 3000
console.log "Listening on port 3000"

