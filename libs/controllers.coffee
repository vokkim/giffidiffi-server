PouchDB = require("pouchdb")
Bacon = require("baconjs")
_ = require("lodash")

exports = module.exports = (db) ->

  getProject = (name) ->
    Bacon.fromNodeCallback(db.get, "project-"+name)

  getAllDocuments = (ruleF) ->
    Bacon.fromNodeCallback(db.query, {map: ruleF}).map (res) ->
      _.pluck(res.rows, 'value')

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
    getProject(request.params.id).flatMap (res) ->
      project = _.merge(res, {displayName: request.body.displayName})
      Bacon.fromNodeCallback(db.put, project).map (res) ->
        project

  removeProject = (request) ->
    getProject(request.params.id).flatMap (res) ->
      Bacon.fromNodeCallback(db.remove, res).map (res) ->
        true

  findProject = (request) ->
    getProject(request.params.id).map (res) ->
      _.omit(res, ['_rev', '_id'])

  findAllProjects = () ->
    rule = (doc) ->
      if doc.type == "project"
        emit(doc._id, doc)

    getAllDocuments(rule).map (docs) ->
      _.map(docs, (doc) -> _.omit(doc, ['_rev', '_id']))

  
  getAllBuilds = (project) ->
    rule = (doc) ->
      if doc.type == "build"
        emit(doc._id, doc)

    getAllDocuments(rule).map (rows)->
      _.filter rows, (row) -> 
        row.project == project.name


  createBuild = (request) ->
    project = request.params.project
    getProject(project).flatMap(getAllBuilds).flatMap (existingBuilds) ->
      buildNumber = existingBuilds.length + 1
      build = 
        _id: project+"-build-"+buildNumber
        project: project
        buildNumber: buildNumber
        status: "created"
        start: new Date()
        tests: []
        type: "build"

      Bacon.fromNodeCallback(db.post, build).map (res) ->
        build

  findBuild = (request) ->
    getProject(request.params.project).flatMap (project) ->
      Bacon.fromNodeCallback(db.get, project.name+"-build-"+request.params.number)
    .map (build) ->
      _.omit(build, ['_rev', '_id'])

  findAllBuilds = (request) ->
    getProject(request.params.project).flatMap(getAllBuilds).map (builds) ->
      _.map(builds, (build) -> _.omit(build, ['_rev', '_id']))

  result =
    project:
      createProject: createProject
      findProject: findProject
      findAllProjects: findAllProjects
      updateProject: updateProject
      removeProject: removeProject
    build:
      createBuild: createBuild
      findBuild: findBuild
      findAllBuilds: findAllBuilds

