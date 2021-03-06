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
  if referenceImage && referenceImage.value
    referenceTempFile = createTempFile(referenceImage.value)
    return compareImageFiles(originalTempFile, referenceTempFile).flatMap (result) ->
      diff = Bacon.fromNodeCallback(fs.readFile, result.diff)
      diff.onEnd () ->
        removeTempFiles(originalTempFile, referenceTempFile, result.diff)
      Bacon.combineTemplate {
        result: if result.isEqual then "success" else "fail"
        diffData: diff
      }
  else
    console.log "Reference image empty? ", referenceImage
    return Bacon.once {result: "success"}

removeTempFiles = () ->
  _.forIn arguments, (file) ->
    Bacon.fromNodeCallback(fs.unlink, file).onError (e)->
      console.error "Unable to remove temp file: ", file

compareImageFiles = (fileA, fileB) ->
  # Use Bacon.Bus to hack the gm.compare, Bacon.fromCallback did not seem to work properly for gm?
  bus = new Bacon.Bus()
  opt = 
    highlightColor: 'darkviolet'
    tolerance: 0.000001
    file: temp.path({suffix: '.png', prefix: 'giffidiffi-'})

  gm.compare fileA, fileB, opt, (err, isEqual, equality, raw) ->
    if (err) 
      bus.error(new Bacon.Error(err))
    else 
      bus.push({'isEqual': isEqual, 'equality': equality, 'diff': opt.file})
    bus.end()

  bus

module.exports = compareImages
