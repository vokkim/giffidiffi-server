PouchDB = require("pouchdb")
Bacon = require("baconjs")
_ = require("lodash")

module.exports = (db) ->

  helpers = require("./helpers")(db)

  getAllBuilds = (project) ->
    rule = (doc) ->
      if doc.type == "build"
        emit(doc._id, doc)

    helpers.getAllDocuments(rule).map (rows)->
      _.filter rows, (row) -> 
        row.project == project.name

  createBuild = (request) ->
    project = request.params.project
    helpers.getProject(project).flatMap(getAllBuilds).flatMap (existingBuilds) ->
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
    helpers.getBuild(request.params.project, request.params.number).map (build) ->
      _.omit(build, ['_rev', '_id'])

  findAllBuilds = (request) ->
    helpers.getProject(request.params.project).flatMap(getAllBuilds).map (builds) ->
      _.map(builds, (build) -> _.omit(build, ['_rev', '_id']))

  api =
    createBuild: createBuild
    findBuild: findBuild
    findAllBuilds: findAllBuilds

