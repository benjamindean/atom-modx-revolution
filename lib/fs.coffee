_ = require 'underscore-plus'
fs = require 'fs-plus'
ncp = require 'ncp'
wrench = require 'wrench'

fsAdditions =
  cp: (sourcePath, destinationPath) ->
    ncp(sourcePath, destinationPath)

module.exports = _.extend({}, fs, fsAdditions)
