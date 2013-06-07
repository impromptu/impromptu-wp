async = require 'async'
path = require 'path'
fs = require 'fs'
_ = require 'underscore'

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

  # Usage
  #
  # section 'wp:WP_DEBUG',
  #   content: wp._configConstants
  #   when: wp.isWP
  #   format: (constants) ->
  #     constants.WP_DEBUG
  register '_configConstants',
    update: (done) ->
      wp.root (err, wpRoot) ->
        return done err, false unless wpRoot

        fs.readFile "#{wpRoot}/wp-config.php", (err, data) ->
          lines = data.toString().split('\n')

          async.map lines, (line, cb) ->
            matches = line.match /^define\(('|")([^'"]+)\1,\s+('|")?([^'"]*)\1?\);/
            return cb null, false unless matches

            cb null, [matches[2], matches[4]]

          , (err, matches) ->

            async.filter matches, (match, cb) ->
              cb !!match

            , (keyValMatches) ->
              done null, _.object keyValMatches
