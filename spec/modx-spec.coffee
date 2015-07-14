path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
{$} = require 'atom-space-pen-views'

describe 'MODX Revolution', ->
    [activationPromise, workspaceElement] = []

    executeCommand = (callback) ->
        atom.commands.dispatch(workspaceElement, 'modx-revolution:scaffold-transport-package')
        atom.commands.dispatch(workspaceElement, 'modx-revolution:scaffold-theme')
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

    describe "when modx-revolution:scaffold-transport-package is triggered", ->
        it "displays a miniEditor with the correct text and selection", ->
            executeCommand ->
                atom.commands.dispatch(workspaceElement, "modx-revolution:scaffold-transport-package")
                modxGeneratorView = $(workspaceElement).find(".modx-revolution").view()
                componentName = modxGeneratorView.miniEditor.getModel().getSelectedText()
                expect(componentName).toEqual 'my-component'

                fullPath = modxGeneratorView.miniEditor.getModel().getText()
                base = atom.config.get 'core.projectHome'
                expect(fullPath).toEqual path.join(base, 'my-component')

    describe "when modx-revolution:scaffold-theme is triggered", ->
        it "displays a miniEditor with the correct text and selection", ->
            executeCommand ->
                atom.commands.dispatch(workspaceElement, "modx-revolution:scaffold-theme")
                modxGeneratorView = $(workspaceElement).find(".modx-revolution").view()
                componentName = modxGeneratorView.miniEditor.getModel().getSelectedText()
                expect(componentName).toEqual 'my-theme'

                fullPath = modxGeneratorView.miniEditor.getModel().getText()
                base = atom.config.get 'core.projectHome'
                expect(fullPath).toEqual path.join(base, 'my-theme')

    describe "when core:cancel is triggered", ->
        it "detaches from the DOM and focuses the the previously focused element", ->
            executeCommand ->
                jasmine.attachToDOM(workspaceElement)
                atom.commands.dispatch(workspaceElement, "modx-revolution:scaffold-transport-package")

                modxGeneratorView = $(workspaceElement).find(".modx-revolution").view()
                expect(modxGeneratorView.miniEditor.element).toBe document.activeElement

                atom.commands.dispatch(modxGeneratorView.element, "core:cancel")
                expect(modxGeneratorView.panel.isVisible()).toBeFalsy()

    describe "when a component is generated", ->
        [componentName, componentPath, componentRoot] = []

        beforeEach ->
            spyOn(atom, "open")

            componentRoot = temp.mkdirSync('atom')
            componentName = "modx-some-component"
            componentPath = path.join(componentRoot, componentName)
            fs.removeSync(componentRoot)

        afterEach ->
            fs.removeSync(componentRoot)

        describe 'when creating a component', ->
            [modxExecute] = []

            simulate = (type, callback) ->
                if type is 'transport-package'
                    atom.commands.dispatch(workspaceElement, "modx-revolution:scaffold-transport-package")
                else
                    atom.commands.dispatch(workspaceElement, "modx-revolution:scaffold-theme")
                modxGeneratorView = $(workspaceElement).find(".modx-revolution").view()
                expect(modxGeneratorView.hasParent()).toBeTruthy()
                modxGeneratorView.miniEditor.setText(componentPath)
                modxExecute = spyOn(modxGeneratorView, 'initComponent').andCallFake (command, args, exit) ->
                    process.nextTick -> exit()
                atom.commands.dispatch(modxGeneratorView.element, "core:confirm")
                waitsFor ->
                    atom.open.callCount is 1

                runs callback

            it "scaffolds a package and opens it", ->
                executeCommand ->
                    simulate "transport-package", ->
                        expect(atom.open.callCount).toBe 1
                        expect(atom.open.argsForCall[0][0].pathsToOpen[0]).toBe componentPath

            it "scaffolds a theme and opens it", ->
                executeCommand ->
                    simulate "theme", ->
                        expect(atom.open.callCount).toBe 1
                        expect(atom.open.argsForCall[0][0].pathsToOpen[0]).toBe componentPath
