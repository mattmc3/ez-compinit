# ez-compinit

> Plugin that makes it much easier to initialize Zsh completions

## How it works?

:hatching_chick: Let's talk about `compinit`...

The [Zsh completion system][zsh-completion-system] works by finding _completion files in
Zsh's `fpath`. That means your `fpath` needs to be fully populated prior to calling
`compinit`. But, sometimes you need completion functions to be available like `compdef`
before `fpath` is fully populated. Many Zsh plugins call `compdef`, for example. Zsh's
completion system has big chicken-and-egg problems :hatching_chick:. Which comes first!?

This plugin handles all those completion use-cases by simply wrapping `compinit`,
queueing any calls to `compdef`, and hooking the real call to `compinit` to an event
that runs at the end of your `.zshrc`. That way you get all the benefits of calling
`compinit` early without any of the downsides. Neat!

## What if I'm using Oh-My-Zsh?

This plugin is **not** needed for regular Oh-My-Zsh users. If you are using Oh-My-Zsh
with the [antidote] plugin manager, I recommend using [getantidote/use-omz][use-omz]
instead, which is by the same plugin author and uses similar concepts, but is geared
towards Oh-My-Zsh specifically.

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

[antidote]: https://getantidote.github.io
[use-omz]: https://github.com/getantidote/use-omz
[zsh-completion-system]: https://zsh.sourceforge.io/Doc/Release/Completion-System.html#index-completion-system
