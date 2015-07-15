_ = require 'underscore-plus'
fs = require 'fs-plus'
ncp = require 'ncp'
wrench = require 'wrench'

fsAdditions =
    cp: (sourcePath, destinationPath, callback) ->
        ncp(sourcePath, destinationPath)
        callback()
    chmod: (path, mod) ->
        wrench.chmodSyncRecursive(path, mod)

module.exports = _.extend({}, fs, fsAdditions)
