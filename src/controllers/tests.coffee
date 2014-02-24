PouchDB = require("pouchdb")
Bacon = require("baconjs")
_ = require("lodash")

module.exports = (db) ->

  helpers = require("./helpers")(db)

  findTests = (request) ->
    projectName = request.params.project
    buildNumber = parseInt(request.params.number)
    helpers.getBuild(projectName, buildNumber).flatMap (build) ->
      rule = (doc) ->
        if doc.type == "test"
          emit(doc._id, doc)
      helpers.getAllDocuments(rule).map (rows) ->
        _.filter rows, (row) -> 
          row.project == projectName && row.buildNumber == buildNumber
    .map (tests) ->
      _.map(tests, (tests) -> _.omit(tests, ['_rev', '_id']))

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
    Bacon.fromNodeCallback(db.get, projectName+"-build-"+buildNumber+"-test-"+testName).flatMap (res) ->
      Bacon.combineTemplate { 
        data: Bacon.fromNodeCallback(db.getAttachment, res._id, testName)
        contentType: res._attachments[testName].content_type
      }

  api =
    createTests: createTests
    findTests: findTests
    findTestOriginalImage: findTestOriginalImage

