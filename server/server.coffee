express = require("express")
sqlite3 = require("sqlite3")
fs = require('fs')

controllers = require("./controllers")
routes = require("./routes")

initExpressApplication = () ->
  app = express()
  app.use express.json()
  app.use express.urlencoded()
  app.use express.multipart()
  
  app.use(express.static(__dirname + '/public'));

  app.configure 'development', () ->
    app.use(express.static(__dirname + './../.tmp'));
    app.use(express.static(__dirname + './../app'));
    app.use express.errorHandler({ dumpExceptions: true, showStack: true })
   
  app.configure 'production', () ->
    app.use(express.static(__dirname + './../dist'))
    app.use express.errorHandler()
  app

initDatabase = (file) ->
  exists = fs.existsSync(file)
  db = new sqlite3.Database(file)
  if !exists
    db.serialize () ->
      db.run("CREATE TABLE documents (id VARCHAR(255) NOT NULL PRIMARY KEY, type VARCHAR(255) NOT NULL, value TEXT)")
      db.run("CREATE TABLE attachments (id VARCHAR(255) NOT NULL PRIMARY KEY, type VARCHAR(255) NOT NULL, value BLOB)")
  db

module.exports = (config) ->
  app = initExpressApplication()
  db = initDatabase config.dbfile
  controllers = controllers db
  routes.setup app, controllers 
  app.listen config.port 
  console.log "Starting %s server, dbfile %s, port %d", app.settings.env, config.dbfile, config.port

  api =
    app: app
    db: db




