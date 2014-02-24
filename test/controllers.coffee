fs = require('fs')
Buffer = require('buffer').Buffer;
server = require('../server')
fixtures = require('./fixtures.json')
attachments = require('./attachments.json')
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
  before (done) -> setTestAttachments(db)(done)

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

      it 'POST returns 409 conflict if ID already exists', (done) ->   
          data = { name: "testp", displayName: "Conflicting Project" }
          request(url).post('/api/project').send(data).end (err, res) ->
            res.status.should.equal(409)
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

  describe 'Build', ->

    it 'GET project/testproject/build returns all builds for testproject', (done) ->   
      request(url).get('/api/project/testproject/build').end (err, res) ->
        res.status.should.equal(200)
        res.body.length.should.equal(2)
        _.each res.body, (build)->
          build.type.should.equal("build")
          build.project.should.equal("testproject")
        done()

    it 'GET project/testproject/build/:id returns matching projects', (done) ->   
      request(url).get('/api/project/testproject/build/2').expect('Content-Type', /json/).end (err, res) -> 
        res.status.should.equal(200)
        res.body.project.should.equal("testproject")
        res.body.buildNumber.should.equal(2)
        done()

    it 'GET project/testproject/build/:id with unknown ID returns 404', (done) ->   
      request(url).get('/api/project/testproject/build/45').end (err, res) ->
        res.status.should.equal(404)
        done()  

    describe 'CRUD operations', ()->
      before (done) ->
        request(url).post('/api/project/testproject/build').end (err, res) -> 
          done()

      it 'POST creates new Build with incrementing Build ID', (done) ->   
          request(url).get('/api/project/testproject/build/3').end (err, res) ->
            res.status.should.equal(200)
            res.body.project.should.equal('testproject')
            res.body.status.should.equal('created')
            res.body.buildNumber.should.equal(3)
            res.body.tests.should.be.empty
            done()

  describe 'Tests', ->

    it 'GET project/testproject/build/2/tests returns all tests', (done) ->   
      request(url).get('/api/project/testproject/build/2/tests').end (err, res) ->
        res.status.should.equal(200)
        res.body.length.should.equal(2)
        _.each res.body, (build)->
          build.type.should.equal("test")
        done()

     it 'get image for test', (done) ->   
      request(url).get('/api/project/testproject/build/2/tests/first_test/image').expect('Content-Type', /png/).end (err, res) ->
        res.status.should.equal(200)
        done()


    describe 'Creating tests', ()->

      it 'POST creates new set of tests', (done) ->   
        data = [
          { testName: "first_test" },
          { testName: "second_test" },
          { testName: "third_test" }
        ]
        request(url).post('/api/project/testproject/build/2/tests').send(data).end (err, res) ->
          res.status.should.equal(200)
          res.body.length.should.equal(3)
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

setTestAttachments = (db) ->
  (done) ->
    streams = _.map attachments, (attachment) ->
      Bacon.fromNodeCallback(fs.readFile, attachment.file).flatMap (data)->
        Bacon.fromNodeCallback(db.get, attachment.testId).flatMap (doc) ->
          Bacon.fromNodeCallback(db.putAttachment, doc._id, doc.testName, doc._rev, data, "image/png")
    Bacon.combineAsArray(streams).onValue ()-> done()


    
