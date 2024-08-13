# ez-compinit

> Plugin that makes it much easier to initialize Zsh completions

## How it works?

:hatching_chick: Let's talk about `compinit`...

The [Zsh completion system][zsh-completion-system] works by finding _completion files in
Zsh's `fpath`. That means your `fpath` needs to be fully populated prior to calling
`compinit`. But, sometimes you need completion functions to be available like `compdef`
before `fpath` is fully populated. Many Zsh plugins call `compdef`, for example.

Zsh's completion system has big chicken-and-egg problems :hatching_chick:. Which is first!?

This plugin handles all those completion use-cases by simply wrapping `compinit`,
queueing up calls to `compdef`, and hooking the real `compinit` call to an event
that runs at the end of your `.zshrc`. That way you get all the benefits of calling
`compinit` early without any of the downsides. Neat!

## How do I install it?

To install with [antidote], add the following to antidote's
`${ZDOTDIR:-$HOME}/.zsh_plugins.txt` file:

```
mattmc3/ez-compinit
```

To install with a different plugin manager, follow the guide for that plugin manager.

To install manually, do the following:

```zsh
[[ -n "$ZPLUGIN_HOME" ]] || ZPLUGIN_HOME=${ZDOTDIR:-$HOME}/.zsh_plugins
if [[ ! -d $ZPLUGIN_HOME/ez-compinit ]]; then
  git clone https://github.com/mattmc3/ez-compinit $ZPLUGIN_HOME
fi
source $ZPLUGIN_HOME/ez-compinit/ez-compinit.plugin.zsh
```

## How do I use it?

ez-compinit is pretty simple. Run this plugin near the top of your config before any
other plugins or scripts that might call `compdef`.

It's also recommended to pick a completion style. You set a compstyle with the following
zstyle statement:

```zsh
# See available completion styles with 'compstyle -l'
zstyle ':plugin:ez-compinit' 'compstyle' 'zshzoo'
```

## Can I still call compinit myself?

Yes, you can absolutely call `compinit` yourself. Or, you can use a plugin that calls
`compinit`. ez-compinit will gracefully unhook itself whenever `compinit` is called.

Or, you can simply load this plugin and forget about it. ez-compinit will guarantee
`compinit` is called for you with reasonable defaults. That's what makes it **easy**.
You no longer need to think about how Zsh completions work.

## What if I'm using Oh-My-Zsh?

This plugin is **not** needed for regular Oh-My-Zsh users. If you are using Oh-My-Zsh
with the [antidote] plugin manager, I recommend using [getantidote/use-omz][use-omz]
instead, which is by the same plugin author and uses similar concepts, but is geared
towards Oh-My-Zsh specifically.

## How do I customize it?

This plugin will place the completion dump file at the following location by default:
`${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump`. You can override this by setting
the `ZSH_COMPDUMP` variable like so:

```zsh
ZSH_COMPDUMP=/path/to/.zcompdump
```

This plugin caches the zcompdump file for a day for performance reasons. You can disable
that behavior with the following `zstyle`:

```zsh
zstyle ':plugin:ez-compinit' 'use-cache' 'no'
```

ez-compinit provides a `run-compinit` function which includes performance enhancements
in addition to caching mentioned above. It will also `zcompile` the completion file, and
will skip insecure directory checks. This is very similar to what Prezto does in its
completion module. That might not be what you want, so if you prefer to use `compinit`
differently, you can simply call it yourself at the very bottom of your `.zshrc`:

```
# .zshrc contents above...
autoload -Uz compinit
compinit -u -d /path/to/zcompdump
# end of .zshrc
```

[antidote]: https://getantidote.github.io
[use-omz]: https://github.com/getantidote/use-omz
[zsh-completion-system]: https://zsh.sourceforge.io/Doc/Release/Completion-System.html#index-completion-system
