define ['text!templates/app.html'], (template)->
  console.log "JQUERY ", $.fn.jquery
  console.log "Lodash", _.VERSION
  console.log "Bacon", Bacon.version
  console.log "Handlers", Handlebars.VERSION
  console.log "TEMPLATE ", template

  context = { projects: []}
  element = Handlebars.compile(template)(context)

  $('#content').html(element)