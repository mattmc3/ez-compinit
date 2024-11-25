# ez-compinit

> :hatching_chick: Make Zsh compinit suck less

This Zsh Plugin removes the complexity and "gotchas" from initializing the Zsh
completion system (compinit).

## What's so hard about compinit?

:hatching_chick: Let's talk about `compinit`...

The [Zsh completion system][zsh-completion-system] works by loading any completion
functions in Zsh's "fpath". Completion functions are named with a leading underscore
(eg: "_foo"). In order to use `compinit` correctly, your fpath needs to be fully populated prior to calling it. But, sometimes you need to use the completion functions
`compinit` creates, like `compdef`. Many Zsh plugins call `compdef`, for example.

This creates a big chicken-and-egg problem :hatching_chick:. Do you call `compinit`
earlier so that its functions are available, or later so that you're sure you have
everything in your `fpath` fully populated?

Then, once you've figured out how to initialize completions, you still have to figure
out how to _display_ them. That happens with calls to `zstyle`. Learning how to
properly configure your [zstyles](https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#index-zstyle)
to show completions how you want them is a whole other dark art in Zsh.

Add to that the fact that calls to `compinit` are likely to be one of the slower parts
of your whole Zsh config, and you wind up quickly finding that `compinit` is a pain to
use, especially for new users.

This plugin aims to fix all that. It handles the Zsh completion system complexity so you don't have to.

## How does ez-compinit work?

This plugin simply wraps `compinit` and the functions it creates so that we can defer
completion initialization until after "fpath" is fully populated. This allows queueing
calls to `compdef`, and hooking the real `compinit` call to an event that runs at the
very end of your `.zshrc`. That way you get all the benefits of calling `compinit`
early without any of the downsides. Neat!

It also packages some completion "zstyles" from other popular projects like:
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)
- [Prezto](https://github.com/sorin-ionescu/prezto)
- [grml](https://github.com/grml/grml-etc-core/blob/master/etc/zsh/zshrc)

## How do I install it?

To install with [antidote], add the following to the **top** of antidote's
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

ez-compinit is pretty simple. Run this plugin near the **top** of your config before any
other plugins or scripts that might call `compdef`.

It's also recommended to pick a completion style. You set a compstyle with the following
zstyle statement:

```zsh
# Available completion styles: gremlin, ohmy, prez, zshzoo
# You can add your own too. To see all available completion styles
# run 'compstyle -l'
zstyle ':plugin:ez-compinit' 'compstyle' 'zshzoo'
```

## Can I still call compinit myself?

Yes, you can absolutely call `compinit` yourself. Or, you can use a plugin that calls
`compinit`. ez-compinit will gracefully unhook itself whenever `compinit` is called.
But remember, once you do, your `fpath` cannot be modified with additional directories
if you expect those to contain more completion functions.

Or, you could simply load this plugin and forget about it. ez-compinit will guarantee
`compinit` is called for you with reasonable defaults. That's what makes it **easy**.
You no longer need to think about how Zsh completions work.

## What if I'm using Oh-My-Zsh?

This plugin is **not** needed for regular Oh-My-Zsh users. But, if you happen to be
using Oh-My-Zsh with the [antidote] plugin manager, I highly recommend using
[getantidote/use-omz][use-omz] instead, which is by the same plugin author (me!) and
uses similar concepts, but is geared specifically towards antidote users of Oh-My-Zsh.
You definitely don't need both plugins.

## I don't use the antidote plugin manager. Can I still use this?

Absolutely. This plugin has nothing to do with antidote, which is why it's hosted on my
personal GitHub and not at [https://github.com/getantidote](https://github.com/getantidote).
It's a complete plugin on its own with no dependencies, and makes managing the Zsh
completion system easy.

## Customization

There are a few ways to customize ez-compinit behavior if you want to.

### Customizing dump file path

This plugin will place the completion dump file at the following location by default:
`${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump`. You can override this by setting
the `ZSH_COMPDUMP` variable like so:

```zsh
ZSH_COMPDUMP=/path/to/.zcompdump
```

### Caching/compiling the dump file

This plugin can also cache the zcompdump file for a day for performance reasons. Caching
is disabled by default because it can cause you trouble if you add completions to your
`fpath` and forget you have enabled caching. Then, you'll waste a hour trying to track
down why your compinit is broken. If you consider yourself an advanced user and think
you can navigate that issue, you can enable caching with the following `zstyle`:

```zsh
zstyle ':plugin:ez-compinit' 'use-cache' 'yes'
```

ez-compinit provides a `run-compinit` function which includes performance enhancements
in addition to caching mentioned above. It will also `zcompile` the completion file, and
will skip insecure directory checks. This is very similar to what Prezto does in its
completion module.

### Calling compinit yourself

If you prefer to use `compinit` differently, you can simply call it yourself at the very bottom of your `.zshrc`. By loading ez-compinit at the top and calling `compinit`
yourself at the bottom, you still get all the benefits of queueing `compdef` calls.

```zsh
# .zshrc
# Load ez-compinit towards the top of your config
# Load it yourself, or with a plugin manager.
source /path/to/ez-compinit/ez-compinit.plugin.zsh

#
# .zshrc contents here...
#

autoload -Uz compinit
compinit -u -d /path/to/zcompdump
# end of .zshrc
```

[antidote]: https://antidote.sh
[use-omz]: https://github.com/getantidote/use-omz
[zsh-completion-system]: https://zsh.sourceforge.io/Doc/Release/Completion-System.html#index-completion-system
