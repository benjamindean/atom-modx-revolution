path = require 'path'
_ = require 'underscore-plus'
{$, TextEditorView, View} = require 'atom-space-pen-views'
fsp = require './fs'
fs = require 'fs-plus'

module.exports =
class modxComponentGeneratorView extends View
    previouslyFocusedElement: null
    mode: null

    @content: ->
        @div class: 'modx-generator', =>
            @subview 'miniEditor', new TextEditorView(mini: true)
            @div class: 'error', outlet: 'error'
            @div class: 'message', outlet: 'message'

    initialize: ->
        @commandSubscription = atom.commands.add 'atom-workspace',
            'modx-generator:scaffold-transport-package': => @attach('component'),
            'modx-generator:scaffold-theme': => @attach('theme')

        @miniEditor.on 'blur', => @close()
        atom.commands.add @element,
            'core:confirm': => @confirm()
            'core:cancel': => @close()

    destroy: ->
        @panel?.destroy()
        @commandSubscription.dispose()

    attach: (@mode) ->
        @panel ?= atom.workspace.addModalPanel(item: this, visible: false)
        @previouslyFocusedElement = $(document.activeElement)
        @panel.show()
        @message.text("Enter #{mode} path")
        if @mode is "component"
            @setPathText("my-component")
        else
            @setPathText("my-theme")
        @miniEditor.focus()

    setPathText: (placeholderName, rangeToSelect) ->
        editor = @miniEditor.getModel()
        rangeToSelect ?= [0, placeholderName.length]
        packagesDirectory = @getComponentsDirectory()
        editor.setText(path.join(packagesDirectory, placeholderName))
        pathLength = editor.getText().length
        endOfDirectoryIndex = pathLength - placeholderName.length
        editor.setSelectedBufferRange([[0, endOfDirectoryIndex + rangeToSelect[0]], [0, endOfDirectoryIndex + rangeToSelect[1]]])

    close: ->
        return unless @panel.isVisible()
        @panel.hide()
        @previouslyFocusedElement?.focus()

    confirm: ->
        if @validComponentPath()
            @createComponentFiles =>
                componentPath = @getComponentPath()
                atom.open(pathsToOpen: [componentPath])
                @close()

    getComponentPath: ->
        ComponentPath = fs.normalize(@miniEditor.getText().trim())
        ComponentName = _.dasherize(path.basename(ComponentPath))
        path.join(path.dirname(ComponentPath), ComponentName)

    getComponentsDirectory: ->
        atom.config.get('core.projectHome') or path.join(fs.getHomeDirectory(), 'github')

    validComponentPath: ->
        if fs.existsSync(@getComponentPath())
            @error.text("Path already exists at '#{@getComponentPath()}'")
            @error.show()
            false
        else
            true

    initComponent: (componentPath, templatePath, callback) ->
        fsp.cp(templatePath, componentPath)
        callback()

    createComponentFiles: (callback) ->
        ComponentPath = @getComponentPath()
        packagesDirectory = @getComponentsDirectory()
        templatePath = path.resolve(__dirname, '..', 'templates', @mode)
        @initComponent(ComponentPath, templatePath, callback)
