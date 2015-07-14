{$, TextEditorView, View} = require 'atom-space-pen-views'
{BufferedProcess} = require 'atom'
_ = require 'underscore-plus'
fs = require 'fs-plus'
path = require 'path'
replace = require 'replace'

module.exports =
class modxInstallView extends View
    previouslyFocusedElement: null

    @content: ->
        @div class: 'modx-revolution', =>
            @div class: 'block', =>
                @div "Enter installation path", class: 'message', outlet: 'messagePath'
                @subview 'inputPath', new TextEditorView(mini: true)
                @div class: 'error text-error', style: "display:none", outlet: 'errorPath'
            @div class: 'block', =>
                @div "MySQL Username", class: 'message', outlet: 'messageUsername'
                @subview 'inputUsername', new TextEditorView(mini: true)
                @div "MySQL Username must be defined", style: "display:none", class: 'error text-error', outlet: 'errorUsername'
            @div class: 'block', =>
                @div "MySQL Password", class: 'message', outlet: 'messagePassword'
                @subview 'inputPassword', new TextEditorView(mini: true)
                @div "MySQL Password must be defined", style: "display:none", class: 'error text-error', outlet: 'errorPassword'
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
        atom.notifications.add 'info', 'MODX Installation',
            detail: 'MODX Installation is now in progress. Success message will appear once it finishes.'
            dismissable: true

    dismissNotification: =>
        atom.notifications.getNotifications().forEach (notification) =>
            if notification.message.indexOf "MODX Installation" is 0
                notification.dismiss()

    done: ->
        installPath = @getInstallPath()
        @dismissNotification()

        atom.notifications.add 'success', 'MODX Installation finished.',
            #detail: 'Path: <i>#{installPath}</i>'
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
                    @dismissNotification()
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
        atom.config.get('core.projectHome') or
            process.env.ATOM_REPOS_HOME or
            path.join(fs.getHomeDirectory(), 'modx-revolution')

    validInstallPath: ->
        if fs.existsSync(@getInstallPath())
            @errorPath.text("Path already exists at '#{@getInstallPath()}'")
            @errorPath.show()
        else
            @errorPath.hide()
        if not @inputUsername.getText()
            @errorUsername.show()
        else
            @errorUsername.hide()
        if not @inputPassword.getText()
            @errorPassword.show()
        else
            @errorPassword.hide()
        not fs.existsSync(@getInstallPath()) and @inputUsername.getText() and @inputPassword.getText()

    installModx: (installPath, callback) ->
        dismiss = @dismissNotification
        command = 'git'
        args = ['clone', 'http://github.com/modxcms/revolution.git', installPath]
        stdout = (output) -> atom.notifications.add 'warning', output
        exit = (code) -> callback()
        process = new BufferedProcess({command, args, stdout, exit})
        process.onWillThrowError((error) -> dismiss())

    config: (installPath) ->

        username = @inputUsername.getText().trim()
        password = @inputPassword.getText().trim()
        buildPath = path.join(@getInstallPath(), '_build/')
        buildConf = buildPath + 'build.config.php'
        buildProp = buildPath + 'build.properties.php'

        fs.rename(buildPath + 'build.config.sample.php', buildConf)
        fs.rename(buildPath + 'build.properties.sample.php', buildProp)
        replace
            regex: "'XPDO_DB_USER', ''"
            replacement: "'XPDO_DB_USER', '#{username}'"
            paths: [ buildConf ]
        replace
            regex: "'XPDO_DB_PASS', ''"
            replacement: "'XPDO_DB_PASS', '#{password}'"
            paths: [ buildConf ]
        replace
            regex: "\['mysql_string_username'\]= ''"
            replacement: "['mysql_string_username']= '#{username}'"
            paths: [ buildProp ]
        replace
            regex: "\['mysql_string_password'\]= ''"
            replacement: "['mysql_string_password']= '#{password}'"
            paths: [ buildProp ]

    runBuild: (installPath) ->
        dismiss = @dismissNotification
        command = 'php'
        args = [path.join(installPath, '_build/transport.core.php')]
        stdout = (output) -> console.log output
        exit = (code) -> atom.notifications.add 'success', 'Build done'
        process = new BufferedProcess({command, args, stdout, exit})
        process.onWillThrowError((error) -> dismiss())

    callForGit: (callback) ->
        installPath = @getInstallPath()
        @installModx(installPath, callback)
