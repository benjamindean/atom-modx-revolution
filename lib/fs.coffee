_ = require 'underscore-plus'
fs = require 'fs-plus'
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

module.exports = _.extend({}, fs, fsAdditions)
