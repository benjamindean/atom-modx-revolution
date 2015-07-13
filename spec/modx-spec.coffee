path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
{$} = require 'atom-space-pen-views'

describe 'MODX Revolution', ->
    [activationPromise, workspaceElement] = []

    executeCommand = (callback) ->
        atom.commands.dispatch(workspaceElement, 'modx-generator:scaffold-transport-package')
        atom.commands.dispatch(workspaceElement, 'modx-generator:scaffold-theme')
        waitsForPromise -> activationPromise
        runs(callback)

    beforeEach ->
        workspaceElement = atom.views.getView(atom.workspace)
        activationPromise = atom.packages.activatePackage('modx-revolution')

    describe "when modx grammar is triggered", ->
        it 'parses grammar', ->
            executeCommand ->
                grammar = atom.grammars.grammarForScopeName("text.html.modx")
                expect(grammar).toBeTruthy()
                expect(grammar.scopeName).toBe "text.html.modx"

    describe "when modx-generator:scaffold-transport-package is triggered", ->
        it "displays a miniEditor with the correct text and selection", ->
            executeCommand ->
                atom.commands.dispatch(workspaceElement, "modx-generator:scaffold-transport-package")
                modxGeneratorView = $(workspaceElement).find(".modx-generator").view()
                packageName = modxGeneratorView.miniEditor.getModel().getSelectedText()
                expect(packageName).toEqual 'my-component'

                fullPath = modxGeneratorView.miniEditor.getModel().getText()
                base = atom.config.get 'core.projectHome'
                expect(fullPath).toEqual path.join(base, 'my-component')

    describe "when modx-generator:scaffold-theme is triggered", ->
        it "displays a miniEditor with the correct text and selection", ->
            executeCommand ->
                atom.commands.dispatch(workspaceElement, "modx-generator:scaffold-theme")
                modxGeneratorView = $(workspaceElement).find(".modx-generator").view()
                packageName = modxGeneratorView.miniEditor.getModel().getSelectedText()
                expect(packageName).toEqual 'my-theme'

                fullPath = modxGeneratorView.miniEditor.getModel().getText()
                base = atom.config.get 'core.projectHome'
                expect(fullPath).toEqual path.join(base, 'my-theme')

    describe "when core:cancel is triggered", ->
        it "detaches from the DOM and focuses the the previously focused element", ->
            executeCommand ->
                jasmine.attachToDOM(workspaceElement)
                atom.commands.dispatch(workspaceElement, "modx-generator:scaffold-transport-package")

                modxGeneratorView = $(workspaceElement).find(".modx-generator").view()
                expect(modxGeneratorView.miniEditor.element).toBe document.activeElement

                atom.commands.dispatch(modxGeneratorView.element, "core:cancel")
                expect(modxGeneratorView.panel.isVisible()).toBeFalsy()

    describe "when a package is generated", ->
        [packageName, packagePath, packageRoot] = []

        beforeEach ->
            spyOn(atom, "open")

            packageRoot = temp.mkdirSync('atom')
            packageName = "modx-some-package"
            packagePath = path.join(packageRoot, packageName)
            fs.removeSync(packageRoot)

        afterEach ->
            fs.removeSync(packageRoot)

        describe 'when creating a package', ->
            [modxExecute] = []

            simulate = (type, callback) ->
                if type is 'package'
                    atom.commands.dispatch(workspaceElement, "modx-generator:scaffold-transport-package")
                else
                    atom.commands.dispatch(workspaceElement, "modx-generator:scaffold-theme")
                modxGeneratorView = $(workspaceElement).find(".modx-generator").view()
                expect(modxGeneratorView.hasParent()).toBeTruthy()
                modxGeneratorView.miniEditor.setText(packagePath)
                modxExecute = spyOn(modxGeneratorView, 'initComponent').andCallFake (command, args, exit) ->
                    process.nextTick -> exit()
                atom.commands.dispatch(modxGeneratorView.element, "core:confirm")
                waitsFor ->
                    atom.open.callCount is 1

                runs callback

            it "scaffolds a package and opens it", ->
                executeCommand ->
                    simulate "package", ->
                        expect(atom.open.callCount).toBe 1
                        expect(atom.open.argsForCall[0][0].pathsToOpen[0]).toBe packagePath

            it "scaffolds a theme and opens it", ->
                executeCommand ->
                    simulate "theme", ->
                        expect(atom.open.callCount).toBe 1
                        expect(atom.open.argsForCall[0][0].pathsToOpen[0]).toBe packagePath
