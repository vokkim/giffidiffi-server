define ['Router', 'text!templates/app.html', 'text!templates/project.html', 'text!templates/build.html'], (Router, template, projectTemplate, buildTemplate) ->

  ProjectsController = (params) ->
    Bacon.$.ajax("/api/project").onValue (projects) ->
      context = { projects: projects}
      element = Handlebars.compile(template)(context)
      $('#content').html(element)

  ProjectController = (params) ->
    project = params.project
    Bacon.combineAsArray(Bacon.$.ajax("/api/project/"+project), Bacon.$.ajax("/api/project/"+project+"/build")).onValue (resp) ->
      project = resp[0]
      builds = resp[1]
      element = Handlebars.compile(projectTemplate)({project: project, builds: builds})
      $('#content').html(element)

  BuildController = (params) ->
    project = params.project
    build = params.build
    Bacon.combineAsArray(
        Bacon.$.ajax("/api/project/"+project), 
        Bacon.$.ajax("/api/project/"+project+"/build/"+build),
        Bacon.$.ajax("/api/project/"+project+"/build/"+build+"/tests")).onValue (resp) ->
      project = resp[0]
      build = resp[1]
      tests = resp[2]
      element = Handlebars.compile(buildTemplate)({project: project, build: build, tests: tests})
      $('#content').html(element)
      $("img.lazy").lazyload()

  router = Router({
    '!/:project/:build': BuildController
    '!/:project': ProjectController
    '!/': ProjectsController
    '!': ProjectsController
    '': ProjectsController
  })

  router.onValue (value) ->
    console.log "PARAMS. ", value
    value.controller(value.params)

  

    