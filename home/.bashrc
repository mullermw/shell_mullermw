#!/bin/bash
#   ~/.bashrc
#
# Bash Shell initialization script.
#
#   Maarten Billemont
#       ~lhunath
#
# Copied from http://stuff.lhunath.com/.bashrc
#             http://stackoverflow.com/a/903213 

#-------------------------#
# SHELL - INITIALIZATION  #
#-------------------------#
[[ $PATH = *local/bin* ]] || PATH=$PATH:/usr/local/bin
[[ $- = *i* ]] || return
#source bashlib


#-------------------------#
# ALIASSES - FILESYSTEM   #
#-------------------------#
alias noproxy="http_proxy= HTTP_PROXY= https_proxy= HTTPS_PROXY= ftp_proxy= FTP_PROXY="
alias rs="nice rsync --archive --no-owner --sparse --hard-links --partial --progress"
alias rsz="rs --compress-level=9 --skip-compress=gz/zip/z/rpm/deb/iso/bz2/t[gb]z/7z/mp[34]/mov/avi/ogg/jpg/jpeg/rar/gif/png/dat"
alias port="sudo nice port"
alias mvn="nice mvn"
alias cp="nice cp -v"
alias mv="nice mv -v"
alias tree="tree -F --dirsfirst"
if ls --color >/dev/null 2>/dev/null; then
    alias ls="ls -bFk --color=auto"
else
    alias ls="ls -bFkG"
fi
alias ll="ls -lh"
alias l=" ll -a"
alias df="nice df -h"


#-------------------------#
# ALIASSES - APPLICATIONS #
#-------------------------#
alias cal="cal -m -3"
alias gsh="git stash"
alias gst="git status --short --branch"
alias gsu="git submodule update --recursive --merge"
alias gdf="git diff"
alias gdt="git difftool"
alias glo="git log"
alias gps="git push"
alias gpl="git pull"
alias gco="git checkout"
alias gci="git commit"
alias gad="git add"
alias grm="git rm"
alias gmv="git mv"
alias gtg="git tag"
alias gbr="git branch"
alias gs="git svn"
alias em="emacs -nw"
alias h="history"

#-------------------------#
# ALIASSES - SYSTEM       #
#-------------------------#
s() {
    fc -s "$1=$2"
}
exists wdiff && \
    alias wdiff="wdiff -a"
exists less && \
    alias more="less" || \
    alias less="more"
alias kbg='bg; kill $!; fg'
exists ltrace && \
    alias trace="ltrace -C -f -n 4 -S"
exists pcregrep && \
    alias pcregrep="pcregrep --color=auto"
alias grep="grep -I --color=auto"
alias egrep="grep -E"
alias fgrep="grep -F"
alias pg="pgrep -l"
if exists pstree; then
    p() {
        if pstree -A >/dev/null 2>&1; then
            pstree -Aahlpu
        else
            [[ -t 1 ]] \
                && pstree -w -g2 \
                || pstree -w -g1 | recode -fg IBM850..UTF8
        fi
    }
else
    if ps auxf >/dev/null 2>&1; then
        p() { ps auxf; }
    else
        p() { ps aux; }
    fi
fi
alias pp="p | less"
top -u -h >/dev/null 2>&1 && \
    alias top="top -S -u -stats pid,ppid,user,cpu,time,threads,state,rprvt,vprvt,faults,command"


#-------------------------#
# ALIASSES - NETWORKING   #
#-------------------------#
alias n="netstat -np tcp"
alias mtr="mtr -t"
alias nmap="nmap -v -v -T5"
alias nmapp="nmap -P0 -A --osscan_limit"
alias pktstat="sudo pktstat -tBFT"


