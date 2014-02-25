Bacon = require("baconjs")
_ = require("lodash")

module.exports = (db) ->

  getProject = (name) ->
    sql = "SELECT * FROM models WHERE type = 'project' AND id='project-"+name+"'"
    Bacon.fromNodeCallback(db, "get", sql).flatMap(handleResultRow)

  getAllDocuments = (ruleF) ->
    Bacon.fromNodeCallback(db.query, {map: ruleF}).map (res) ->
      _.pluck(res.rows, 'value')

  getAllDocumentsByType = (type) ->
    Bacon.fromNodeCallback(db, "all", "SELECT * FROM models WHERE type = ?", type).flatMap(handleResultRows)

  getBuild = (projectName, buildNumber) ->
    getProject(projectName).flatMap (project) ->
      id = projectName + "-build-" + buildNumber
      Bacon.fromNodeCallback(db, "get", "SELECT * FROM models WHERE type = 'build' AND id=?", id).flatMap(handleResultRow)

  handleResultRows = (rows) ->
    _.map(rows, (row) -> JSON.parse row.value)

  handleResultRow = (row) ->
    if _.isEmpty(row)
        return new Bacon.Error { cause: "Not found", status: 404 }
    JSON.parse row.value

  api = 
    getProject: getProject
    getAllDocumentsByType: getAllDocumentsByType
    getBuild: getBuild
    handleResultRow: handleResultRow
    handleResultRows: handleResultRows