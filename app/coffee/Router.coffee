define [], ()->
  Router = (routes) ->
    simrou = new Simrou()
    routeBus = new Bacon.Bus()

    _.forIn routes, (controller, route) ->
      simrou.addRoute(route).get (event, params) ->
        routeBus.push {
          controller: controller
          params: params 
        }

    hash = () ->
      getHash = ->
        (if !!document.location.hash then document.location.hash else "!/")
      $(window).asEventStream("hashchange").map(getHash).toProperty(getHash()).skipDuplicates()

    hash().onValue (r) ->
      console.log "onval ", r
      simrou.navigate(r);

    routeBus