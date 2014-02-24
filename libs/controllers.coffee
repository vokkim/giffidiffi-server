PouchDB = require("pouchdb")
Bacon = require("baconjs")
_ = require("lodash")

exports = module.exports = (db) ->

  createProject = (request) ->
    if _.isEmpty(request.body.displayName)
      return Bacon.Error "Must provide displayName"

    if _.isEmpty(request.body.name)
      return Bacon.Error "Must provide name"

    project = {
      _id: "project-"+request.body.name
      name: request.body.name,
      displayName: request.body.displayName
      type: "project"
    }

    Bacon.fromNodeCallback(db.post, project).map (result) ->
      project

  updateProject = (request) ->
    Bacon.fromNodeCallback(db.get, "project-"+request.params.id).flatMap (result) ->
      project = _.merge(result, {displayName: request.body.displayName})
      Bacon.fromNodeCallback(db.put, project).map (result) ->
        project

  removeProject = (request) ->
    Bacon.fromNodeCallback(db.get, "project-"+request.params.id).flatMap (result) ->
      Bacon.fromNodeCallback(db.remove, result).map (result) ->
        true

  findProject = (request) ->
    Bacon.fromNodeCallback(db.get, "project-"+request.params.id).map (result) ->
      _.omit(result, ['_rev', '_id'])

  findAllProjects = () ->
    Bacon.fromNodeCallback(db.allDocs, {include_docs: true}).map (result) ->
      _.map(_.pluck(result.rows, "doc"), (doc)-> _.omit(doc, ['_rev', '_id']))

  { 
    createProject: createProject,
    findProject: findProject,
    findAllProjects: findAllProjects,
    updateProject: updateProject,
    removeProject: removeProject
  }