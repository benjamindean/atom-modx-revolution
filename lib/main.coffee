modxComponentGeneratorView = require './modx-component-generator-view'

module.exports =
    config:
        autror:
            default: process.env.GITHUB_USER or 'atom'
            type: 'string'

    activate: ->
        @view = new modxComponentGeneratorView()

    deactivate: ->
        @view?.destroy()
