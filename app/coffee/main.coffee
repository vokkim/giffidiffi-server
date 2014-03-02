requirejs.config
	baseUrl: './js'
	shim:
		'lodash':
			exports: '_'
		'jquery':
			exports: '$'
		'bacon':
			exports: 'Bacon'
		'handlebars':
		  deps: ['lodash', 'jquery']
			exports: 'Handlebars'
		'simrou':
			deps: ['jquery']
			exports: 'Simrou'

		'lazyload':
			deps: ['jquery']
			exports: '$'

		'bootstrap-affix': 		{ deps: ['jquery'], exports: '$' }
		'bootstrap-alert': 		{ deps: ['jquery'], exports: '$' }
		'bootstrap-button': 	{ deps: ['jquery'], exports: '$' }
		'bootstrap-carousel': 	{ deps: ['jquery'], exports: '$' }
		'bootstrap-collapse': 	{ deps: ['jquery'], exports: '$' }
		'bootstrap-dropdown': 	{ deps: ['jquery'], exports: '$' }
		'bootstrap-modal': 		{ deps: ['jquery'], exports: '$' }
		'bootstrap-popover': 	{ deps: ['jquery'], exports: '$' }
		'bootstrap-scrollspy': 	{ deps: ['jquery'], exports: '$' }
		'bootstrap-tab': 		{ deps: ['jquery'], exports: '$' }
		'bootstrap-tooltip': 	{ deps: ['jquery'], exports: '$' }
		'bootstrap-transition': { deps: ['jquery'], exports: '$' }
		'bootstrap-typeahead': 	{ deps: ['jquery'], exports: '$' }

		'modernizr':
			exports: 'Modernizr'

	paths:
		'lodash': '../components/lodash/dist/lodash'
		'jquery': '../components/jquery/jquery'
		'bacon': '../components/bacon/dist/bacon'
		'bacon.jquery': '../components/bacon.jquery/dist/bacon.jquery'
		'handlebars': '../components/handlebars/dist/handlebars'
		'simrou': '../components/simrou/build/simrou'
		'text' : '../components/requirejs-text/text'
		'lazyload' : '../components/jquery.lazyload/jquery.lazyload'
		'templates': '../templates'

		'bootstrap-affix': 		'../components/bootstrap/js/bootstrap-affix'
		'bootstrap-alert': 		'../components/bootstrap/js/bootstrap-alert'
		'bootstrap-button': 	'../components/bootstrap/js/bootstrap-button'
		'bootstrap-carousel': 	'../components/bootstrap/js/bootstrap-carousel'
		'bootstrap-collapse': 	'../components/bootstrap/js/bootstrap-collapse'
		'bootstrap-dropdown': 	'../components/bootstrap/js/bootstrap-dropdown'
		'bootstrap-modal': 		'../components/bootstrap/js/bootstrap-modal'
		'bootstrap-popover': 	'../components/bootstrap/js/bootstrap-popover'
		'bootstrap-scrollspy':	'../components/bootstrap/js/bootstrap-scrollspy'
		'bootstrap-tab': 		'../components/bootstrap/js/bootstrap-tab'
		'bootstrap-tooltip': 	'../components/bootstrap/js/bootstrap-tooltip'
		'bootstrap-transition':	'../components/bootstrap/js/bootstrap-transition'
		'bootstrap-typeahead': 	'../components/bootstrap/js/bootstrap-typeahead'

require [
  'lodash'
  'jquery'
  'lazyload'
  'bacon'
  'bacon.jquery'
  'handlebars'
  'simrou'], () ->

  	require ['ClientApp'], () ->

