Bacon = require('baconjs')
assert = require('assert')
should = require('should')
request = require('supertest')
_ = require("lodash")

url = require("./helper").url


describe 'Build', ->

  it 'returns all builds for testproject', (done) ->   
    request(url).get('/api/project/testproject/build').end (err, res) ->
      res.status.should.equal(200)
      res.body.length.should.equal(3)
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
      
    it 'creates new Build with incremental Build ID', (done) ->   
      request(url).post('/api/project/testproject/build').end (err, res) -> 
        res.status.should.equal(200)
        res.body.project.should.equal('testproject')
        res.body.status.should.equal('created')
        res.body.buildNumber.should.equal(4)
        res.body.tests.should.be.empty
        done()
