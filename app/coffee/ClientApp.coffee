define ['Router', 'text!templates/app.html', 'text!templates/project.html', 'text!templates/build.html', 'text!templates/build_row.html', 'text!templates/test_row.html', 'text!templates/test_details.html'], (Router, template, projectTemplate, buildTemplate, buildRowTemplate, testRowTemplate, testDetailsTemplate) ->

  ProjectsController = (params) ->
    Bacon.$.ajax("/api/project").onValue (projects) ->
      context = { projects: projects}
      element = Handlebars.compile(template)(context)
      $('#content').html(element)

  BuildRowController = (build) ->
    context = 
      numOfBuilds: 'said'
    element = $(Handlebars.compile(buildRowTemplate)(_.merge(context, build)).trim())
    element.clickE().onValue () ->
      window.location = "#!/"+build.project+"/"+build.buildNumber

    element

  ProjectController = (params) ->
    project = params.project
    Bacon.combineAsArray(Bacon.$.ajax("/api/project/"+project), Bacon.$.ajax("/api/project/"+project+"/build")).onValues (project, builds) ->
      context = 
        numOfBuilds: builds.length
      element = $(Handlebars.compile(projectTemplate)(_.merge(context, project)))

      sortedBuilds = _.sortBy(builds, (build) -> -build.buildNumber )

      buildElements = _.map(sortedBuilds.slice(0, 100), BuildRowController)
      element.find('.builds').append(buildElements)
      $('#content').html(element)

  TestRowController = (test) ->
    context =
      showMarkAsOkButton: _.contains(['fail'], test.status)
      showMarkAsBadButton: _.contains(['good'], test.status)
      isNewTest: !test.images.reference

    element = $(Handlebars.compile(testRowTemplate)(_.merge(context, test)).trim())
   
    visibility = element.clickE().map ()-> !element.hasClass('selected')
    visibility.toProperty(false).assign(element, 'toggleClass', 'selected')
    TestDetailsController(element, test, visibility)

    createButton = (markedValue) ->
      buttonElement = element.find('.mark-button')
      clicks = buttonElement.clickE().map (e) ->
        e.stopPropagation()
        markedValue
      .flatMap () ->
        Bacon.$.ajaxPost("/api/project/"+test.project+"/build/"+test.buildNumber+"/tests/"+test.testName+"/"+markedValue)
      .onValue () ->
        location.reload()

    if context.showMarkAsBadButton then createButton('bad')
    if context.showMarkAsOkButton then createButton('good')

    return element

  TestDetailsController = (testRow, test, visibility) ->
    element = $(Handlebars.compile(testDetailsTemplate)(test).trim())
    visibility.where().not().truthy().onValue () -> element.remove()

    visibility.where().truthy().onValue () -> 
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
        element.find('button.'+selection).addClass('active')
        element.find('.frame .image').hide()
        element.find('.frame .' + selection).show()


  BuildController = (params) ->
    project = params.project
    build = params.build
    Bacon.combineAsArray(
        Bacon.$.ajax("/api/project/"+project), 
        Bacon.$.ajax("/api/project/"+project+"/build/"+build),
        Bacon.$.ajax("/api/project/"+project+"/build/"+build+"/tests")).onValues (project, build, tests) ->
      numOfFailed = _.filter(tests, (test) -> test.status == "fail").length
      context = 
        numOfFailed: numOfFailed
        numOfTests: tests.length
        showBuildCompleteButton: build.status == "created"
        projectDisplayName: project.displayName
      element = $(Handlebars.compile(buildTemplate)(_.merge(context, build)).trim())

      if context.showBuildCompleteButton
        element.find('.build-complete button').clickE().flatMap () ->
          Bacon.$.ajaxPost("/api/project/"+build.project+"/build/"+build.buildNumber+"/done")
        .onValue () ->
          location.reload()

      sortedTests = _.sortBy(tests, ['status', 'testName'])

      testRows = _.map sortedTests, (test) ->
        TestRowController(test)

      element.find('.tests').append(testRows)

      $('#content').html(element)
      #$("img.lazy").lazyload()


  router = Router({
    '!/:project/:build': BuildController
    '!/:project': ProjectController
    '!/': ProjectsController
    '!': ProjectsController
    '': ProjectsController
  })

  router.onValue (value) ->
    value.controller(value.params)
    window.scrollTo(0, 0)
