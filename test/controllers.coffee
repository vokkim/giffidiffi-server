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
      request(url).get('/api/project').end (err, res) ->
        res.status.should.equal(200)
        res.body.length.should.equal(2)
        _.each res.body, (project)->
          project.type.should.equal("project")
        done()

    it 'GET project/:id returns matching projects', (done) ->   
      request(url).get('/api/project/myproject').expect('Content-Type', /json/).end (err, res) -> 
        res.status.should.equal(200)
        res.body.name.should.equal("myproject")
        done()

    it 'GET project/:id with unknown ID returns 404', (done) ->   
      request(url).get('/api/project/project-2').end (err, res) ->
        res.status.should.equal(404)
        done()  

    describe 'CRUD operations', ()->
      before (done) ->
        data = { name: "testp", displayName: "POST Test Project", _id: "ignoredid" }
        request(url).post('/api/project').send(data).end (err, res) -> done()

      it 'POST creates new Project with project name as an ID', (done) ->   
          request(url).get('/api/project/testp').end (err, res) ->
            res.status.should.equal(200)
            res.body.name.should.equal('testp')
            res.body.displayName.should.equal('POST Test Project')
            done()

      it 'PUT updates project, but not the id/name', (done) ->   
          data = { name: "modifiedname", displayName: "Modified Test Project", _id: "ignoredid" }
          request(url).put('/api/project/testp').send(data).end (err, res) ->
            request(url).get('/api/project/testp').end (err, res) ->
              res.status.should.equal(200)
              res.body.name.should.equal('testp')
              res.body.displayName.should.equal('Modified Test Project')
              done()

      it 'DELETE deletes project', (done) ->   
          request(url).del('/api/project/testp').end (err, res) ->
            request(url).get('/api/project/testp').end (err, res) ->
              res.status.should.equal(404)
              done()

      it 'DELETE unexisting project returns 404', (done) ->   
          request(url).del('/api/project/testp').end (err, res) ->
            res.status.should.equal(404)
            done()


clearDatabase = (db) ->
  (done) ->
    Bacon.fromNodeCallback(db.allDocs, {include_docs: true}).map (result)->
      _.map result.rows, (row) -> 
        row.doc
    .flatMap (docs)->
      docs = _.map docs, (doc) -> _.merge(doc, {_deleted: true})
      if _.isEmpty docs
        Bacon.once(true)
      else
        Bacon.fromNodeCallback(db.bulkDocs, {docs: docs})
    .onValue () -> done()

setFixtures = (db) ->
  (done) ->
    Bacon.fromNodeCallback(db.bulkDocs, {docs: fixtures}).onValue () -> done()
