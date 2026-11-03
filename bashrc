# ===== ~/.bashrc 追記サンプル =====

# エイリアス
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias grep='grep --color=auto'

# git ブランチを色付きで表示（カレントディレクトリ名のみ・入力は次の行）
if [ -f /etc/bash_completion.d/git-prompt ]; then
    source /etc/bash_completion.d/git-prompt
    GIT_PS1_SHOWDIRTYSTATE=1
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[33m\]$(__git_ps1 " (%s)")\[\033[00m\]\n\$ '
fi
