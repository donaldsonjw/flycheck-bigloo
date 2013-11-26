# flycheck-bigloo Readme


## Description

flycheck-bigloo is a Flycheck syntax checker for the programming language bigloo. It has two modes of operation: standalone and make. In standalone mode, the file to be checked is passed to the compiler and any resulting errors are parsed and displayed. In make mode, the current directory and its parent directories are searched recursively for a makefile with a check-syntax. If found, the target is called with the environment variable CHK_SOURCES set to the file to be checked. This is the preferred method of invoking the syntax checker. It allows the appropriate setting of paths and creation of bigloo .afiles, a common source of spurious errors in stand alone mode. flycheck-bigloo prefers make mode and only falls back to standalone mode if no appropriate makefile and target are found.

## Installation
Installation is straight forward. First, flycheck-bigloo is a bigloo syntax checker for Flycheck, so as you might expect, you need to install Flycheck. The installation instructions for Flycheck can be found at <https://github.com/flycheck/flycheck>. Once Flycheck is installed, you need to copy flycheck-bigloo.el to either a location already on your elisp load-path or add the directory where you copied flycheck-bigloo.el. This can be done with a command similiar to

`(add-to-list 'load-path "/dir/to/flycheck-bigloo-dir")`

Finally, add the following line to your emacs initialization file.

`(require 'flycheck-bigloo)`

Now, flycheck can be enabled for a bigloo scheme buffer using the command `flycheck-mode`. By default, flycheck-bigloo enables flycheck for all buffers using bee.
## Customization

flycheck-bigloo provides the following customizable options:

* `flycheck-bigloo-buildfile-list`

   The list of buildfile(makefile) names to look for.

* `flycheck-bigloo-buildfile-target`

   The name of the flycheck syntax target

* `flycheck-bigloo-error-regexps`

   The list of bigloo error regexps to use


## Example Makefile Target

`check-syntax: .afile
	$(BIGLOO) -syntax-check ${CHK_SOURCES}`

The dependency on the .afile target guarantees that an appropriate .afile is created and all of the bigloo modules can be found.
