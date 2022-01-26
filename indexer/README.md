# Making a new indexer release

Running `bash rollout_new_release.sh GITHUB_TOKEN` will create a new indexer
image with latest snapshot binaries available in
[clangd/releases](https://github.com/clangd/clangd/releases) and restart the
`indexer` instance in `chrome-remote-index` GCP project.

The `GITHUB_TOKEN` is used for creating releases and uploading indexing
artifacts into
[this repo](https://github.com/clangd/chrome-remote-index/releases). So it
should have `public_repo` access. Note that releases will be created as the user
owning the token.
