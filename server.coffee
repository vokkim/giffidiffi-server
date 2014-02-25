express = require("express")
sqlite3 = require("sqlite3")
fs = require('fs')

controllers = require("./src/controllers")
routes = require("./src/routes")

initExpressApplication = () ->
  application = express()
  application.use express.json()
  application.use express.urlencoded()
  application.use express.multipart()

  application.configure 'development', () ->
    application.use express.errorHandler({ dumpExceptions: true, showStack: true })

  application.configure 'production', () ->
    application.use express.errorHandler()

  application

app = initExpressApplication()

initDatabase = (file) ->
  exists = fs.existsSync(file)
  db = new sqlite3.Database(file)
  if !exists
    db.serialize () ->
      db.run("CREATE TABLE models (id VARCHAR(255) NOT NULL PRIMARY KEY, type VARCHAR(255) NOT NULL, value TEXT)")
      db.run("CREATE TABLE attachments (id VARCHAR(255) NOT NULL PRIMARY KEY, value BLOB)")
  db

start = (config) ->
  db = initDatabase config.dbname
  controllers = controllers db
  routes.setup app, controllers 
  port = process.env.PORT || 3000
  app.listen port
  console.log "%s server on port %d", app.settings.env, port
  db

exports.app = app
exports.start = start
