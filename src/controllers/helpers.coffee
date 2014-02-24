PouchDB = require("pouchdb")
Bacon = require("baconjs")
_ = require("lodash")

module.exports = (db) ->

  getProject = (name) ->
    Bacon.fromNodeCallback(db.get, "project-"+name)

  getAllDocuments = (ruleF) ->
    Bacon.fromNodeCallback(db.query, {map: ruleF}).map (res) ->
      _.pluck(res.rows, 'value')

  api = 
    getProject: getProject
    getAllDocuments: getAllDocuments