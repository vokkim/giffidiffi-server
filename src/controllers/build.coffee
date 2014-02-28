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
        end: null
        tests: []
        type: "build"
      
      Bacon.fromNodeCallback(db, "run", "INSERT INTO documents (id, type, value) VALUES (?, ?, ?)", 
        build.id, build.type, JSON.stringify(build))
      .flatMap () ->
        build

  markAsDone = (request) ->
    helpers.getBuild(request.params.project, request.params.number).flatMap (build) ->
      if build.status != "created"
        return new Bacon.Error {status: 400, result: "Build already complete!"}
      testResults = _.map build.tests, (testName) ->
        helpers.getTest(build.project, build.buildNumber, testName).map (test) ->
          test.status

      Bacon.combineAsArray(testResults).flatMap (results)-> 
        successful = _.every results, (result) ->
          result == "success"
        build.end = new Date()
        build.status = if successful then "success" else "fail"
        helpers.updateDocument(build)
      .flatMap () ->
        build

  findBuild = (request) ->
    helpers.getBuild(request.params.project, request.params.number)

  findAllBuilds = (request) ->
    getAllBuilds(request.params.project)

  api =
    createBuild: createBuild
    findBuild: findBuild
    findAllBuilds: findAllBuilds
    markAsDone: markAsDone

