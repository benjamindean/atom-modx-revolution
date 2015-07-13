_ = require 'underscore-plus'
fs = require 'fs-plus'
ncp = require 'ncp'

fsAdditions =
    cp: (sourcePath, destinationPath, callback) ->
        ncp(sourcePath, destinationPath)
        callback()

module.exports = _.extend({}, fs, fsAdditions)
