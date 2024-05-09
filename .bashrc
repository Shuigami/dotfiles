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

# Config
alias hcf='nvim ~/.config/hypr/hyprland.conf'

# Connect to vm
alias vm='ssh ubuntu@141.145.204.217'

# Afs alias
cafs()
{
    kinit -f ewan.schwaller@CRI.EPITA.FR
    mkdir -p ~/afs
    sshfs -o reconnect ewan.schwaller@ssh.cri.epita.fr:/afs/cri.epita.fr/user/e/ew/ewan.schwaller/u/ ~/afs
    cd ~/afs
}
dafs()
{
    umount ~/afs
    rmdir ~/afs
}

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

kr()
{
    nohup obsidian &
    nohup firefox ~/Documents/Talk_To_Me_In_Korean_Levels_1_9_pdf.pdf &
    exit
}
export PGDATA="$HOME/postgres_data"
export PGHOST="/tmp"

# Add JBang to environment
alias j!=jbang
export PATH="$HOME/.jbang/bin:$PATH"

gp() {
    if [ $# -ne 3 ]; then
        return;
    fi
    clang-format-epita
    git add $1
    str=$1
    str=${str::-1}
    git commit -m "$str: $2"
    git push
    git tag $3
    git push --tags
}

alias dodo="docker run --rm -it -v $PWD:/tc --workdir /tc registry.lrde.epita.fr/tc-sid"
. "$HOME/.cargo/env"
