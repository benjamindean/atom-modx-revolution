modxComponentGeneratorView = require './modx-component-generator-view'

module.exports =
    activate: ->
        @view = new modxComponentGeneratorView()

    deactivate: ->
        @view?.destroy()
