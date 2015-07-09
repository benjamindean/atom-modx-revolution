modxComponentGeneratorView = require './modx-scaffold-view'

module.exports =

    activate: ->
        @view = new modxComponentGeneratorView()

    deactivate: ->
        @view?.destroy()
