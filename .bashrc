# ============================== PS1 ============================== #
parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ \1/'
}
parse_git_status() {
    git_status=$(git status --porcelain 2>/dev/null)
    status=""
    if [ "$git_status" != "" ]; then
        status=" *"
    fi
    echo "$status"
}
export PS1="\n\[$(tput setaf 111)\]\w\[$(tput setaf 146)\]\$(parse_git_branch)\$(parse_git_status)\n\[$(tput setaf 141)\]> \[$(tput sgr0)\]"

# ============================== Export ============================== #
export NVIM_LOG_FILE=~/.local/share/nvim/log
export GRIM_DEFAULT_DIR=~/Pictures/screens/

export GTK_IM_MODULE='fcitx'
export QT_IM_MODULE='fcitx'
export SDL_IM_MODULE='fcitx'
export XMODIFIERS='@im=fcitx'

# ============================== Alias ============================== #
alias ls='ls --color=auto'
alias v='nvim'

# Connect to vm
alias vm='ssh ubuntu@141.145.204.217'

# Remouse function
re()
{
    if [ $# -eq 1 ]; then
        orientation=$1
    else
        orientation=left
    fi
    source ~/.env_remouse/bin/activate
    remouse --mode fill --password aodLKYhCyz --orientation $orientation
}
rer()
{
    source ~/.env_remouse/bin/activate
    remouse --region --mode fill --password aodLKYhCyz
}
red()
{
    ip=$1
    if [ "$ip" == "" ]; then
        ip=$(arp-scan -l | grep "20:50:e7:d8:52:7a" | cut -d '	' -f 1)
    fi
    if [ "$ip" == "" ]; then
        exit
    fi
    echo $ip
    source ~/.env_remouse/bin/activate
    remouse --key .ssh/remarkable --password aodLKYhCyz --address $ip
}
