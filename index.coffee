async = require 'async'
path = require 'path'
fs = require 'fs'

module.exports = (Impromptu, register, wp) ->
  register 'isWP',
    update: (done) ->
      wp.root (err, root) ->
        done err, !!root

  register 'root',
    update: (done) ->
      paths = []
      directory = path.resolve()

      until path.resolve(directory) is '/'
        paths.push directory
        directory = path.dirname directory

      async.detect paths, (path, cb) ->
        fs.exists "#{path}/wp-config.php", (wpDirectory) ->
          cb wpDirectory
      , (result) ->
        done null, result

  register 'version',
    update: (done) ->
      wp.root (err, wpRoot) ->
        return done err, false unless wpRoot
        versionFile = path.join wpRoot, 'wp-includes/version.php'
        fs.readFile "#{wpRoot}/wp-includes/version.php", (err, data) ->
          version = data.toString().match /\$wp_version = '([^']+)';/;
          done err, version.pop()
