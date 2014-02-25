Bacon = require("baconjs")
_ = require("lodash")

module.exports = (db) ->

  helpers = require("./helpers")(db)

  findTests = (request) ->
    projectName = request.params.project
    buildNumber = parseInt(request.params.number)

    helpers.getBuild(projectName, buildNumber).flatMap (build) ->
      sql = "SELECT * FROM models WHERE type = 'test' AND id LIKE '" + projectName + "-build-" + buildNumber + "-test-%'"
      Bacon.fromNodeCallback(db, "all", sql).flatMap(helpers.handleResultRows)

  createTests = (request) ->
    projectName = request.params.project
    buildNumber = parseInt(request.params.number)

    #console.log "FILES", request.files
    docs = _.map request.body, (test) ->
      doc = 
        _id: projectName+"-build-"+buildNumber+"-test-"+test.testName
        project: projectName
        buildNumber: buildNumber
        testName: test.testName
        status: "created"
        created: new Date()
        type: "test"

    helpers.getBuild(projectName, buildNumber).flatMap (build)->
      Bacon.fromNodeCallback(db.bulkDocs, {docs: docs})  
    .map (result) ->
      docs

  findTestOriginalImage = (request) ->
    projectName = request.params.project
    buildNumber = parseInt(request.params.number)
    testName = request.params.test
    requestedImage = request.params.image

    if _.contains(["original", "diff", "reference"], requestedImage)

      return helpers.getBuild(projectName, buildNumber).flatMap (build) ->
        sql = "SELECT * FROM models WHERE type = 'test' AND id = '" + projectName + "-build-" + buildNumber + "-test-"+testName+"'"
        Bacon.fromNodeCallback(db, "get", sql).flatMap(helpers.handleResultRow).flatMap (test) ->
          Bacon.fromNodeCallback(db, "get", "SELECT * FROM attachments WHERE id=?", test.images[requestedImage])
          .flatMap (attachment) ->
            if _.isEmpty(attachment)
              return new Bacon.Error {cause: "No " + requestedImage + " image", status: 404}
            { data: attachment.value, contentType: attachment.type }
    else
      return Bacon.once(new Bacon.Error {cause: "Unknown image type: " + requestedImage, status: 400})

  api =
    createTests: createTests
    findTests: findTests
    findTestOriginalImage: findTestOriginalImage

