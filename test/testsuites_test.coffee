fs = require('fs')
Buffer = require('buffer').Buffer;
buffertools = require('buffertools')
Bacon = require('baconjs')
assert = require('assert')
should = require('should')
request = require('supertest')
_ = require("lodash")

url = require("./test_helper").url


describe 'Testsuites', ->

  it 'returns all tests', (done) ->   
    request(url).get('/api/project/testproject/build/2/tests').end (err, res) ->
      res.status.should.equal(200)
      res.body.length.should.equal(2)
      _.each res.body, (build)->
        build.type.should.equal("test")
      done()

  it 'returns original image for test', (done) ->   
    request(url).get('/api/project/testproject/build/2/tests/first_test/original').expect('Content-Type', /png/)
    .parse(imageParser).end (err, res) ->
      res.status.should.equal(200)
      res.get('Cache-Control').should.equal('max-age=259200')
      imageComparator('./test/2_first_test.png', res.body, done)

  it 'get difference image for test', (done) ->   
    request(url).get('/api/project/testproject/build/2/tests/first_test/diff').expect('Content-Type', /png/)
    .parse(imageParser).end (err, res) ->
      res.status.should.equal(200)
      imageComparator('./test/2_first_test.diff.png', res.body, done)

  it 'get reference image for test', (done) ->   
    request(url).get('/api/project/testproject/build/2/tests/first_test/reference').expect('Content-Type', /png/)
    .parse(imageParser).end (err, res) ->
      res.status.should.equal(200)
      imageComparator('./test/1_first_test.png', res.body, done)

  it 'returns 404 if no difference image exists', (done) ->   
    request(url).get('/api/project/testproject/build/1/tests/first_test/diff').end (err, res) ->
      res.status.should.equal(404)
      done()

  it 'returns 400 if wrong image resource requested', (done) ->   
    request(url).get('/api/project/testproject/build/2/tests/first_test/asd').end (err, res) ->
      res.status.should.equal(400)
      done()

    
  describe 'Adding new test', ()->

    it 'creates a new test and returns success', (done) ->   
      data = { testName: "first_test" }
      request(url).post('/api/project/testproject/build/3/tests').field('data', JSON.stringify(data))
        .attach('first_test', './test/new_first_test.png')
        .end (err, res) ->
          res.status.should.equal(200)
          res.body.status.should.equal("success")
          done()

    it 'creates a new test without prior history, returns success', (done) ->   
      data = { testName: "third_test" }
      request(url).post('/api/project/testproject/build/3/tests').field('data', JSON.stringify(data))
        .attach('third_test', './test/2_first_test.png')
        .end (err, res) ->
          res.status.should.equal(200)
          res.body.status.should.equal("success")
          done()

    it 'does not allow to add tests to completed build', (done) ->   
      data = { testName: "new_test" }
      request(url).post('/api/project/testproject/build/2/tests').field('data', JSON.stringify(data))
        .attach('new_test', './test/new_first_test.png')
        .end (err, res) ->
          res.status.should.equal(409)
          done()

  describe 'Adding new (failing) test', ()->

    it 'creates a new test and returns fail', (done) ->   
      data = { testName: "second_test" }
      request(url).post('/api/project/testproject/build/3/tests')
        .field('data', JSON.stringify(data))
        .attach('second_test', './test/new_second_test.png')
        .end (err, res) ->
          res.status.should.equal(200)
          res.body.status.should.equal("fail")
          done()

    it 'returns correct original image for test', (done) ->   
      request(url).get('/api/project/testproject/build/3/tests/second_test/original').parse(imageParser).end (err, res) ->
        res.status.should.equal(200)
        imageComparator('./test/new_second_test.png', res.body, done)

    it 'returns correct reference image for test', (done) ->   
      request(url).get('/api/project/testproject/build/3/tests/second_test/reference').parse(imageParser).end (err, res) ->
        res.status.should.equal(200)
        imageComparator('./test/second_test.png', res.body, done)

    it 'returns difference image', (done) ->   
      request(url).get('/api/project/testproject/build/3/tests/second_test/diff').end (err, res) ->
        res.status.should.equal(200)
        res.type.should.equal("image/png")
        res.header['content-length'].should.above(10000)
        done()

  describe 'Mark suite as completed', ()->

    it 'returns the build data with correct result and tests', (done) ->   
      data = { testName: "first_test" }
      request(url).post('/api/project/testproject/build/3/done').end (err, res) ->
        res.status.should.equal(200)
        res.body.status.should.equal("fail")
        res.body.tests.should.containDeep(["first_test", "third_test", "second_test"])
        res.body.end.should.be.ok
        done()

    it 'does not allow to mark already completed build', (done) ->   
      data = { testName: "first_test" }
      request(url).post('/api/project/testproject/build/2/done').end (err, res) ->
        res.status.should.equal(400)
        done()

  describe 'Mark individual test as good', ()->

    before (done) ->
      request(url).post('/api/project/testproject/build/3/tests/second_test/good').expect(200).end (err, res)->
        if err then throw err
        done()

    it 'updates build status to success', (done) ->   
      request(url).get('/api/project/testproject/build/3').end (err, res) -> 
        res.status.should.equal(200)
        res.body.status.should.equal("success")
        done()

    it 'does not allow to mark tests if the build is incomplete', (done) ->   
      request(url).post('/api/project/myproject/build/1/tests/myproject_test/good').end (err, res) -> 
        res.status.should.equal(409)
        done()

  describe 'Mark test as bad', ()->

    before (done) ->
      request(url).post('/api/project/testproject/build/1/tests/second_test/bad').expect(200).end (err, res)->
        if err then throw err
        done()

    it 'updates build status to fail', (done) ->   
      request(url).get('/api/project/testproject/build/1').end (err, res) -> 
        res.status.should.equal(200)
        res.body.status.should.equal("fail")
        done()

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


    
