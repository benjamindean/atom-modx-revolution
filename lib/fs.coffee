_ = require 'underscore-plus'
fs = require 'fs-plus'
ncp = require 'ncp'
wrench = require 'wrench'

fsAdditions =
    cp: (sourcePath, destinationPath, callback) ->
        ncp(sourcePath, destinationPath)
        callback()

module.exports = _.extend({}, fs, fsAdditions)
