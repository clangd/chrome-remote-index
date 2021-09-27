# Chromium remote index server

This server provides about a day old index for
[chromium](https://chromium.googlesource.com/chromium/src.git) to be used by
clangd. It aims to lower resource usage of clangd on workstation machines by
moving project-wide indexing and serving pieces to a centralized server.

To make use of this service you need a clangd build with remote index support
and point clangd at this particular index server.

More details on
[remote index internals](https://clangd.llvm.org/remote-index.html).

## Getting clangd client

**Googlers only** : clangd is installed on `/usr/bin/clangd` by default on
glinux workstations, you can directly use that instead.

[clangd/releases](https://github.com/clangd/clangd/releases) are
built with that support for major platforms. You can find out about other
options in [here](https://clangd.llvm.org/remote-index.html#clangd-client).

After acquiring the binary, make sure your LSP client points to it. Details
about this process can be found
[here](https://clangd.llvm.org/installation.html#editor-plugins).

## Pointing clangd to chromium-remote-index-server

**Googlers only** : if you are using clangd installed on a glinux workstation,
you should have remote-index support on by default.

Finally you'll need to point clangd at this particular index server. The easiest
way to achieve this is via user configuration: a config.yaml file in an
OS-specific directory:

-   Windows: `%LocalAppData%\clangd\config.yaml`, typically
    `C:\Users\Bob\AppData\Local\clangd\config.yaml`.
-   macOS: `~/Library/Preferences/clangd/config.yaml`
-   Linux and others: `$XDG_CONFIG_HOME/clangd/config.yaml`, typically
    `~/.config/clangd/config.yaml`.

You'll need to populate this config file with the following, while changing
`/path/to/chromium/src/` with absolute path to your checkout location.

```
If:
  PathMatch: /path/to/chromium/src/.*
Index:
  External:
    Server: linux.clangd-index.chromium.org:5900
    MountPoint: /path/to/chromium/src/
```

## FAQ

### I am targeting a non-linux platform, can I still use this service?

If you are targeting a different platform, you can change the Server to one of
the following instead:

```
linux: linux.clangd-index.chromium.org:5900
chromeos: chromeos.clangd-index.chromium.org:5900
android: android.clangd-index.chromium.org:5900
fuchsia: fuchsia.clangd-index.chromium.org:5900
chromecast-linux: chromecast-linux.clangd-index.chromium.org:5900
chromecast-android: chromecast-android.clangd-index.chromium.org:5900
```

Unfortunately we don't support mac & windows targets yet.

### Will clangd still know about my local changes?

Clangd will still have up-to-date symbol information for the files open (and the
headers included through them) in your current editing session, but the
information might be stale for the others. This has been working fine for most
users, but if that's not the case for you, you can also turn on local indexing
for parts of the codebase. Such a config file could look like:

```yaml
If:
  PathMatch: /path/to/chromium/src/.*
Index:
  External:
    Server: linux.clangd-index.chromium.org:5900
    MountPoint: /path/to/chromium/src/
---
If:
  PathMatch: /path/to/chromium/src/chromeos/login/.*
Index:
  Background: Build
```

Note that the fragment setting Index.Background to Build must come after the
external index specification. More details on
[configuration schema](https://clangd.llvm.org/config.html).

### I've multiple checkouts, how do I state that fact in config?

If you have multiple checkouts you can specify different fragments by putting
--- in between. For example:

```yaml
If:
  PathMatch: /path/to/chromium/src/.*
Index:
  External:
    Server: linux.clangd-index.chromium.org:5900
    MountPoint: /path/to/chromium/src/
---
If:
  PathMatch: /path/to/chromium2/src/.*
Index:
  External:
    Server: chromeos.clangd-index.chromium.org:5900
    MountPoint: /path/to/chromium2/src/
```

### Verifying that remote-index is in use

Clangd should be working as before, e.g. can take you to the definitions of
symbols that aren't directly visible within the current file, or provide code
completions for symbols outside of current translation unit. Note that the
information coming from files that are recently modified but not been opened in
current editing session might be stale.

To increase certainity, you can check clangd logs after performing some actions
like go-to-definition or code-completion for such contents:

```
I[12:49:24.612] Associating /repos/chromium/src/ with remote index at linux.clangd-index.chromium.org:5900.
V[12:49:24.614] Remote index connection [linux.clangd-index.chromium.org:5900]: idle => connecting
V[12:49:24.662] Remote index [linux.clangd-index.chromium.org:5900]: LookupRequest => 1 results in 48ms.
V[12:49:24.662] Remote index connection [linux.clangd-index.chromium.org:5900]: connecting => ready
```

Note that to see the verbose logs you need to pass in `-log=verbose` to clangd.
You can find details about accessing clangd logs in
https://clangd.llvm.org/troubleshooting.html#gathering-logs.

### Untrusted config warning

If you have the following warning:

> Remote index may not be specified by untrusted configuration. Copy this into
> user config to use it.

It means you configered the remote index through project config (e.g.
`/path/to/llvm/.clangd`) which is no longer supported. Please follow
[configuration instructions](http://go/clangd-llvm-remote-index#setup-instructions-for-googlers)
above instead.

### Symbol information seems to be missing for some symbols.

If you are working on a branded chromeos build, using chromeos index is not
enough as there's some discrepancy in handling std symbols between branded and
unbranded builds. You can work around this by updating your remote index spec to
look like:

```yaml
If:
  PathMatch: /path/to/chromium/src/.*
Index:
  External:
    Server: chromeos.clangd-index.chromium.org:5900
    MountPoint: /path/to/chromium/src/
CompileFlags:
  Add: [-D_LIBCPP_ABI_UNSTABLE, -D_LIBCPP_ABI_VERSION=Cr]
```