#-------------------------#
# OS-SPECIFIC             #
#-------------------------#
if [[ $MACHTYPE = *darwin* ]]; then
    # MAC ----------------#

    qview() {
        files=("$@"); i=0
        while true; do
            file=${files[i]}
            qlmanage -p "$file" & pid=$!
            
            read -sn1 key
            kill $pid || key=q
            wait $pid

            case $key in
                q)  return  ;;
                p)  let i-- ;;
                *)  let i++ ;;
            esac

            (( i < ${#files[@]} )) || break
            (( i < 0 )) && i=0
        done
    } 2>/dev/null

    qthumb() {
        qlmanage -t "$@" & pid=$!
        read -sn1

        kill $pid; wait $pid
    } 2>/dev/null
fi


#-------------------------#
# SHELL - COMPLETION      #
#-------------------------#
complete_getpw() {
    local successes candidates
    source ~/.getpw
    for url in "${!urls[@]}"; do
        [[ $url = $2* ]] || continue

        successes=${urls["$url"]}
        if (( successes )); then
            COMPREPLY+=("$url")
        fi
    done
}
complete_pw() {
    local successes candidates
    source ~/.pw.conf
    for host in "${!uses[@]}"; do
        [[ $host = $2* ]] || continue

        use=${uses["$host"]}
        if (( use > 0 )); then
            COMPREPLY+=("$host")
        fi
    done
}
complete -F complete_getpw getpw
complete -F complete_pw pw
complete -A command sudo

#-------------------------#
# FUNCTIONS - CONVENIENCE #
#-------------------------#
i() {
    bash --rcfile <(printf '%s\n' "$(<~/.bashrc)" "HISTFILE='$HISTFILE.i'" "PS1='\[$yellow\]~\[$reset\]$PS1'" "cd; clear"); clear
}
d() {
    if exists colordiff; then
        colordiff -ur "$@"
    elif exists diff; then
        diff -ur "$@"
    elif exists comm; then
        comm -3 "$1" "$2"
    fi | less
}
# f pattern [find-args]
f() {
    local root pattern=$1 preargs=() postargs=() ispost=0; shift
    for arg; do
        if [[ $arg == -- ]]; then
            ispost=1
        else
            if (( ispost )); then
                postargs+=("$arg")
            else
                preargs+=("$arg")
            fi
        fi
    done
    (( ${#preargs[@]} )) || preargs=.

    printf >&2 'find '
    printf >&2 '<%s> ' "${preargs[@]}"
    printf >&2 -- '-iname <*%s*> ' "$pattern"
    printf >&2 '<%s> ' "${postargs[@]}"
    printf >&2 '\n'

    find "${preargs[@]}" -iname "*$pattern*" "${postargs[@]}"
}
abs() {
    for arg; do
        [[ $arg = /* ]] || arg=$PWD/$arg
        printf '%s\n' "$arg"
    done
}
rerun() {
    local h history histories dialogMenu=() startIndex
    
    # Load in history entries (ignoring the last)
    IFS=$'\n' read -r -d '' -a histories < <(history | tail -n "${1:-10}")
    unset histories[${#histories[@]}-1]

    # Build a dialog(1) menu and show it to ask for the starting index.
    for h in "${!histories[@]}"; do dialogMenu+=( "$h" "${histories[h]}" ); done
    startIndex=$(dialog --stdout --menu "Bash History" 0 0 0 "${dialogMenu[@]}")

    # Run all history commands starting from the starting index.
    for history in "${histories[@]:startIndex}"; do
        eval "${history#*$'\t'}" || break
    done
}
sw() {
    local bak="$1~"
    while [[ -e $bak ]]
    do bak+='~'; done
    mv -v "$1" "$bak"
    mv -v "$2" "$1"
    mv -v "$bak" "$2"
}
ppg() {
    pat=$1; shift
    p | grep -i "$@" "$pat"
}
cwatch() {
    while sleep .5; do
        o="$("$@")"
        clear && echo "$o"
    done
}
mvns() {
    export PATH=/usr/local/share/soylatte16-amd64-1.0.3/bin:${PATH}
    export JAVA_HOME=/usr/local/share/soylatte16-amd64-1.0.3

    mvn "$@"
}
mvnroot() {
    local p=$PWD c=${1:-1}
    until p=${p%/*}; [[ -e "$p/pom.xml" ]] && (( --c <= 0 )); do :; done

    echo "${p}${red}${PWD#$p}${reset}"
    cd "$p"
}
git() {
    local errors suffix

    case $1 in
        push)
            if git submodule foreach --recursive git-check-remote; then
                inf 'All submodules have been pushed.  Continuing with push.'
            else
                err 'Fix the errors above before committing.'
                return 1
            fi ;;
    esac

    nice git "$@"
}
gf() {
    git-forest -a --sha "${@:---all}" | less
}
gd() {
    git describe --always --dirty
}
gdm() {
    emit "GIT Daemon starting with base path: $(shorten "$PWD")"
    git daemon --base-path=. "$@" &
}
git-redo-move() {
    (( $# == 2 ))   || { emit -r "Expected two parameters; [source] [destination]."; return; }
    [[ -e $2 ]]     || { emit -r "$2 doesn't exist, can't redo move."; return; }
    [[ ! -e $1 ]]   || { emit -r "$1 exists, don't want to overwrite, aborting redo move."; return; }
    mkdir -p "${1%/*}" && \mv "$2" "$1" && git mv "$1" "$2" && rmdir -p "${1%/*}"
}
git-repo-status() {
    local exit=$? cwd=$PWD repo= tag

    while [[ $cwd ]]; do
        [[ -d $cwd/.git ]] && { repo=git; break; }

        cwd=${cwd%/*}
    done

    case $repo in
        git)
            if ! tag=$(git describe --tags --exact-match 2>&-); then
                tag=$(git describe --tags 2>&-)
                tag=${tag%-*} # Chop off hash.
            fi
            printf '[%s%s%s] \n' "${cwd##*/}" "${tag:+:}" "$tag"
        ;;
    esac

    return $exit
}
ps-stats() {
    local exitcode=$? cmd=$1 elapsed= ps_stats_file="${TMPDIR:-/tmp}/.ps_stats.$$" elapsedColor= exitColor=

    # Exit code.
    (( exitcode )) || exitcode=

    # Calculate elapsed since last command.
    [[ -e $ps_stats_file ]] && {
        (( elapsed = SECONDS - $(<"$ps_stats_file") ))
        (( elapsed )) || elapsed=
    }

    # Record start of command.
    if (( cmd )); then
        echo "$SECONDS" > "$ps_stats_file"
    else
        rm -f "$ps_stats_file"
    fi

    # Color stats.
    (( elapsed >= 5 )) && elapsedColor=$red || elapsedColor=$green
    (( exitcode )) && exitColor=$red || exitColor=$green
    (( exitcode > 128 )) && exitColor=$yellow

    # Display stats.
    printf %s "$save$return$(tput cuf $((COLUMNS - 9 - ${#elapsed} - 0${elapsed:+2} - ${#exitcode} - 0${exitcode:+2})))$eel" \
                "${elapsed:+$elapsedColor+$reset$elapsed }" \
                "${exitcode:+$exitColor?$reset$exitcode }" \
                "$(date +"${yellow}T$reset%H$yellow:$reset%M$yellow:$reset%S")$load"
}
portget() {
    (( $# )) || { emit -r "$0 [revision] [category/portname]"; return; }

    [[ -e "${2#*/}" ]] && { ask -Ny! 'Target exists, delete?' && rm -rf "${2#*/}" || return; }
    svn co -r "$1" http://svn.macports.org/repository/macports/trunk/dports/"$2"
    cd "${2#*/}"
}


#-------------------------#
# FUNCTIONS - NETWORKING  #
#-------------------------#
exists lft && \
    lft() {
        sudo lft -S "$@" | tail -n +3 | column -t
    }
svnup() {
    local cRev=$(svn info | awk '/^Revision:/ { print $2 }')
    [[ $cRev ]] || { emit -r "Not in a repository."; return 1; }

    emit "Looking for updates to r$cRev"
    svn up

    local nRev=$(svn info | awk '/^Revision:/ { print $2 }')
    [[ $nRev = $cRev ]] && {
        emit "Nothing to update."
        return
    }

    echo
    emit "Changelog $cRev -> $nRev:"
    svn log -r$((cRev+1)):$nRev | while IFS= read -r line; do
        [[ $line ]] || continue

        [[ $line != *[^-]* ]] && { begin=1; continue; }
        if (( begin )); then
            read rev _ user _ d t _ <<< "$line"
            echo
            echo "$bold$green$user$reset - r$bold${rev#r}$reset:    "$'\t'"($bold$d$reset - $bold$t$reset)"
            begin=0
        else
            [[ $line = *:* ]] \
                && echo $'\t'"$reset- $bold$blue${line%%:*}$reset:${line#*:}" \
                || echo $'\t'"$reset- $line"
        fi
    done

    echo
    emit "To view the code diff of these updates; execute: svn diff -r$cRev:$nRev $(quote "$@")"
}


#-------------------------#
# FUNCTIONS - FILE SYSTEM #
#-------------------------#
cc() {
    [[ $@ =~ ^\ *(.*)\ +([^\ ]+)\ *$ ]] && \
        tar -Sc ${BASH_REMATCH[1]} | \
            tar --preserve -xvC ${BASH_REMATCH[2]}
}


#-------------------------#
# FUNCTIONS - EVALUATION  #
#-------------------------#
calc() { python -c "import math; print $*"; }
c() {
    local out="${TMPDIR:-/tmp}/c.$$" strict=1
    trap 'rm -f "$out"' RETURN

    [[ $1 = -l ]] && { strict=; shift; }
    
    local code=$(cat <<.
#include <stdio.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#if defined(__linux__)
#include <linux/fs.h>
#elif defined(__CYGWIN__)
#include <cygwin/fs.h>
#else
#include <sys/disk.h>
#endif
#include <fcntl.h>
#include <unistd.h>
#include <math.h>

void printb(char *p, size_t size) {
    for (int i = 0; i < size; ++i)
        printf("%02hhX ", p[i]);
    printf("\n");
}

int main(int argc, const char* argv[]) {
    $1;
    return 0;
}
.
)
    shift

    if ! gcc -std=gnu99 -x c -o "$out" ${strict:+-Werror} -Wall - <<< "$code"; then
        emit -r "Compilation failed:"
        cat -n <<< "$code"
        return 255
    else
        chmod +x "$out" && "$out" "$@"
    fi
}
downsize() {
    local from=$1 to=${2:-$1} size=${3:-50%}
    convert "$from" -filter box -resize "$size" -unsharp 1x1+1+0.4 "$to"
    pngstrip "$to"
}




#-----------------------------#
# SHELL - HISTORY             #
#-----------------------------#
shopt -s histappend
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILE=~/.bash.log
HISTFILESIZE=
HISTTIMEFORMAT='%F %T%t'


#-------------------------#
# SHELL - LOOK AND FEEL   #
#-------------------------#
shopt -s extglob
#shopt -qs globstar
shopt -qs checkwinsize
shopt -qs hostcomplete
shopt -qs no_empty_cmd_completion
stty stop undef
stty -echoctl

#[[ -f /etc/bash_completion ]] && \
#    source /etc/bash_completion
[[ -f ~/.share/git-svn-extensions/source.sh ]] && \
    source ~/.share/git-svn-extensions/source.sh

# Subshell to avoid triggering DEBUG.
PROMPT_COMMAND='(history -a)'

# Prompt
PS1='\h\[$blue\] \W \[$red\]${?/#0/\[$green\]}\$\[$reset\] '
if (( EUID )); then
    PS1='\[$reset$bold$green\]\u@'$PS1
else
    PS1='\[$reset$bold$red\]'$PS1
fi
forcePS1ToFront() {
    origExitCode=$?
    read r c < <(cloc)
    (( c > 1 )) && printf '\n' >&2
    return $origExitCode
}
#PS1='$(forcePS1ToFront)'$PS1 # Put the prompt on a new line if the cursor isn't in the beginning of the line.
#PS1='\[$reset$bold$green\]\u@\h\[$blue\] \W \[$green\]$(: "${?#0}"; printf "\[%s\]" "${_:+$save$red\r$_ $load}")\$\[$reset\] '
#PS1='\[$(ps-stats)\]'$PS1
#trap '(ps-stats 1)' DEBUG

# Colors
if      [[ -f /etc/DIR_COLORS.env ]]
then        source "/etc/DIR_COLORS.env"
elif    [[ -f /etc/DIR_COLORS ]] && exists dircolors
then        eval "$(dircolors -b "/etc/DIR_COLORS")"
fi
if      [[ -f ~/.dir_colors.env ]]
then        source ~/.dir_colors.env
elif    [[ -f ~/.dir_colors ]] && exists dircolors
then        eval "$(dircolors -b ~/.dir_colors)"
fi

# X Resources.
#[ "$DISPLAY" -a -f "$HOME/.Xdefaults" ] && \
#    exists xrdb && xrdb "$HOME/.Xdefaults"


#-------------------------#
# FINK ENVIRONMENT        #
#-------------------------#
test -r /sw/bin/init.sh && . /sw/bin/init.sh


#-------------------------#
# STARTUP APPLICATIONS    #
#-------------------------#
mysqlstop() {
    /opt/local/lib/mysql55/bin/mysqladmin -u root -p shutdown "$@"
}
