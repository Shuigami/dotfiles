# ============================== PS1 ============================== #
virtualenv_info(){
    if [[ -n "$VIRTUAL_ENV" ]]; then
        venv="${VIRTUAL_ENV##*/}"
    else
        venv=''
    fi
    [[ -n "$venv" ]] && echo "(venv:$venv) "
}
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

export VIRTUAL_ENV_DISABLE_PROMPT=1
VENV="\$(virtualenv_info)";

export PS1="\n\[$(tput setaf 103)\]\w\[$(tput setaf 146)\]\$(parse_git_branch)\$(parse_git_status) \[$(tput setaf 1)\]$VENV\n\[$(tput setaf 210)\]> \[$(tput sgr0)\]"

# ============================== Export ============================== #
export NVIM_LOG_FILE=~/.local/share/nvim/log
export GRIM_DEFAULT_DIR=~/Pictures/screens/

export GTK_IM_MODULE='fcitx'
export QT_IM_MODULE='fcitx'
export SDL_IM_MODULE='fcitx'
export XMODIFIERS='@im=fcitx'

export LS_COLORS=$LS_COLORS:'di=1;31:'

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
export PGPORT="5432"

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

shuigit() {
    echo "Files/folder to add?"
    read files

    echo "Commit message?"
    read msg

    echo "Tag?"
    read tag

    echo "You sure? (y/n)"
    printf "Files/folder: $files\t\tCommit message: $msg\t\tTag: $tag\n"

    read ans
    if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
        return;
    fi

    git add "$files"
    git commit -m "$msg"
    git push

    if [ -n "$tag" ]; then
        git tag "$tag"
        git push --tags
    fi
}

shuicmake() {
  cmake -B build/
  cmake --build build/
}

export PATH=$HOME/.local/bin:$PATH
alias zed="WAYLAND_DISPLAY='' zed"

eval "$(thefuck --alias)"

