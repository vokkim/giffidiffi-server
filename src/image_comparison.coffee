Bacon = require("baconjs")
_ = require("lodash")
fs = require('fs')
temp = require('temp')
gm = require('gm')

createTempFile = (stream) ->
  tempFile = temp.createWriteStream()
  tempFile.write(stream)
  tempFile.path

compareImages = (originalImage, referenceImage) ->
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

module.exports = compareImages
