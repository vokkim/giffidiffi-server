Bacon = require("baconjs")
_ = require("lodash")

module.exports = (db) ->

  helpers = require("./helpers")(db)

  getAllBuilds = (projectName) ->
    helpers.getProject(projectName).flatMap (project) ->
      sql = "SELECT * FROM documents WHERE type = 'build' AND id LIKE '"+ project.name+"-build-%'"
      Bacon.fromNodeCallback(db, "all", sql).flatMap(helpers.handleResultRows)

  createBuild = (request) ->
    projectName = request.params.project
    #TODO: Optimize
    getAllBuilds(projectName).flatMap (existingBuilds) ->
      buildNumber = existingBuilds.length + 1
      build = 
        id: projectName+"-build-"+buildNumber
        project: projectName
        buildNumber: buildNumber
        status: "created"
        start: new Date()
        tests: []
        type: "build"
      
      Bacon.fromNodeCallback(db, "run", "INSERT INTO documents (id, type, value) VALUES (?, ?, ?)", 
        build.id, build.type, JSON.stringify(build))


  findBuild = (request) ->
    helpers.getBuild(request.params.project, request.params.number)

  findAllBuilds = (request) ->
    getAllBuilds(request.params.project)

  api =
    createBuild: createBuild
    findBuild: findBuild
    findAllBuilds: findAllBuilds

