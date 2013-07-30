_ = require 'underscore'
npm = require "npm"
semver = require "semver"
_path = require 'path'
events = require 'events'
async = require 'async'

class Winky extends events.EventEmitter
  constructor: (@dir) ->

  load: (callback) ->
    @deps = {}
    @package = require _path.join @dir, 'package.json'
    for pkg, savedVersion of @package.dependencies
      @deps[pkg] = savedVersion:savedVersion
    #npm.load @package, (err) =>
    npm.load loglevel:'silent', (err) =>
      @emit 'error', err if err
      callback()


  findCurrentVersions: (callback) ->
    findVersion = (pkg, cb) =>
      npm.commands.view ["#{pkg}@latest", 'version'], (err, data) =>
        return cb err if err
        #Data will be of the form { VER_NUM: { 'version': VER_NUM } }
        for k, d of data
          @deps[pkg].latestVersion = d.version if d.version
        cb()

    async.each _.keys(@deps), findVersion, (err) =>
      @emit 'error', err if err
      callback?()

  findInstalledVersions: (callback) =>
    findVersion = (pkg, cb) =>
      pkgInfoPath = _path.join @dir, 'node_modules', pkg, 'package.json'
      pkgInfo = require pkgInfoPath
      @deps[pkg].installedVersion = pkgInfo.version
      cb()
      
    async.each _.keys(@deps), findVersion, (err) =>
      @emit 'error', err if err
      callback?()

module.exports = Winky
