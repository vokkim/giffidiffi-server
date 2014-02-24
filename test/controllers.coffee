server = require('../server')
fixtures = require('./fixtures.json')
Bacon = require('baconjs')
assert = require('assert')
PouchDB = require('PouchDB')
should = require('should')
request = require('supertest')
_ = require("lodash")

config = {
  dbname: "./db/giffidiffi-test"
}
url = "http://localhost:3333"

db = server.start(config)

describe 'API', ->
  this.timeout 5000
  before (done) -> clearDatabase(db)(done)
  before (done) -> setFixtures(db)(done)

  describe 'Project', ->
      
    it 'GET project/ returns all projects', (done) ->   
      request(url).get('/api/project').expect(200).end (err, res) ->
        res.body.length.should.equal(2)
        _.each res.body, (project)->
          project.type.should.equal("project")
        done()

    it 'GET project/:id returns matching projects', (done) ->   
      request(url).get('/api/project/project-2').expect(200).end (err, res) ->
        res.body.name.should.equal("myproject")
        done()

    it 'GET project/:id with unknown ID returns 404', (done) ->   
      request(url).get('/api/project/project-2').expect(404).end (err, res) ->
        done()  

    it.skip 'POST creates new Project with random ID', (done) ->   
      data = { name: "test", displayName: "Test Project" }
      request(url).post('/api/project').send(data).end (err, res) ->
        id = res.id

        request(url).get('/api/project/'+id).end (err, res) ->
          res.should.have.status(200);
          res.name.should.equal('test')
          res.displayName.should.equal('Test Project')
          done()


clearDatabase = (db) ->
  (done) ->
    Bacon.fromNodeCallback(db.allDocs, {include_docs: true}).map (result)->
      _.map result.rows, (row) -> 
        row.doc
    .flatMap (docs)->
      docs = _.map docs, (doc) -> _.merge(doc, {_deleted: true})
      if _.isEmpty docs
        console.log "EMPTY"
        Bacon.once(true)
      else
        Bacon.fromNodeCallback(db.bulkDocs, {docs: docs})
    .onValue () -> done()

setFixtures = (db) ->
  (done) ->
    Bacon.fromNodeCallback(db.bulkDocs, {docs: fixtures}).onValue () -> done()
