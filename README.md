# Auto-LaTeXdiff

This action produces differential LaTeX documents by automatically searching for LaTeX root documents and running latexdiff comparing with previous tags.

## Input parameters and configuration

This action (by design choice, mostly due to portability) does not rely on GitHub inputs, but uses environment variables.

* `DIRECTORY`: where to search for LaTeX files. Defaults to the GitHub Actions workspace.
* `METHOD`: Which differential method to use, defaults to `CFONTCHBAR`.
* `OUTPUT`: The file where to write the results. Defaults to `auto-latexdiff.log`
* `BUILDER`: The LaTex compiler to use, among: `latexmk`, `tectonic`, `lualatex`, `xelatex`, `pdflatex`.
Defaults to `latexmk`.
* `BIB_TYPE`: if set, forces execution of either `bibtex` or `biber`.
Should be useful only when `pdflatex` is selected.
Empty by default.

## Usage example

An example configuration this action is used and its results are deployed is available [here](https://github.com/DanySK/centralized-automated-deployer/blob/master/LaTeX%20diff/.github/workflows/auto-latexdiff.yml).
