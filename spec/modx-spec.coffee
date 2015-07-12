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
      packageName = "modx-transport-package"
      packagePath = path.join(packageRoot, packageName)
      fs.removeSync(packageRoot)

    afterEach ->
      fs.removeSync(packageRoot)

    describe 'when creating a package', ->
      it "scaffolds a package and opens it", ->
        executeCommand ->
          atom.commands.dispatch(workspaceElement, "package-generator:generate-package")
          packageGeneratorView = $(workspaceElement).find(".modx-generator").view()
          expect(packageGeneratorView.hasParent()).toBeTruthy()
          packageGeneratorView.miniEditor.setText(packagePath)
          atom.commands.dispatch(packageGeneratorView.element, "core:confirm")
          waitsFor ->
            atom.open.callCount is 1
          expect(atom.open.callCount).toBe 1
