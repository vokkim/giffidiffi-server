requirejs.config
	baseUrl: './js'
	paths:
		'lodash': '../components/lodash/dist/lodash'
		'jquery': '../components/jquery/jquery'
		'bacon': '../components/bacon/dist/bacon'
		'bacon.jquery': '../components/bacon.jquery/dist/bacon.jquery'
		'templates': 	'../templates'

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

require ['jquery', 'lodash', 'bacon', 'bacon.jquery'], ->

	require ['ClientApp'], (App) ->
		console.log "Initialized!"
