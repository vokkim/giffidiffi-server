requirejs.config({
  baseUrl: 'js',
  paths: {
    //'templates': '../templates',
    'components': '../components',
    'handlebars': '../components/handlebars/dist/handlebars',
    'lodash': '../components/lodash/dist/lodash',
    'jquery': '../components/jquery/jquery',
    'bacon': '../components/bacon.js/dist/Bacon',
    'bacon.jquery': '../components/bacon.jquery/dist/bacon.jquery',
  },
  shim: {
    "bacon": {
      deps: ["jquery"]
    },
    "bacon.jquery": {
      deps: ["bacon"]
    },
    "App": {
      deps: ["bacon.jquery"]
    },
    'handlebars': {
      exports: 'Handlebars'
    }
  }
})


;(function() {
  console.log("STARTED!")
}());