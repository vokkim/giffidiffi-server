fs = require('fs')
fixtures = require('./fixtures.json')
attachments = require('./attachments.json')
Bacon = require('baconjs')
_ = require("lodash")

config = 
  dbfile: ":memory:"
  port: 3333

server = require('../server/server')(config)

module.exports.url = "http://localhost:3333"
db = server.db

before (done) -> setFixtures(db)(done)
before (done) -> setTestAttachments(db)(done)

setFixtures = (db) ->
  (done) ->
    inserts = _.map fixtures, (data) ->
      Bacon.fromNodeCallback(db, "run", "INSERT INTO documents (id, type, value) VALUES (?, ?, ?)", data.id, data.type, JSON.stringify(data))

    Bacon.combineAsArray(inserts).onValue () -> done()

setTestAttachments = (db) ->
  (done) ->
    inserts = _.map attachments, (attachment) ->
      Bacon.fromNodeCallback(fs.readFile, attachment.file).flatMap (data)->
        Bacon.fromNodeCallback(db, "run", "INSERT INTO attachments (id, type, value) VALUES (?, ?, ?)", attachment.id, "image/png", data)

    Bacon.combineAsArray(inserts).onValue () -> done()
