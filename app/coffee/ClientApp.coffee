define ['Router', 'text!templates/app.html', 'text!templates/project.html', 'text!templates/build.html', 'text!templates/test_details.html'], (Router, template, projectTemplate, buildTemplate, testDetailsTemplate) ->

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

  TestDetailsController = (testRow, test) ->
    element = $(Handlebars.compile(testDetailsTemplate)(test).trim())
    testRow.after(element)
    _.forIn test.images, (value, key)->
      if _.isEmpty(value)
        element.find('.'+key).attr('disabled', 'disabled')

    selected = Bacon.mergeAll(
      element.find('.original').clickE().map('original'),
      element.find('.diff').clickE().map('diff'),
      element.find('.reference').clickE().map('reference'),
      ).toProperty('original').skipDuplicates()

    selected.onValue (selection) ->
      element.find('button').removeClass('active')
      element.find('.'+selection).addClass('active')

      element.find('.frame .image').removeClass('shown')
      element.find('.frame .' + selection).addClass('shown')

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
      element = $(Handlebars.compile(buildTemplate)({project: project, build: build, tests: tests }).trim())

      rows = _.map element.find('.tests .row'), (row) -> $(row)
      _.each rows, (row) ->
        id = row.data('id')
        test = _.find tests, (test) ->
          test.id == id
        TestDetailsController(row, test)

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

  

    