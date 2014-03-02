define [], ()->
  Router = () ->
    simrou = new Simrou()
    routeBus = new Bacon.Bus()

    addRoute = (routeKey, route) ->
      simrou.addRoute(route).get (event, params) ->
        routeBus.push {
          route: routeKey
          params: params 
        }

    hash = () ->
      getHash = ->
        (if !!document.location.hash then document.location.hash else "!/")
      $(window).asEventStream("hashchange").map(getHash).toProperty(getHash())
      .skipDuplicates()

    hash().onValue (r) ->
      simrou.navigate(r);

    api = 
      addRoute: addRoute
      router: routeBus