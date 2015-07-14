path = require 'path'
_ = require 'underscore-plus'
{$, TextEditorView, View} = require 'atom-space-pen-views'
{BufferedProcess} = require 'atom'
fsp = require './fs'
fs = require 'fs-plus'

module.exports =
class modxInstallView extends View
    previouslyFocusedElement: null

    @content: ->
        @div class: 'modx-revolution', =>
            @div class: 'error', outlet: 'errorPath'
            @div class: 'message', outlet: 'messagePath'
            @subview 'inputPath', new TextEditorView(mini: true)
            @div class: 'error', outlet: 'errorUsername'
            @div class: 'message', outlet: 'messageUsername'
            @subview 'inputUsername', new TextEditorView(mini: true)
            @div class: 'error', outlet: 'errorPassword'
            @div class: 'message', outlet: 'messagePassword'
            @subview 'inputPassword', new TextEditorView(mini: true)
            @div class: 'row', =>
                @div class: 'col-xs-12', =>
                    @div class: 'btn btn-toolbar pull-right', outlet: 'cancelBtn'
                    @div class: 'btn btn-success', outlet: 'confirmBtn'

    initialize: ->
        @commandSubscription = atom.commands.add 'atom-workspace',
            'modx-revolution:install-modx': => @attach()

        @confirmBtn.on 'click', => @confirm()
        @cancelBtn.on 'click', => @close()
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
        @confirmBtn.text("Confirm")
        @cancelBtn.text("Close")
        @messagePath.text("Enter installation path")
        @messageUsername.text("MYSQL username")
        @messagePassword.text("MYSQL password")
        @setPathText("modx")
        @inputPath.focus()

    setPathText: (placeholderName, rangeToSelect) ->
        editor = @inputPath.getModel()
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

    inProgress: ->
        @close()
        atom.notifications.add 'info', 'MODX Installation',
            detail: 'MODX Installation is now in progress. Success message will appear once it finishes.'
            dismissable: true

    dismissNotification: ->
        atom.notifications.getNotifications().forEach (notification) =>
            if notification.message.indexOf "MODX Installation" is 0
                notification.dismiss()

    done: ->
        installPath = @getInstallPath()
        @dismissNotification()

        atom.notifications.add 'success', 'MODX Installation finished',
            buttons: [{
                text: 'Open in new window'
                className: 'btn-success'
                onDidClick: =>
                    atom.open(pathsToOpen: [installPath])
                    @dismissNotification()
            },
            {
                text: 'Run Build'
                className: 'btn-warning'
                onDidClick: =>
                    @runBuild(installPath)
            }]
            dismissable: true

    confirm: ->
        if @validInstallPath()
            @inProgress()
            @callForGit =>
                @done()

    getInstallPath: ->
        InstallPath = fs.normalize(@inputPath.getText().trim())
        ComponentName = _.dasherize(path.basename(InstallPath))
        path.join(path.dirname(InstallPath), ComponentName)

    getComponentsDirectory: ->
        atom.config.get('core.projectHome') or
            process.env.ATOM_REPOS_HOME or
            path.join(fs.getHomeDirectory(), 'modx-revolution')

    validInstallPath: ->
        if fs.existsSync(@getInstallPath())
            @error.text("Path already exists at '#{@getInstallPath()}'")
            @error.show()
            false
        else
            true

    installModx: (installPath, callback) ->
        dismiss = @dismissNotification
        command = 'git'
        args = ['clone', 'http://github.com/modxcms/revolution.git', installPath]
        stdout = (output) -> atom.notifications.add 'warning', output
        exit = (code) -> callback()
        process = new BufferedProcess({command, args, stdout, exit})
        process.onWillThrowError((error) -> dismiss())



    runBuild: (installPath) ->
        dismiss = @dismissNotification
        command = 'php'
        args = [path.join(installPath, '_build/transport.core.php')]
        stdout = (output) -> atom.notifications.add 'warning', output
        exit = (code) -> console.log("ps -ef exited with #{code}")
        process = new BufferedProcess({command, args, stdout, exit})
        process.onWillThrowError((error) -> dismiss())

    callForGit: (callback) ->
        installPath = @getInstallPath()
        @installModx(installPath, callback)
