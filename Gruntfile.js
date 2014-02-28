module.exports = function(grunt) {
  var src = "public"
  var targetDir = "build"
  var target = targetDir + "/"
  var targetCss = target + "/css/styles.css"
  var buildIdFile = target + "/build-id.txt"

  var testVersion = process.env.NODE_ENV == "test";
  var testFiles = {}

  var config = {
    meta: {
      banner: "/*! v<%= meta.version %> - <%= grunt.template.today('yyyy-mm-dd') %"
    },
    build: {
      dest: target
    },
    clean: {
      target: [target],
      options: {
        force: true
      }
    },

    copy: {
      main: {
        files: [
          { expand: true, cwd: src, src: "index.html", dest: target },
          { expand: true, cwd: src, src: "fonts/**", dest: target  },
          { expand: true, cwd: src, src: "js/**", dest: target  },
          { expand: true, cwd: src, src: "images/**", dest: target },
          { expand: true, cwd: src, src: "components/**", dest: target },
        ]
      },
      test: {
       files: testFiles
      }
    },

    less: {
      production: {
        options: {
          paths: [src, src + '/less']
        },
        files: {
          "<%= build.dest %>/css/styles.css": src + "/less/styles.less"
        }
      }
    },
    requirejs: {
      js: {
        options: {
          optimize: "uglify",
          baseUrl: src + "/js",
          out: target + "/js/Bootstrap.js",
          mainConfigFile: src + "/js/Bootstrap.js",
          name: "Bootstrap"
        }
      },
      css: {
        options: {
          cssIn: targetCss,
          out: targetCss
        }
      }
    },
  }

  grunt.initConfig(config);

  // Ready-made tasks
  grunt.loadNpmTasks("grunt-contrib-copy")
  grunt.loadNpmTasks("grunt-contrib-less")
  grunt.loadNpmTasks("grunt-image-embed")
  grunt.loadNpmTasks("grunt-contrib-requirejs")
  grunt.loadNpmTasks("grunt-contrib-clean")
  grunt.loadNpmTasks('grunt-contrib-jshint');

  grunt.registerTask('prepare', ['clean'])
  grunt.registerTask('package', ["copy", "less", "requirejs"])

  grunt.registerTask("default", ['prepare', 'package'])
}
