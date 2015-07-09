modxComponentGeneratorView = require './modx-generator-view'

module.exports =
    config:
        autror:
            default: process.env.GITHUB_USER or 'atom'
            type: 'string'
        autrorEmail:
            default: 'atom@atom.com'
            type: 'string'

    activate: ->
        @view = new modxComponentGeneratorView()

    deactivate: ->
        @view?.destroy()
