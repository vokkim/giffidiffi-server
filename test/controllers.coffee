fs = require('fs')
Buffer = require('buffer').Buffer;
buffertools = require('buffertools')
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
  dbname: ":memory:"
}
url = "http://localhost:3333"

db = server.start(config)

describe 'API', ->
  this.timeout 5000
  before (done) -> setFixtures(db)(done)
  #before (done) -> setTestAttachments(db)(done)

  describe 'Project', ->
      
    it 'returns all projects', (done) ->   
      request(url).get('/api/project').end (err, res) ->
        res.status.should.equal(200)
        res.body.length.should.equal(2)
        _.each res.body, (project)->
          project.type.should.equal("project")
        done()

    it 'returns matching projects', (done) ->   
      request(url).get('/api/project/myproject').expect('Content-Type', /json/).end (err, res) -> 
        res.status.should.equal(200)
        res.body.name.should.equal("myproject")
        done()

    it 'returns 404 with unknown project ID', (done) ->   
      request(url).get('/api/project/project-2').end (err, res) ->
        res.status.should.equal(404)
        done()  

    describe 'CRUD operations', ()->
      before (done) ->
        data = { name: "testp", displayName: "POST Test Project", _id: "ignoredid" }
        request(url).post('/api/project').send(data).end (err, res) -> 
          res.body.should.be.empty
          done()

      it 'creates new Project with project name as an ID', (done) ->   
        request(url).get('/api/project/testp').end (err, res) ->
          res.status.should.equal(200)
          res.body.name.should.equal('testp')
          res.body.displayName.should.equal('POST Test Project')
          done()

      it 'returns 409 conflict if ID already exists', (done) ->   
        data = { name: "testp", displayName: "Conflicting Project" }
        request(url).post('/api/project').send(data).end (err, res) ->
          res.status.should.equal(409)
          done()

      it 'updates project, but not the id/name', (done) ->   
        data = { name: "modifiedname", displayName: "Modified Test Project", _id: "ignoredid" }
        request(url).put('/api/project/testp').send(data).end (err, res) ->
          request(url).get('/api/project/testp').end (err, res) ->
            res.status.should.equal(200)
            res.body.name.should.equal('testp')
            res.body.displayName.should.equal('Modified Test Project')
            done()

      it 'deletes project', (done) ->   
        request(url).del('/api/project/testp').end (err, res) ->
          request(url).get('/api/project/testp').end (err, res) ->
            res.status.should.equal(404)
            done()

      it 'returns 404 if trying to delete unexisting project', (done) ->   
        request(url).del('/api/project/testp').end (err, res) ->
          res.status.should.equal(404)
          done()

  describe 'Build', ->

    it 'returns all builds for testproject', (done) ->   
      request(url).get('/api/project/testproject/build').end (err, res) ->
        res.status.should.equal(200)
        res.body.length.should.equal(2)
        _.each res.body, (build)->
          build.type.should.equal("build")
          build.project.should.equal("testproject")
        done()

    it 'returns matching project', (done) ->   
      request(url).get('/api/project/testproject/build/2').expect('Content-Type', /json/).end (err, res) -> 
        res.status.should.equal(200)
        res.body.project.should.equal("testproject")
        res.body.buildNumber.should.equal(2)
        done()

    it 'returns 404 with unknown build number', (done) ->   
      request(url).get('/api/project/testproject/build/45').end (err, res) ->
        res.status.should.equal(404)
        done()  

    describe 'CRUD operations', ()->
      before (done) ->
        request(url).post('/api/project/testproject/build').end (err, res) -> 
          done()

      it 'creates new Build with incremental Build ID', (done) ->   
          request(url).get('/api/project/testproject/build/3').end (err, res) ->
            res.status.should.equal(200)
            res.body.project.should.equal('testproject')
            res.body.status.should.equal('created')
            res.body.buildNumber.should.equal(3)
            res.body.tests.should.be.empty
            done()

  describe.skip 'Tests', ->

    it 'GET project/testproject/build/2/tests returns all tests', (done) ->   
      request(url).get('/api/project/testproject/build/2/tests').end (err, res) ->
        res.status.should.equal(200)
        res.body.length.should.equal(2)
        _.each res.body, (build)->
          build.type.should.equal("test")
        done()

    it 'get original image for test', (done) ->   
      request(url).get('/api/project/testproject/build/2/tests/first_test/original').expect('Content-Type', /png/)
      .parse(imageParser).end (err, res) ->
        res.status.should.equal(200)
        imageComparator('./test/2_first_test.png', res.body, done)

    it 'get difference image for test', (done) ->   
      request(url).get('/api/project/testproject/build/2/tests/first_test/diff').expect('Content-Type', /png/)
      .parse(imageParser).end (err, res) ->
        res.status.should.equal(200)
        imageComparator('./test/2_first_test.diff.png', res.body, done)

    it 'returns 404 if no difference image exists', (done) ->   
      request(url).get('/api/project/testproject/build/1/tests/first_test/diff').end (err, res) ->
        res.status.should.equal(404)
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
    inserts = _.map fixtures, (data) ->
      Bacon.fromNodeCallback(db, "run", "INSERT INTO models (id, type, value) VALUES (?, ?, ?)", data.id, data.type, JSON.stringify(data))

    Bacon.combineAsArray(inserts).onValue () -> done()

setTestAttachments = (db) ->

  saveImage = (docId, rev, imageFile, type) ->
    Bacon.fromNodeCallback(fs.readFile, imageFile).flatMap (data)->
      Bacon.fromNodeCallback(db.putAttachment, docId, type, rev, data, "image/png")

  (done) ->
    streams = _.map attachments, (attachment) ->
      Bacon.fromNodeCallback(db.get, attachment.testId).flatMap (doc) ->
        imageStream = saveImage(doc._id, doc._rev, attachment.original, "original")

        if attachment.diff
          imageStream = imageStream.flatMap (res) -> saveImage(doc._id, res.rev, attachment.diff, "diff")

        return imageStream
    Bacon.combineAsArray(streams).onValue ()-> done()


imageParser = (res, callback) ->
    res.setEncoding('binary')
    res.data = ''
    res.on 'data', (chunk) ->
        res.data += chunk;
    res.on 'end', () ->
        callback(null, new Buffer(res.data, 'binary'));

imageComparator = (expectedImage, data, done) ->
  Bacon.fromNodeCallback(fs.readFile, expectedImage)
  .mapError (e) ->
    console.log "Error comparing images ", e
    0
  .onValue (expectedData)->
    should(buffertools.compare(expectedData, data)).equal(0)
    done()


    
