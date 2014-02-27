fs = require('fs')
Buffer = require('buffer').Buffer;
buffertools = require('buffertools')
Bacon = require('baconjs')
assert = require('assert')
should = require('should')
request = require('supertest')
_ = require("lodash")

url = require("./helper").url


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

    it 'creates new test and returns success', (done) ->   
      data = { testName: "first_test" }
      request(url).post('/api/project/testproject/build/3/tests')
        .field('data', JSON.stringify(data))
        .attach('first_test', './test/new_first_test.png')
        .end (err, res) ->
          res.status.should.equal(200)
          res.body.result.should.equal("success")
          done()

  describe 'Adding new (failing) test', ()->

    it 'create test and returns fail', (done) ->   
      data = { testName: "second_test" }
      request(url).post('/api/project/testproject/build/3/tests')
        .field('data', JSON.stringify(data))
        .attach('second_test', './test/new_second_test.png')
        .end (err, res) ->
          res.status.should.equal(200)
          res.body.result.should.equal("fail")
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


    
