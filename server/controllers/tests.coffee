Bacon = require("baconjs")
_ = require("lodash")
fs = require('fs')
imageComparison = require('../image_comparison')

module.exports = (db) ->

  helpers = require("./helpers")(db)

  findTests = (request) ->
    projectName = request.params.project
    buildNumber = parseInt(request.params.number)

    helpers.getBuild(projectName, buildNumber).flatMap (build) ->
      sql = "SELECT * FROM documents WHERE type = 'test' AND id LIKE '" + projectName + "-build-" + buildNumber + "-test-%'"
      Bacon.fromNodeCallback(db, "all", sql).flatMap(helpers.handleResultRows)

  findReferenceImageId = (projectName, testName, currentBuild) ->
    sql = "SELECT * FROM documents WHERE type = 'test' AND id LIKE '" + projectName + "-build-%-test-" + testName + "'"
    Bacon.fromNodeCallback(db, "all", sql).flatMap(helpers.handleResultRows).map (rows) ->
      rows = _.sortBy(rows, 'buildNumber')
      ok = _.findLast rows, (row) ->
        _.contains(["success", "good"], row.status) && row.buildNumber < currentBuild
      if ok
        return ok.images['original']
      else
        return null

  compareImages = (originalImage, referenceImageId) ->
    Bacon.fromNodeCallback(db, "get", "SELECT * FROM attachments WHERE id=?", referenceImageId).flatMap (referenceImage) ->
      imageComparison(originalImage, referenceImage)

  createTest = (build, testName, result, originalImageId, referenceImageId, diffImageId) ->
    test = 
      id: build.project + "-build-" + build.buildNumber + "-test-" + testName
      project: build.project
      buildNumber: build.buildNumber
      testName: testName
      status: result
      created: new Date()
      type: "test"
      images: 
        original: originalImageId
        reference: referenceImageId
        diff: diffImageId

    build.tests.push(testName)
    helpers.storeDocument(test).flatMap () ->
      helpers.updateDocument(build)

  runNewTest = (request) ->
    projectName = request.params.project
    buildNumber = parseInt(request.params.number)
    postData = request.body
    if !postData.testName
      postData = JSON.parse(request.body.data)
    testName = postData.testName
    helpers.getBuild(projectName, buildNumber).flatMap (build) ->
      if _.isEmpty(request.files) || !_.has(request.files, testName) 
        return new Bacon.Error {status: 400, result: "Missing upload?"}
      if build.status != "created"
        return new Bacon.Error {status: 409, result: "Build already complete!"}

      originalImageId = generateAttachmentId(projectName, buildNumber, testName, "original")
      Bacon.combineAsArray(parseUploadedImage(originalImageId, request.files[testName]), findReferenceImageId(projectName, testName, buildNumber)).flatMap (v) ->

        originalImage = v[0]
        referenceImageId = v[1]

        resultS = if referenceImageId then compareImages(originalImage, referenceImageId) else Bacon.once({ result: "success" })
        resultS.flatMap (result) ->
          diffImageId = if result.diffData then generateAttachmentId(projectName, buildNumber, testName, "diff") else null

          streams = [createTest(build, testName, result.result, originalImage.id, referenceImageId, diffImageId),
                     helpers.storeAttachment(originalImage)]

          if diffImageId
            streams.push(helpers.storeAttachment({id: diffImageId, type: "image/png", value: result.diffData }))

          Bacon.combineAsArray(streams).map () -> 
            {status: result.result}
            

  markAsBad = (request) ->
    projectName = request.params.project
    buildNumber = parseInt(request.params.number)
    testName = request.params.test
    markTestAs(projectName, buildNumber, testName, "fail")

  markAsGood = (request) ->
    projectName = request.params.project
    buildNumber = parseInt(request.params.number)
    testName = request.params.test
    markTestAs(projectName, buildNumber, testName, "good")

  markTestAs = (projectName, buildNumber, testName, status) ->
    helpers.getBuild(projectName, buildNumber).flatMap (build) ->
      if build.status == "created"
        return new Bacon.Error {status: 409, result: "Can not mark tests for incomplete build!"}
      helpers.getTest(projectName, buildNumber, testName).flatMap (test) ->
        test.status = status
        helpers.updateDocument(test)
      .flatMap () -> 
        helpers.updateBuildStatus(build)

  generateAttachmentId = (projectName, buildNumber, testName, imageType) ->
    projectName+"-build-"+buildNumber+"-test-"+testName+"-"+imageType

  parseUploadedImage = (imageId, fileHandle) ->
    Bacon.combineTemplate {
      id: imageId
      value: Bacon.fromNodeCallback(fs.readFile, fileHandle.path)
      type: fileHandle.type
    }

  findTestImage = (request) ->
    projectName = request.params.project
    buildNumber = parseInt(request.params.number)
    testName = request.params.test
    requestedImage = request.params.image

    if _.contains(["original", "diff", "reference"], requestedImage)
      return helpers.getTest(projectName, buildNumber, testName).flatMap (test) ->
        Bacon.fromNodeCallback(db, "get", "SELECT * FROM attachments WHERE id=?", test.images[requestedImage])
        .flatMap (attachment) ->
          if _.isEmpty(attachment)
            return new Bacon.Error {result: "No " + requestedImage + " image", status: 404}
          return { result: attachment.value, contentType: attachment.type, additionalHeaders: {'Cache-Control':'max-age=259200'} }
    else
      return Bacon.once(new Bacon.Error {result: "Unknown image type: " + requestedImage, status: 400})

  api =
    createTests: runNewTest
    findTests: findTests
    findTestImage: findTestImage
    markAsGood: markAsGood
    markAsBad: markAsBad

