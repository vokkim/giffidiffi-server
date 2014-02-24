PouchDB = require("pouchdb")
Bacon = require("baconjs")
_ = require("lodash")

exports = module.exports = (db) ->

  createProject = (request) ->
    project = {
      name: request.body.name,
      displayName: request.body.displayName
      type: "project"
    }

    Bacon.fromNodeCallback(db.post, project).map (result) ->
      project.id = result.id
      project

  findProject = (request) ->
    Bacon.fromNodeCallback(db.get, request.params.id)

  findAllProjects = () ->
    Bacon.fromNodeCallback(db.allDocs, {include_docs: true}).map (result) ->
      _.map(_.pluck(result.rows, "doc"), (doc)-> _.omit(doc, ['_rev']))

  { 
    createProject: createProject,
    findProject: findProject,
    findAllProjects: findAllProjects
  }