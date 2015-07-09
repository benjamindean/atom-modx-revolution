_ = require 'underscore-plus'
fs = require 'fs-plus'
ncp = require 'ncp'
wrench = require 'wrench'

fsAdditions =
  list: (directoryPath) ->
    if fs.isDirectorySync(directoryPath)
      try
        fs.readdirSync(directoryPath)
      catch e
        []
    else
      []

  listRecursive: (directoryPath) ->
    wrench.readdirSyncRecursive(directoryPath)

  cp: (sourcePath, destinationPath) ->
    ncp(sourcePath, destinationPath)

module.exports = _.extend({}, fs, fsAdditions)
