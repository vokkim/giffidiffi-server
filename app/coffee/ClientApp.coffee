define ['Router', 'text!templates/app.html'], (Router, template)->
  console.log "JQUERY ", $.fn.jquery
  console.log "Lodash", _.VERSION
  console.log "Bacon", Bacon.version
  console.log "Handlers", Handlebars.VERSION

  router = Router()

  router.addRoute('project','!/:project')
  router.addRoute('build','!/:project/build/:build')
  router.addRoute('projects','!/')

  router.router.onValue (params) ->
    console.log "PARAMS. ", params

  Bacon.$.ajax("/api/project").onValue (projects) ->
    context = { projects: projects}
    element = Handlebars.compile(template)(context)
    $('#content').html(element)
  