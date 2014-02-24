PouchDB = require("pouchdb")
Bacon = require("baconjs")
_ = require("lodash")

module.exports = (db) ->

  getProject = (name) ->
    Bacon.fromNodeCallback(db.get, "project-"+name)

  getAllDocuments = (ruleF) ->
    Bacon.fromNodeCallback(db.query, {map: ruleF}).map (res) ->
      _.pluck(res.rows, 'value')

  getBuild = (projectName, buildNumber) ->
    getProject(projectName).flatMap (project) ->
      Bacon.fromNodeCallback(db.get, project.name+"-build-"+buildNumber)

  api = 
    getProject: getProject
    getAllDocuments: getAllDocuments
    getBuild: getBuild