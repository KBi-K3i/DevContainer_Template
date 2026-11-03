# --- DevContainer シェル設定（Dockerfile により /etc/bash.bashrc へ追記される）---

# エイリアス
alias ll='ls -alF'
alias la='ls -A'
alias ..='cd ..'
alias grep='grep --color=auto'

# git ブランチを色付きで表示（カレントディレクトリ名のみ・入力は次の行）
__git_branch() { git branch 2>/dev/null | sed -n 's/^\* \(.*\)/ (\1)/p'; }
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[33m\]$(__git_branch)\[\033[00m\]\n\$ '
