# MODX Revolution support in Atom

[![Build Status](https://travis-ci.org/benjamindean/atom-modx-revolution.svg?branch=master)](https://travis-ci.org/benjamindean/atom-modx-revolution)
[![Dependency Status](https://david-dm.org/benjamindean/atom-modx-revolution.svg)](https://david-dm.org/benjamindean/atom-modx-revolution)

[Atom.io](https://atom.io/packages/modx-revolution)  | [GitHub](https://github.com/benjamindean/atom-modx-revolution)

##Features

####Snippets

[Snippets](https://atom.io/packages/snippets) for [Template Tags](http://rtfm.modx.com/revolution/2.x/making-sites-with-modx/commonly-used-template-tags) in .html & .tpl, [modX](http://rtfm.modx.com/revolution/2.x/developing-in-modx/other-development-resources/class-reference/modx) and [xPDO](http://rtfm.modx.com/xpdo/1.x/class-reference/xpdo) Class methods in .php.

![MODX Class Snippets](https://cloud.githubusercontent.com/assets/5139993/8494629/3ec80d06-216f-11e5-8d22-581ac4c1b554.gif)

####Descriptions & Documentation links

Each [modX](http://rtfm.modx.com/revolution/2.x/developing-in-modx/other-development-resources/class-reference/modx) and [xPDO](http://rtfm.modx.com/xpdo/1.x/class-reference/xpdo) class has a description and link to a full documentation.

![Descriptions and documentation links](https://cloud.githubusercontent.com/assets/5139993/8544719/796dc556-24b0-11e5-971d-937f649fd0b5.png)

####Autocomplete & Syntax Highlighting

To enable syntax highlighting, switch to HTML (MODX) syntax.

![Autocomplete & Syntax highlighting](https://cloud.githubusercontent.com/assets/5139993/8555633/fed13fc2-24f9-11e5-9ce2-edbf14fdbcee.png)

####Theme and Transport Package scaffolding

Hit <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>p</kbd> and search for `MODX Generator`. There is two options available:

* Scaffold Transport Package
* Scaffold Theme

Transport Package template (modExtra) originally developed by [Shaun McCormick](https://github.com/splittingred).
Please, read the [modExtra](https://github.com/splittingred/modExtra) documentation before using it. There is also a relevant [page](http://rtfm.modx.com/extras/revo/modextra) at MODX RTFM.

###Triggers

| Snippet | Trigger | Scope |
| ------- | ------- | ----- |
| $modx->  | `$`  | .text.html.php |
| $xpdo->  | `$p`  | .text.html.php |
| MODX_API_MODE | `mapi` | .text.html.php |
| &property=\`value\` | `&` | .text.html.basic |
| :filter=\`value\` | `:` | .text.html.basic |
| @propertyset | `@` | .text.html.basic |
| [[*tag]]  | `mt`  | .text.html.basic |

**MODX_API_MODE**

    define('MODX_API_MODE', true);
    require_once('/path/to/index.php');
    $modx = new modX();
    $modx->initialize('mgr');

### Notes
* In case of issues with Emmet, use <kbd>Ctrl</kbd>+<kbd>Space</kbd> shortcut to toggle snippet.
* Because of large amount of files in Theme and Transport Package templates, there in no *Project* or *Author Name* placeholders for now. You have to manually replace them after scaffolding.
