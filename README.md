# Auto-LaTeXdiff

This action produces differential tex documents by automatically searching for LaTeX root documents and running latexdiff comparing with previous tags.

## Input parameters and configuration

No parameter is required (convention over configuration).

| **Parameter**  | **Description**  | **Default**  |
|---|---|---|
| `directory` | Where to search for LaTeX files | `GITHUB_WORKSPACE` |
| `fail-on-error` | Fail if `latexdiff` fails | `true` |
| `files` | Latex files (globs) to compile, separated by newlines, relative to directory | `**/*.tex` |
| `include-lightweight-tags` | Whether non-annotated tags should be considered | `false` |
| `markupstyle` | Differential style. Available styles: `UNDERLINE`, `CTRADITIONAL`, `TRADITIONAL`, `CFONT`, `FONTSTRIKE`, `INVISIBLE` `CHANGEBAR` `CCHANGEBAR` `CULINECHBAR` `CFONTCHBAR` `BOLD` `PDFCOMMENT` | `CFONTCHBAR` |
| `tags` | Whether non-annotated tags should be considered | `false` |
| `include-lightweight-tags` | Newline-separated list of tags to create differential documents with. Ruby Regex syntax supported. | `.*` |
| `use-magic-comments` | If enabled, the system will consider `TeX root` magic comments to filter non-root documents | `true` |

## Usage example

```yaml
jobs:
  latexdiff:
    runs-on: ubuntu-latest # Cannot run on windows or mac.
    steps:
      - name: Checkout
        uses: actions/checkout@v2.4.0
    # Possibly other steps
      - name: Prepare the differential documents
        uses: DanySK/auto-latexdiff@master # Please select a stable release here!
        id: latexdiff
        with: # This is the default configuration. Remove all parameters that you do not change
          directory: '.'
          fail-on-error: true
          files: |
            **/*.tex
          include-lightweight-tags: false
          markupstyle: CFONTCHBAR
          tags: |
            .*
          use-magic-comments: true
    # Possibly other steps, e.g.
      - name: Compile LaTeX
        uses: DanySK/compile-latex-action@0.3.57
```
