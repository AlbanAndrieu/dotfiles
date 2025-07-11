
###
# Alias
###

# Formatting constants
export BOLD=`tput bold`
export UNDERLINE_ON=`tput smul`
export UNDERLINE_OFF=`tput rmul`
export TEXT_BLACK=`tput setaf 0`
export TEXT_RED=`tput setaf 1`
export TEXT_GREEN=`tput setaf 2`
export TEXT_YELLOW=`tput setaf 3`
export TEXT_BLUE=`tput setaf 4`
export TEXT_MAGENTA=`tput setaf 5`
export TEXT_CYAN=`tput setaf 6`
export TEXT_WHITE=`tput setaf 7`
export BACKGROUND_BLACK=`tput setab 0`
export BACKGROUND_RED=`tput setab 1`
export BACKGROUND_GREEN=`tput setab 2`
export BACKGROUND_YELLOW=`tput setab 3`
export BACKGROUND_BLUE=`tput setab 4`
export BACKGROUND_MAGENTA=`tput setab 5`
export BACKGROUND_CYAN=`tput setab 6`
export BACKGROUND_WHITE=`tput setab 7`
export RESET_FORMATTING=`tput sgr0`

#esc="\033["
#line="${esc}31;40mIn Color${esc}0m"
#echo -e "$line"
#echo -e "${esc}1;34mBLUE TEXT${esc}0m"

#To be able to print this, you have to press CTRL+V and then the ESC key.
#The Color Code: <ESC>[{attr};{fg};{bg}m
#echo "^[[0;31;40mIn Color"

# The "sed -r" trick does not work on every Linux, I still dunno why:
export DECOLORIZE='eval sed "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"'
#howto use
#<commands that type colored output> | ${DECOLORIZE}

# Wrapper function for Maven's mvn command.
mvn-color()
{
  # Filter mvn output using sed
  mvn $@ | sed -e "s/\(\[INFO\]\ \-.*\)/${TEXT_BLUE}${BOLD}\1/g" \
               -e "s/\(\[INFO\]\ \[.*\)/${RESET_FORMATTING}${BOLD}\1${RESET_FORMATTING}/g" \
               -e "s/\(\[INFO\]\ BUILD SUCCESSFUL\)/${BOLD}${TEXT_GREEN}\1${RESET_FORMATTING}/g" \
               -e "s/\(\[WARNING\].*\)/${BOLD}${TEXT_YELLOW}\1${RESET_FORMATTING}/g" \
               -e "s/\(\[ERROR\].*\)/${BOLD}${TEXT_RED}\1${RESET_FORMATTING}/g" \
               -e "s/Tests run: \([^,]*\), Failures: \([^,]*\), Errors: \([^,]*\), Skipped: \([^,]*\)/${BOLD}${TEXT_GREEN}Tests run: \1${RESET_FORMATTING}, Failures: ${BOLD}${TEXT_RED}\2${RESET_FORMATTING}, Errors: ${BOLD}${TEXT_RED}\3${RESET_FORMATTING}, Skipped: ${BOLD}${TEXT_YELLOW}\4${RESET_FORMATTING}/g"

  # Make sure formatting is reset
  echo -ne ${RESET_FORMATTING}
}

# Override the mvn command with the colorized one.
alias mvnc="mvn-color"

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  ## Colorize the ls output ##
  #alias ls='ls --color=auto'

  # some more ls aliases

  ## Use a long listing format ##
  #alias ll='ls -alF'

  ## Show hidden files ##
  #alias l.='ls -d .* --color=auto'

  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

# Use instead ~/.local/share/omakub/defaults/bash/aliases

alias l='exa'
alias la='exa -a'
alias ll='exa -lahg'
# alias ls='exa --color=auto'

## replace mac with your actual server mac address #
alias wakeupnas01='/usr/bin/wakeonlan 7C:05:07:0E:D9:88'

# Stop after sending count ECHO_REQUEST packets #
alias ping='ping -c 5'
# Do not wait interval 1 second, go fast #
alias fastping='ping -c 100 -s.2'

# handy short cuts #
alias h='history'
alias j='jobs -l'

alias mount='mount | column -t'

alias sha1='openssl sha1'

alias c='clear'

# get web server headers #
# find out if remote server supports gzip / mod_deflate or not #
alias header='curl -I'
alias headerc='curl -I --compress'

## pass options to free ##
alias meminfo='free -m -l -t'

## get top process eating memory
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'

## get top process eating cpu ##
alias pscpu='ps auxf | sort -nr -k 3'
alias pscpu10='ps auxf | sort -nr -k 3 | head -10'

## Get server cpu info ##
alias cpuinfo='lscpu'

## older system use /proc/cpuinfo ##
##alias cpuinfo='less /proc/cpuinfo' ##

## get GPU ram on desktop / laptop##
alias gpumeminfo='grep -i --color memory /var/log/Xorg.0.log'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

#alias status="svn status -u"
#alias replace="${WORKSPACE_ENV}/scripts/replace.pl"
#alias svndi="svn di --diff-cmd=svndiff"
#TODO same as svn st-q
#alias svnst="svn st | grep -v ^?"

