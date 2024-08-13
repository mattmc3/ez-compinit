#
# ez-compinit: Plugin that makes it much easier to initialize Zsh completions.
#

# References:
# - https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Use-of-compinit

# Return if requirements are not met.
[[ "$TERM" != 'dumb' ]] || return 1

function run-compinit {
  emulate -L zsh
  setopt local_options extended_glob

  # Use whatever ZSH_COMPDUMP is set to, or use an appropriate cache directory.
  local zcompdump
  if [[ -n "$ZSH_COMPDUMP" ]]; then
    zcompdump="$ZSH_COMPDUMP"
  elif [[ -n "$XDG_CACHE_HOME" ]]; then
    zcompdump=$XDG_CACHE_HOME/zcompdump
  else
    zcompdump=${ZDOTDIR:-$HOME}/.zcompdump
  fi

  # Make sure zcompdump's directory exists and doesn't have a leading tilde.
  zcompdump="${~zcompdump}"
  [[ -d $zcompdump:h ]] || mkdir -p $zcompdump:h

  # `run-compinit -f` forces a cache reset.
  if [[ "$1" == (-f|--force) ]]; then
    shift
    [[ -r "$zcompdump" ]] && rm -rf -- "$zcompdump"
  fi

  # Initialize completions
  local -a compinit_flags=(-d "$zcompdump")
  autoload -Uz compinit
  if zstyle -T ':ez-compinit:features:caching' 'enabled'; then
    # Load and initialize the completion system ignoring insecure directories with a
    # cache time of 20 hours, so it should almost always regenerate the first time a
    # shell is opened each day.
    local zcompdump_cache=($zcompdump(Nmh-20))
    if (( $#zcompdump_cache )); then
      # -C (skip function check) implies -i (skip security check).
      compinit -C $compinit_flags
    else
      compinit -i $compinit_flags
      touch "$zcompdump"  # Ensure timestamp updates to reset the cache timeout.
    fi
  else
    compinit $compinit_flags
  fi

  # Compile zcompdump, if modified, in background to increase startup speed.
  {
    if [[ -s "$zcompdump" && (! -s "${zcompdump}.zwc" || "$zcompdump" -nt "${zcompdump}.zwc") ]]; then
      if command mkdir "${zcompdump}.zwc.lock" 2>/dev/null; then
        zcompile "$zcompdump"
        command rmdir  "${zcompdump}.zwc.lock" 2>/dev/null
      fi
    fi
  } &!

  # Once this runs once, we want to make sure to remove the precmd hook.
  add-zsh-hook -d precmd run-compinit
}

# Attach run-compinit to the built-in precmd hook. It should only run once, so
# run-compint or our compinit wrapper need to remove this hook after they run.
autoload -U add-zsh-hook
add-zsh-hook precmd run-compinit

# Define compinit placeholder functions (compdef) so we can queue up calls.
# That way when the real compinit is called, we can execute the queue.
typeset -gHa __compdef_queue=()
function compdef {
  (( $# )) || return
  local compdef_args=("${@[@]}")
  __compdef_queue+=("$(typeset -p compdef_args)")
}

# Wrap compinit temporarily so that when the real compinit call happens, the
# queue of compdef calls is processed.
function compinit {
  unfunction compinit compdef &>/dev/null
  autoload -Uz compinit && compinit "$@"

  # Apply all the queued compdefs.
  local typedef_compdef_args
  for typedef_compdef_args in $__compdef_queue; do
    eval "$typedef_compdef_args"
    compdef "$compdef_args[@]"
  done
  unset __compdef_queue

  # We can also run compinit early. Once it runs, we no longer need a precmd hook.
  add-zsh-hook -d precmd run-compinit
}
