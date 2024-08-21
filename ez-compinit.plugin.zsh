#
# ez-compinit: Plugin that makes it much easier to initialize Zsh completions.
#

# References:
# - https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Use-of-compinit

# Return if requirements are not met.
[[ "$TERM" != 'dumb' ]] || return 1

# Autoload functions.
0=${(%):-%N}
fpath=(${0:a:h}/functions $fpath)
autoload -Uz ${0:a:h}/functions/*(.:t)

function run-compinit {
  emulate -L zsh
  setopt local_options extended_glob

  # Use whatever ZSH_COMPDUMP is set to, or use an appropriate cache directory.
  local zcompdump
  if [[ -n "$ZSH_COMPDUMP" ]]; then
    zcompdump="$ZSH_COMPDUMP"
  else
    zcompdump=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump
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
  if zstyle -t ':plugin:ez-compinit' 'use-cache'; then
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
}

# Define compinit placeholder functions (compdef) so we can queue up calls.
# That way when the real compinit is called, we can execute the queue.
typeset -gHa __compdef_queue=()
function compdef {
  (( $# )) || return
  __compdef_queue+=("${@[@]}" ";;;do compdef;;;")
}

# Wrap compinit temporarily so that when the real compinit call happens, the
# queue of compdef calls is processed.
function compinit {
  unfunction compinit compdef &>/dev/null
  autoload -Uz compinit && compinit "$@"

  # Apply all the queued compdefs.
  local arg; local -a compdef_args=()
  for arg in "${__compdef_queue[@]}"; do
    if [[ "$arg" == ";;;do compdef;;;" ]]; then
      compdef "${compdef_args[@]}"
      compdef_args=()
    else
      compdef_args+=("$arg")
    fi
  done
  unset __compdef_queue

  # We can also run compinit early. Once it runs, we no longer need a precmd hook.
  add-zsh-hook -d precmd run-compinit
}

function run-compstyleinit {
  compstyleinit
  local -a mycompstyle
  if zstyle -a ':plugin:ez-compinit' 'compstyle' mycompstyle; then
    if [[ "$mycompstyle" != (off|none) ]]; then
      compstyle "${mycompstyle[@]}"
    fi
  fi
}

# Attach run-compinit and run-compstyle to the built-in precmd hook. These should only
# run once, so each function needs to remove this hook after they run.
autoload -U add-zsh-hook
add-zsh-hook precmd run-compinit

if zstyle -t ':plugin:ez-compinit:compstyleinit' defer; then
  add-zsh-hook precmd run-compstyleinit
else
  run-compstyleinit
fi
