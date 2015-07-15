{$, TextEditorView, View} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'
{BufferedProcess} = require 'atom'
_ = require 'underscore-plus'
fs = require 'fs-plus'
fsp = require './fs'
path = require 'path'

module.exports =
class modxInstallView extends View

    previouslyFocusedElement: null

    @content: ->
        @div class: 'modx-revolution', =>
            @div class: 'block', =>
                @div "Enter installation path", class: 'message', outlet: 'messagePath'
                @subview 'inputPath', new TextEditorView(mini: true)
                @div class: 'error text-error', style: "display:none", outlet: 'errorPath'
            @div class: 'block btn-toolbar', =>
                @div "Confirm", class: 'btn btn-success', outlet: 'confirmBtn'
                @div "Close", class: 'btn', outlet: 'cancelBtn'

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
        if fs.makeTreeSync(@getInstallPath())
            atom.notifications.add 'info', 'MODX Installation',
                detail: 'MODX Installation is now in progress.\nSuccess message will appear when it\'s done.'
                dismissable: true

    dismissNotification: (message) =>
        atom.notifications.getNotifications().forEach (notification) =>
            if notification.message is message
                notification.dismiss()

    done: ->
        installPath = @getInstallPath()
        @dismissNotification("MODX Installation")

        atom.notifications.add 'success', 'MODX installation finished.',
            buttons: [{
                text: 'Run Build'
                className: 'btn-warning'
                onDidClick: =>
                    @runBuild(installPath)
            },{
                text: 'Open in New Window'
                className: 'btn-success'
                onDidClick: =>
                    atom.open(pathsToOpen: [installPath])
                    @dismissNotification("MODX installation finished.")
            }]
            dismissable: true

    confirm: ->
        if @validInstallPath()
            @inProgress()
            @callForGit =>
                @config()
                @done()

    getInstallPath: ->
        InstallPath = fs.normalize(@inputPath.getText().trim())
        ComponentName = _.dasherize(path.basename(InstallPath))
        path.join(path.dirname(InstallPath), ComponentName)

    getComponentsDirectory: ->
        if process.platform is 'linux'
            '/var/www'
        else if process.platform is 'darwin'
            path.join(fs.getHomeDirectory(), 'sites')
        else if process.platform is 'win32'
            path.join(fs.getHomeDirectory(), 'wamp')

    validInstallPath: ->
        if fs.existsSync(@getInstallPath())
            @errorPath.text("Path already exists at '#{@getInstallPath()}'")
            @errorPath.show()
            false
        else
            true

    installModx: (installPath, callback) ->
        fs.makeTreeSync(installPath)
        dismiss = @dismissNotification
        command = 'git'
        args = ['clone', 'http://github.com/modxcms/revolution.git', installPath]
        stdout = (output) -> atom.notifications.add 'warning', output
        exit = (code) -> callback()
        process = new BufferedProcess({command, args, stdout, exit})
        process.onWillThrowError((error) ->
            atom.notifications.add 'error', error
            dismiss("MODX Installation"))

    installCLI: (installPath) ->
        dismiss = @dismissNotification
        command = 'php'
        args = [path.join(installPath, 'setup/index.php'), '--installmode=new']
        stdout = (output) -> atom.notifications.add 'warning', output
        exit = (code) ->
            dismiss("MODX Installation")
            atom.notifications.add 'success', 'Install finished.'
        process = new BufferedProcess({command, args, stdout, exit})
        process.onWillThrowError((error) ->
            atom.notifications.add 'error', error
            dismiss("MODX Installation"))

    checkBuild: (buildPath) ->
        fs.existsSync(buildPath)

    showConfig: ->
        file = path.join(@getInstallPath(), 'setup/config.xml')
        atom.workspace
            .open(file, searchAllPanes: true)
            .done (textEditor) =>
                pane = atom.workspace.paneForURI(file)
                options = { copyActiveItem: true }
                pane.splitLeft options
                textEditor.destroy()
                @disposable = new CompositeDisposable
                @disposable.add pane.getActiveEditor().onDidSave => @installCLI()
                @disposable.add pane.getActiveEditor().onDidDestroy => @disposable.dispose()

    config: ->
        buildPath = path.join(@getInstallPath(), '_build/')
        buildConf = buildPath + 'build.config.php'
        buildProp = buildPath + 'build.properties.php'
        configPath = path.join(@getInstallPath(), 'setup/')
        config = configPath + 'config.xml'

        fs.copy(buildPath + 'build.config.sample.php', buildConf)
        fs.copy(buildPath + 'build.properties.sample.php', buildProp)
        fs.copy(configPath + 'config.dist.new.xml', config)

        @fixPermissions(@getInstallPath())
        @showConfig()

    fixPermissions: (installPath) ->
        if process.platform is 'linux' or 'darwin'
            fsp.chmod(installPath, '777')

    runBuild: (installPath) ->
        dismiss = @dismissNotification
        check = @checkBuild
        atom.notifications.add 'info', 'Build in progress...',
            dismissable: true
        command = 'php'
        args = [path.join(installPath, '_build/transport.core.php')]
        stdout = (output) -> console.log output
        exit = (code) ->
            dismiss("Build in progress...")
            if check(path.join(installPath, 'core/packages/core.transport.zip'))
                atom.notifications.add 'success', 'Build done.'
            else
                atom.notifications.add 'error', 'core.transport.zip not found.'
        process = new BufferedProcess({command, args, stdout, exit})
        process.onWillThrowError((error) ->
            dismiss("Build in progress...")
            dismiss("MODX installation")
            atom.notifications.add 'error', error)

    callForGit: (callback) ->
        installPath = @getInstallPath()
        @installModx(installPath, callback)
