# How to update libcurl in Tower
- fetch all remotes
- find libcurl tag for latest version in upstream remote, e.g. "curl-8_10_1"
- create new local branch from tag for Textastic version: e.g. "textastic_10_4"
- cherry-pick or manually add commit "libssh2: Use custom SSH protocol banner"
- push to origin remote
