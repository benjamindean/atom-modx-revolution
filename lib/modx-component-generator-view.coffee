path = require 'path'
_ = require 'underscore-plus'
{$, TextEditorView, View} = require 'atom-space-pen-views'
{BufferedProcess} = require 'atom'
fsp = require './fs'
fs = require 'fs-plus'

module.exports =
class modxComponentGeneratorView extends View
  previouslyFocusedElement: null
  mode: null

  @content: ->
    @div class: 'modx-component-generator', =>
      @subview 'miniEditor', new TextEditorView(mini: true)
      @div class: 'error', outlet: 'error'
      @div class: 'message', outlet: 'message'

  initialize: ->
    @commandSubscription = atom.commands.add 'atom-workspace',
      'modx-component-generator:generate-component': => @attach('component')

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
    @setPathText("my-component")
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
        ComponentPath = @getComponentPath()
        atom.open(pathsToOpen: [ComponentPath])
        @close()

  getComponentPath: ->
    ComponentPath = fs.normalize(@miniEditor.getText().trim())
    ComponentName = _.dasherize(path.basename(ComponentPath))
    path.join(path.dirname(ComponentPath), ComponentName)

  getComponentsDirectory: ->
    atom.config.get('core.projectHome') or
    path.join(fs.getHomeDirectory(), 'github')

  validComponentPath: ->
    if fs.existsSync(@getComponentPath())
      @error.text("Path already exists at '#{@getComponentPath()}'")
      @error.show()
      false
    else
      true

  initPackage: (componentPath, templatePath, componentName, callback) ->
    componentName ?= path.basename(componentPath)
    componentAuthor = atom.config.get('modx-component-generator.author') or process.env.GITHUB_USER or 'atom'

    fs.makeTreeSync(componentPath)

    for childPath in fsp.listRecursive(templatePath)
      templateChildPath = path.resolve(templatePath, childPath)
      relativePath = templateChildPath.replace(templatePath, "")
      relativePath = relativePath.replace(/^\//, '')
      relativePath = relativePath.replace(/\.template$/, '')
      relativePath = @replacecomponentNamePlaceholders(relativePath, componentName)

      sourcePath = path.join(componentPath, relativePath)
      continue if fs.existsSync(sourcePath)
      if fs.isDirectorySync(templateChildPath)
        fs.makeTreeSync(sourcePath)
      else if fs.isFileSync(templateChildPath)
        fs.makeTreeSync(path.dirname(sourcePath))
        contents = fs.readFileSync(templateChildPath).toString()
        contents = @replacecomponentNamePlaceholders(contents, componentName)
        contents = @replacecomponentAuthorPlaceholders(contents, componentAuthor)
        fs.writeFileSync(sourcePath, contents)
        callback()

  replacecomponentAuthorPlaceholders: (string, componentAuthor) ->
    string.replace(/__component-author__/g, componentAuthor)

  replacecomponentNamePlaceholders: (string, componentName) ->
    placeholderRegex = /__(?:(component-name)|([cC]omponentName)|(component))__/g
    string = string.replace placeholderRegex, (match, dash, camel, underscore) =>
      if dash
        @dasherize(componentName)
      else if camel
        if /[a-z]/.test(camel[0])
          componentName = componentName[0].toLowerCase() + componentName[1...]
        else if /[A-Z]/.test(camel[0])
          componentName = componentName[0].toUpperCase() + componentName[1...]
        @camelize(componentName)

      else if underscore
        @underscore(componentName)

  dasherize: (string) ->
    string = string[0].toLowerCase() + string[1..]
    string.replace /([A-Z])|(_)/g, (m, letter, underscore) ->
      if letter
        "-" + letter.toLowerCase()
      else
        "-"

  camelize: (string) ->
    string.replace /[_-]+(\w)/g, (m) -> m[1].toUpperCase()

  underscore: (string) ->
    string = string[0].toLowerCase() + string[1..]
    string.replace /([A-Z])|(-)/g, (m, letter, dash) ->
      if letter
        "_" + letter.toLowerCase()
      else
        "_"

  createComponentFiles: (callback) ->
    ComponentPath = @getComponentPath()
    packagesDirectory = @getComponentsDirectory()
    templatePath = path.resolve(__dirname, '..', 'templates', @mode)
    @initPackage(ComponentPath, templatePath, @componentName, callback)


  runCommand: (command, args, exit) ->
    new BufferedProcess({command, args, exit})