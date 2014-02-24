PouchDB = require("pouchdb")
Bacon = require("baconjs")
_ = require("lodash")

module.exports = (db) ->


  helpers = require("./helpers")(db)

  createProject = (request) ->
    if _.isEmpty(request.body.displayName)
      return Bacon.Error "Must provide displayName"

    if _.isEmpty(request.body.name)
      return Bacon.Error "Must provide name"

    project = 
      _id: "project-"+request.body.name
      name: request.body.name
      displayName: request.body.displayName
      type: "project"
    

    Bacon.fromNodeCallback(db.post, project).map (res) ->
      project

  updateProject = (request) ->
    helpers.getProject(request.params.id).flatMap (res) ->
      project = _.merge(res, {displayName: request.body.displayName})
      Bacon.fromNodeCallback(db.put, project).map (res) ->
        project

  removeProject = (request) ->
    helpers.getProject(request.params.id).flatMap (res) ->
      Bacon.fromNodeCallback(db.remove, res).map (res) ->
        true

  findProject = (request) ->
    helpers.getProject(request.params.id).map (res) ->
      _.omit(res, ['_rev', '_id'])

  findAllProjects = () ->
    rule = (doc) ->
      if doc.type == "project"
        emit(doc._id, doc)

    helpers.getAllDocuments(rule).map (docs) ->
      _.map(docs, (doc) -> _.omit(doc, ['_rev', '_id']))

  
  getAllBuilds = (project) ->
    rule = (doc) ->
      if doc.type == "build"
        emit(doc._id, doc)

    helpers.getAllDocuments(rule).map (rows)->
      _.filter rows, (row) -> 
        row.project == project.name

  api =
    createProject: createProject
    findProject: findProject
    findAllProjects: findAllProjects
    updateProject: updateProject
    removeProject: removeProject

