Bacon = require("baconjs")
_ = require("lodash")

module.exports = (db) ->

  getProject = (name) ->
    sql = "SELECT * FROM documents WHERE type = 'project' AND id='project-"+name+"'"
    Bacon.fromNodeCallback(db, "get", sql).flatMap(handleResultRow)

  getAllDocumentsByType = (type) ->
    Bacon.fromNodeCallback(db, "all", "SELECT * FROM documents WHERE type = ?", type).flatMap(handleResultRows)

  getBuild = (projectName, buildNumber) ->
    getProject(projectName).flatMap (project) ->
      id = projectName + "-build-" + buildNumber
      Bacon.fromNodeCallback(db, "get", "SELECT * FROM documents WHERE type = 'build' AND id=?", id).flatMap(handleResultRow)

  getTest = (projectName, buildNumber, testName) ->
    sql = "SELECT * FROM documents WHERE type = 'test' AND id='" + projectName + "-build-" + buildNumber + "-test-" + testName + "'"
    Bacon.fromNodeCallback(db, "get", sql).flatMap(handleResultRow)

  handleResultRows = (rows) ->
    _.map(rows, (row) -> JSON.parse row.value)

  handleResultRow = (row) ->
    if _.isEmpty(row)
        return new Bacon.Error { result: "Not found", status: 404 }
    JSON.parse row.value

  storeDocument = (doc) ->
    Bacon.fromNodeCallback(db, "run", "INSERT INTO documents (id, type, value) VALUES (?, ?, ?)", 
      doc.id, doc.type, JSON.stringify(doc)).map () -> doc

  updateDocument = (doc) ->
    Bacon.fromNodeCallback(db, "run", "UPDATE documents SET value=? WHERE id=?", 
        JSON.stringify(doc), doc.id)

  storeAttachment = (attachment) ->
    Bacon.fromNodeCallback(db, "run", "INSERT INTO attachments (id, type, value) VALUES (?, ?, ?)", 
      attachment.id, attachment.type, attachment.value).map () -> attachment

  api = 
    getProject: getProject
    getAllDocumentsByType: getAllDocumentsByType
    getBuild: getBuild
    getTest: getTest
    handleResultRow: handleResultRow
    handleResultRows: handleResultRows
    storeDocument: storeDocument
    updateDocument: updateDocument
    storeAttachment: storeAttachment