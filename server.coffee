express = require("express")
PouchDB = require('PouchDB')

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

initDatabase = (name) ->
  db = new PouchDB name

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
