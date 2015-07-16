modxComponentGeneratorView = require './modx-scaffold-view'
modxInstallView = require './modx-install-view'

module.exports =

    activate: ->
        @scaffoldView = new modxComponentGeneratorView()
        @installView = new modxInstallView()

    deactivate: ->
        @scaffoldView?.destroy()
        @installView?.destroy()
