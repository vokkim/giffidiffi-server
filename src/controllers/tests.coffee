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
      sql = "SELECT * FROM models WHERE type = 'test' AND id LIKE '" + projectName + "-build-" + buildNumber + "-test-%'"
      Bacon.fromNodeCallback(db, "all", sql).flatMap(helpers.handleResultRows)

  findReferenceImageId = (projectName, testName) ->
    sql = "SELECT * FROM models WHERE type = 'test' AND id LIKE '" + projectName + "-build-%-test-" + testName + "'"
    Bacon.fromNodeCallback(db, "all", sql).flatMap(helpers.handleResultRows).map (rows) ->
      rows = _.sortBy(rows, 'buildNumber')
      ok = _.findLast rows, (row) ->
        row.status == "success"
      if ok
        return ok.images['original']
      else
        return null

  compareImages = (originalImage, referenceImageId) ->
    Bacon.fromNodeCallback(db, "get", "SELECT * FROM attachments WHERE id=?", referenceImageId).flatMap (referenceImage) ->
      imageComparison(originalImage, referenceImage)

  createTest = (projectName, buildNumber, testName, result, originalImageId, referenceImageId, diffImageId) ->
    test = 
      id: projectName+"-build-"+buildNumber+"-test-"+testName
      project: projectName
      buildNumber: buildNumber
      testName: testName
      status: result
      created: new Date()
      type: "test"
      images: 
        original: originalImageId
        reference: referenceImageId
        diff: diffImageId

    helpers.storeDocument(test)

  runNewTest = (request) ->
    projectName = request.params.project
    buildNumber = parseInt(request.params.number)
    postData = JSON.parse(request.body.data)
    testName = postData.testName
    helpers.getBuild(projectName, buildNumber).flatMap (build) ->
      if _.isEmpty(request.files) || !_.has(request.files, testName) 
        return new Bacon.Error {status: 400, cause: "Missing upload?"}
      if build.status != "created"
        return new Bacon.Error {status: 409, cause: "Build already complete!"}

      originalImageId = generateAttachmentId(projectName, buildNumber, testName, "original")
      Bacon.combineAsArray(parseUploadedImage(originalImageId, request.files[testName]), findReferenceImageId(projectName, testName)).flatMap (v) ->

        originalImage = v[0]
        referenceImageId = v[1]
        resultS = if referenceImageId then compareImages(originalImage, referenceImageId) else Bacon.once({ result: "success" })
        resultS.flatMap (result) ->
          diffImageId = if result.diffData then generateAttachmentId(projectName, buildNumber, testName, "diff") else null

          streams = [createTest(projectName, buildNumber, testName, result.result, originalImage.id, referenceImageId, diffImageId),
                     helpers.storeAttachment(originalImage)]

          if diffImageId
            streams.push(helpers.storeAttachment({id: diffImageId, type: "image/png", value: result.diffData }))

          Bacon.combineAsArray(streams).map () -> result

  generateAttachmentId = (projectName, buildNumber, testName, imageType) ->
    projectName+"-build-"+buildNumber+"-test-"+testName+"-"+imageType

  parseUploadedImage = (imageId, fileHandle) ->
    Bacon.combineTemplate {
      id: imageId
      value: Bacon.fromNodeCallback(fs.readFile, fileHandle.path) 
      type: fileHandle.type
    }

  findTestOriginalImage = (request) ->
    projectName = request.params.project
    buildNumber = parseInt(request.params.number)
    testName = request.params.test
    requestedImage = request.params.image

    if _.contains(["original", "diff", "reference"], requestedImage)
      return helpers.getBuild(projectName, buildNumber).flatMap (build) ->
        sql = "SELECT * FROM models WHERE type = 'test' AND id = '" + projectName + "-build-" + buildNumber + "-test-" + testName + "'"
        Bacon.fromNodeCallback(db, "get", sql).flatMap(helpers.handleResultRow).flatMap (test) ->
          Bacon.fromNodeCallback(db, "get", "SELECT * FROM attachments WHERE id=?", test.images[requestedImage])
          .flatMap (attachment) ->
            if _.isEmpty(attachment)
              return new Bacon.Error {cause: "No " + requestedImage + " image", status: 404}
            { data: attachment.value, contentType: attachment.type }
    else
      return Bacon.once(new Bacon.Error {cause: "Unknown image type: " + requestedImage, status: 400})

  api =
    createTests: runNewTest
    findTests: findTests
    findTestOriginalImage: findTestOriginalImage

