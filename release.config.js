var prepareCmd = `
docker build -t danysk/auto-latexdiff:latest . || exit 1
`
var publishCmd = `
docker build -t danysk/auto-latexdiff:\${nextRelease.version} . || exit 1
docker push --all-tags danysk/auto-latexdiff || exit 2
`
var config = require('semantic-release-preconfigured-conventional-commits');
config.plugins.push(
    ["@semantic-release/exec", {
        "prepareCmd": prepareCmd,
        "publishCmd": publishCmd,
    }],
    "@semantic-release/github",
    "@semantic-release/git",
)
module.exports = config