# See https://www.howtoforge.com/tutorial/linux-grep-command/
# use grep -r instead
#alias Grep="find . -name '*.[jch]*' -exec grep -n \!* {} + -o -name '.svn' -prune -type f"
#alias hGrep="find . -name '*.h' -exec grep -n \!* {} + -o -name '.svn' -prune -type f"
# grep -r mysearch ./
alias Grep="find . -name '*.*' -type f  -not -path '*/\.git/*' | xargs grep {} "
#alias Grep="grep -r  {} . "
#echo "find . -type d -name ".svn"  -print | xargs rm -Rf"
#echo "find . -name 'pom.xml' | xargs grep SNAPSHOT"

#alias scons="${SCONS}"

alias eclipse='${ECLIPSE_HOME}/eclipse'
alias cursor='~/Applications/cursor.AppImage --no-sandbox'
alias lumbermill='java -jar ${LUMBERMILL_HOME}/dist/lib/lumbermill.jar'

alias mkctl="microk8s kubectl"

#mkdir /home/albandrieu/.k9s
alias k9s='k9s --kubeconfig /home/albandrieu/.kube/config'
alias dockviz="docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock nate/dockviz"

#rm ~/.gitconfig.lock
#git config --global alias.co checkout
#git config --global alias.br branch
#git config --global alias.ci commit
#git config --global alias.st status
#git config --global alias.unstage 'reset HEAD --'
#git config --global alias.last 'log -1 HEAD'

alias ..="cd .."
alias cls="clear"

if [ "${ARCH}" = sun4sol -o "${ARCH}" = solaris ]
then
  alias l='/bin/ls -Fl'
  alias pp='/usr/ucb/ps -auxwww'
  alias m='/usr/ucb/more'
else
  if [ "${ARCH}" = sun4 ]
  then
    alias l='/bin/ls -Flg'
    alias pp='/usr/bin/ps -auxwww'
  else
    if [ "${ARCH}" = rs6000 ]
    then
      alias l='/bin/ls -Fl'
      alias pp='/usr/bin/ps auxwww'
      alias m='/usr/bin/more'
    else
      if [ "${ARCH}" = hprisc ]
      then
        alias l='/bin/ls -Fl'
        alias pp='/bin/ps -edf'
      else
        if [ "${ARCH}" = linux -o "${ARCH}" = cygwin ]
        then
          alias l='/bin/ls -Fl --color'
          alias pp='/bin/ps -auxwww'
        fi
      fi
    fi
  fi
fi

#to get man in french
#alias man='man -L en'
#alias man='man -L fr'
alias man='tldr'

alias psg="pp | egrep -i \!* |& grep -v 'egrep -i \!*'"
alias psuser="pp | cut -d' ' -f1 | sort | grep -v USER | uniq -c | sort -r"

alias cat='batcat --paging=never'

#ln -s "${PROJECT_DEV}" ~/w || true
alias cdr="cd ~/w"
alias cdj="cd ~/w/jm"
alias cdi="cd ~/w/jm/infra"
alias cde="cd ${PROJECT_DEV}/${PROJECT_EXTRACTION}"
alias cdw="cd ${PROJECT_DEV}"
alias cdc="cd ${PROJECT_DEV}/env/config"
#alias cdinc="cd ${PROJECT_TARGET_PATH}/include/${ARCH}"
#alias cdobj="cd ${PROJECT_TARGET_PATH}"
#alias cdbin="cd ${PROJECT_TARGET_PATH}/bin"

#alias cdrl="cd ${PROJECT_RELEASE}/latest"
#alias cdri="cd ${PROJECT_RELEASE}/installed"
#alias cdcu="cd ${PROJECT_RELEASE}/current"

alias cdcore="cd ${PROJECT_TARGET_PATH}/corefiles"
alias setEnvFiles="${WORKSPACE_ENV}/config/setEnvFiles.sh ${PROJECT_USER_PROFILE} \!* --userdev"
alias setEnvFilesAll="${WORKSPACE_ENV}/config/setEnvFiles.allUserDev.sh ${PROJECT_USER_PROFILE}"
alias setWorkspace="source ${WORKSPACE_ENV}/scripts/setWorkspace.sh"

alias phpstan='docker run -v $PWD:/app --rm ghcr.io/phpstan/phpstan'
alias lzd='docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v /home/albanandrieu/.config/:/.config/jesseduffield/lazydocker lazyteam/lazydocker'

# Infrastructure tools
alias tf='terraform'
alias mcp-gen='mcp generate'

# Cloud CLI shortcuts
alias awsq='aws q'
alias azai='az ai'
alias gcp-ai='gcloud ai'

# alias tctl="docker exec temporal-admin-tools tctl"
# BEGIN ANSIBLE MANAGED BLOCK profile 
# openvpn
#alias jmvpn="sudo openvpn3 session-start --config ~/openvpn.profile"
#alias jmvpn="sudo tailscale up --login-server https://vpn.jusmundi.com:943 --accept-routes --accept-dns"
alias jmvpn="sudo tailscale up --login-server https://vpn.jusmundi.com:943 --accept-routes --accept-dns --advertise-connector --advertise-tags=tag:connector --operator=$USER --stateful-filtering && sudo service tailscaled restart"
alias bssh="ssh -t gra1bastion.int.jusmundi.com --"
# END ANSIBLE MANAGED BLOCK profile 
