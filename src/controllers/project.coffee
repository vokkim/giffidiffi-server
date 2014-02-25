Bacon = require("baconjs")
_ = require("lodash")

module.exports = (db) ->


  helpers = require("./helpers")(db)

  createProject = (request) ->
    project = 
      id: "project-"+request.body.name
      name: request.body.name
      displayName: request.body.displayName
      type: "project"

    Bacon.fromNodeCallback(db, "run", "INSERT INTO models (id, type, value) VALUES (?, ?, ?)", 
      project.id, project.type, JSON.stringify(project))

  updateProject = (request) ->
    helpers.getProject(request.params.id).flatMap (res) ->
      project = _.merge(res, {displayName: request.body.displayName})
      Bacon.fromNodeCallback(db, "run", "UPDATE models SET value=? WHERE id=?", 
        JSON.stringify(project), project.id)

  removeProject = (request) ->
    helpers.getProject(request.params.id).flatMap (project) ->
      Bacon.fromNodeCallback(db, "run", "DELETE FROM models WHERE id=?", project.id)

  findProject = (request) ->
    helpers.getProject(request.params.id)
   

  findAllProjects = () ->
    helpers.getAllDocumentsByType('project')
  
  getAllBuilds = (project) ->
    rule = (doc) ->
      if doc.type == "build"
        emit(doc._id, doc)

    helpers.getAllDocuments(rule).map (rows)->
      _.filter rows, (row) -> 
        row.project == project.name

  api =
    createProject: createProject
    findProject: findProject
    findAllProjects: findAllProjects
    updateProject: updateProject
    removeProject: removeProject

