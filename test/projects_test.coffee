Bacon = require('baconjs')
assert = require('assert')
should = require('should')
request = require('supertest')
_ = require("lodash")

url = require("./helper").url

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
