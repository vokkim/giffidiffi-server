Bacon = require("baconjs")
_ = require("lodash")
fs = require('fs')
temp = require('temp')
gm = require('gm')

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
      originalTempFile = createTempFile(originalImage.value)
      referenceTempFile = createTempFile(referenceImage.value)
      compareImageFiles(originalTempFile, referenceTempFile).flatMap (result) ->
        Bacon.combineTemplate {
          result: if result.isEqual then "success" else "fail"
          diffData: Bacon.fromNodeCallback(fs.readFile, result.diff)
        }

  compareImageFiles = (fileA, fileB) ->
    # Use Bacon.Bus to hack the gm.compare, Bacon.fromCallback did not seem to work properly for some reason?
    bus = new Bacon.Bus()
    opt = 
      highlightColor: 'yellow'
      tolerance: 0.002
      file: temp.path({suffix: '.png', prefix: 'giffidiffi-'})

    gm.compare fileA, fileB, opt, (err, isEqual, equality, raw) ->
      if (err) 
        bus.error(new Bacon.Error(err))
      else 
        bus.push({'isEqual': isEqual, 'equality': equality, 'diff': opt.file})
      bus.end()

    bus

  createTempFile = (stream) ->
    tempFile = temp.createWriteStream()
    tempFile.write(stream)
    tempFile.path

  createTests = (request) ->
    projectName = request.params.project
    buildNumber = parseInt(request.params.number)
    postData = JSON.parse(request.body.data)
    testName = postData.testName
    helpers.getBuild(projectName, buildNumber).flatMap (build) ->
      if _.isEmpty(request.files) || !_.has(request.files, testName) 
        return new Bacon.Error {status: 400, cause: "Missing upload?"}
      originalImageId = generateAttachmentId(projectName, buildNumber, testName, "original")
      Bacon.combineAsArray(parseUploadedImage(originalImageId, request.files[testName]), findReferenceImageId(projectName, testName)).flatMap (v) ->

        originalImage = v[0]
        referenceImageId = v[1]
        resultS = if referenceImageId then compareImages(originalImage, referenceImageId) else Bacon.once({ result: "success" })
        resultS.flatMap (result) ->
          diffImageId = if result.diffData then generateAttachmentId(projectName, buildNumber, testName, "diff") else null

          test = 
            id: projectName+"-build-"+buildNumber+"-test-"+testName
            project: projectName
            buildNumber: buildNumber
            testName: testName
            status: result.result
            created: new Date()
            type: "test"
            images: 
              original: originalImage.id
              reference: referenceImageId
              diff: diffImageId

          streams = [helpers.storeDocument(test), helpers.storeAttachment(originalImage)]

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
    createTests: createTests
    findTests: findTests
    findTestOriginalImage: findTestOriginalImage

