fileHTMLRewriter = ({regex, snippet})->
  excludeList = [".woff", ".js", ".css", ".ico"]

  acceptsHtmlExplicit = (req)->
    accept = req.headers["accept"]
    return false unless accept
    return (~accept.indexOf("html"))

  isExcluded = (req)->
    url = req.url
    excluded = false
    return true unless url

    excludeList.forEach (exclude)->
      if ~url.indexOf(exclude)
        excluded = true
    return excluded

  return (req, res, next)->
    write = res.write

    # Select just html file
    if !acceptsHtmlExplicit(req) or isExcluded(req)
          return next()

    res.write = (string, encoding)->
      body = if string instanceof Buffer then string.toString() else string
      body = body.replace regex, snippet

      if string instanceof Buffer
        string = new Buffer(body)
      else
        string = body

      unless this.headerSent
        this.setHeader 'content-length', Buffer.byteLength(body)+snippet.lenght
        this._implicitHeader()

      write.call(res, string, encoding)

    next()

module.exports = (grunt)->

  grunt.loadNpmTasks('grunt-contrib-clean')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-less')
  grunt.loadNpmTasks('grunt-contrib-concat')
  grunt.loadNpmTasks('grunt-contrib-copy')
  grunt.loadNpmTasks('grunt-contrib-cssmin')
  grunt.loadNpmTasks('grunt-contrib-htmlmin')
  grunt.loadNpmTasks('grunt-contrib-imagemin')
  grunt.loadNpmTasks('grunt-contrib-uglify')
  grunt.loadNpmTasks('grunt-contrib-requirejs')
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-open')
  grunt.loadNpmTasks('grunt-usemin')
  grunt.loadNpmTasks('grunt-coffeecov')
  grunt.loadNpmTasks('grunt-express-server')

  # configurable paths
  yeomanConfig = {
    app: 'app'
    src: 'app'
    server: 'server'
    dist: 'dist'

    tmp: '.tmp'
    tmp_dist: '.tmp-dist'

    livereload_port: 35729
  }

  try
    yeomanConfig.app = require('./bower.json').appPath || yeomanConfig.app
  catch e
  
  #
  # Grunt configuration:
  #
  # https://github.com/cowboy/grunt/blob/master/docs/getting_started.md
  #
  grunt.initConfig

    # Project configuration
    # ---------------------
    yeoman: yeomanConfig
    watch:
      options:
        interrupt: true
        livereload: yeomanConfig.livereload_port

      coffee:
        files: ['<%= yeoman.app %>/coffee/{,**/}*.coffee']
        tasks: ['coffee:dist']
      
      less:
        files: ['<%= yeoman.src %>/less/{,**/}*.less']
        tasks: ['less:server']

      express:
        files:  [ '<%= yeoman.server %>/{,**/}*.coffee' ]
        tasks:  [ 'express:server' ]
        options:
          spawn: false

      files:
        files: [
          '<%= yeoman.tmp %>/{,**/}*.{css,js}'
          '<%= yeoman.app %>/{,**/}*.html'
          '<%= yeoman.app %>/css/{,**/}*.css'
          '<%= yeoman.app %>/coffee/{,**/}*.coffee'
          '<%= yeoman.app %>/images/{,**/}*.{png,jpg,jpeg}'
          '!<%= yeoman.app %>/components/**'
        ]
        tasks: []

    express: 
      options: 
        cmd: 'coffee'
        port: 3000
        script: 'index.coffee'
      server: 
        options:
          node_env: 'development'
      dist: 
        options:
          node_env: 'production'
    open:
      server:
        path: 'http://localhost:<%= express.options.port %>'
      dist:
        path: 'http://localhost:<%= express.options.port %>'
      
    clean:
      dist: ['<%= yeoman.dist %>']
      tmp: ['<%= yeoman.tmp %>']
      tmp_dist: ['<%= yeoman.tmp_dist %>']
      components: ['<%= yeoman.dist %>/components']
      templates: ['<%= yeoman.dist %>/templates']
      spec: ['<%= yeoman.dist %>/js/spec']

    coffee:
      dist:
        expand: true
        cwd: '<%= yeoman.src %>/coffee/'
        src: ['**/*.coffee']
        dest: '<%= yeoman.tmp %>/js'
        ext: '.js'

    coffeecov:
      options:
        path: 'relative'
      dist:
        src: '<%= yeoman.src %>/coffee/app'
        dest: '<%= yeoman.tmp %>/js/app'

    less:
      server:
        options:
          dumpLineNumbers: 'all'
        files:
            '<%= yeoman.tmp %>/css/all-less.css' : '<%= yeoman.app %>/less/app.less'

      dist:
        options:
          compress: true
          yuicompress: true
        files:
            '<%= yeoman.tmp %>/css/all-less.css' : '<%= yeoman.app %>/less/app.less'

    copy:
      dist:
        files: [
          { expand: true, cwd: '<%= yeoman.tmp %>/components', src: ['**'], dest: '<%= yeoman.dist %>/components' }
          { expand: true, cwd: '<%= yeoman.tmp %>/', src: ['**'], dest: '<%= yeoman.tmp_dist %>/' }
          { expand: true, cwd: '<%= yeoman.app %>/', src: ['**'], dest: '<%= yeoman.tmp_dist %>/' }
        ]

    useminPrepare:
      html: '<%= yeoman.tmp_dist %>/index.html'
      options:
        dest: '<%= yeoman.dist %>'

    usemin:
      html: ['<%= yeoman.dist %>/{,*/}*.html']
      css: ['<%= yeoman.dist %>/css/{,*/}*.css']
      options:
        dirs: ['<%= yeoman.dist %>']

    imagemin:
      dist:
        files: [{
          expand: true,
          cwd: '<%= yeoman.app %>/images'
          src: '{,*/}*.{png,jpg,jpeg}'
          dest: '<%= yeoman.dist %>/images'
        }]

    htmlmin:
      dist:
        # options:
        #   removeCommentsFromCDATA: true
        #   # https://github.com/yeoman/grunt-usemin/issues/44
        #   collapseWhitespace: true
        #   collapseBooleanAttributes: true
        #   removeAttributeQuotes: true
        #   removeRedundantAttributes: true
        #   useShortDoctype: true
        #   removeEmptyAttributes: true
        #   removeOptionalTags: true

        files: [{
          expand: true,
          cwd: '<%= yeoman.app %>',
          src: ['*.html', 'templates/*.html'],
          dest: '<%= yeoman.dist %>'
        }]

    uglify:
      dist:
        files: [{
          expand: true,
          cwd: '<%= yeoman.dist %>/js',
          src: '**/*.js',
          dest: '<%= yeoman.dist %>/js'
        }]

    requirejs:
      compile:
        options:
          baseUrl: '<%= yeoman.tmp_dist %>/js/'
          #wrap: true
          #removeCombined: true
          #keepBuildDir: true
          #inlineText: true
          mainConfigFile: '<%= yeoman.tmp_dist %>/js/main.js'
          optimize: "none"
          name: "main"
          out: "<%= yeoman.dist %>/js/main.js"
         

  grunt.registerTask('server', [
    'coffee:dist'
    'less:server'
    'express:server'
    'open:server'
    'watch'
  ])

  grunt.registerTask('server-dist', [
    'build'
    'express:dist'
    'open:dist'
    'watch:files'
  ])

  grunt.registerTask('compile', [
    'coffee:dist'
    'less:server'
    'less:dist'
  ])

  grunt.registerTask('build', [
    'clean:dist'
    'clean:tmp'
    'clean:tmp_dist'
    'coffee'
    'less:dist'
    'copy:dist'
    'requirejs:compile'
    'useminPrepare'
    'imagemin'
    'htmlmin'
    'concat'
    'usemin'
    'cssmin'
    'clean:tmp_dist'
    'clean:components'
    'clean:templates'
    'clean:spec'
    #'uglify'
  ])

  grunt.registerTask('default', ['build'])
