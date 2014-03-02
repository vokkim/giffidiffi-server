fs = require('fs')

module.exports = (db) ->
  exports = {}
  fs.readdirSync(__dirname).forEach (file) ->
    if file != 'index.coffee' 
      moduleName = file.substr(0, file.indexOf('.'))
      exports[moduleName] = require('./' + moduleName)(db)

  exports
   