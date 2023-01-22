#! /bin/sh

# === SHELL CONFIG ===
set -e # stop with a error
set -u # forbidden undefined vars

# === STEP CONFIG ===
STEP_COUNT=12
COUNTER=1

# === COLOR CONFIG ===
ESC="\e["
ESCEND="m"

COLOR_CYAN="${ESC}36;1${ESCEND}"
COLOR_YELLOW="${ESC}33;1${ESCEND}"
COLOR_OFF="${ESC}${ESCEND}"

# === SELECT MODE

MODE_SELECTOR=""
while :
do
  printf "${COLOR_YELLOW}SELECT MODE\"? [withoutsudo/full]: ${COLOR_OFF}"
  read MODE_SELECTOR
  case "${MODE_SELECTOR}" in
    "withoutsudo" )
      MODE=0
      printf "${COLOR_CYAN}Run only tasks that do not require sudo.${COLOR_OFF}\n"
      break
      ;;
    "full" )
      MODE=1
      printf "${COLOR_CYAN}Run all tasks.${COLOR_OFF}\n"
      break
      ;;
  esac
done

# === SET APT SERVER FIRST TIME [sudo]
MSG="SET apt server to Yamagata Univ first time."

if [$MODE -le 0]; then
  printf "[${COUNTER}/${STEP_COUNT}] SKIP ${MSG} (Need sudo)\n"
then
  printf "[${COUNTER}/${STEP_COUNT}] ${COLOR_CYAN}${MSG}${COLOR_OFF}\n"

  set -x
  sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
  sudo sed -i.bak -r 's@http://(jp\.)?archive\.ubuntu\.com/ubuntu/?@https://linux.yz.yamagata-u.ac.jp/ubuntu/@g' /etc/apt/sources.list
  { set +x ; } 2>/dev/null
fi

COUNTER=`expr $COUNTER + 1`

# === APT UPDATE [sudo] ===
MSG="apt update && apt upgrade"

if [$MODE -le 0]; then
  printf "[${COUNTER}/${STEP_COUNT}] SKIP ${MSG} (Need sudo)\n"
then
  printf "[${COUNTER}/${STEP_COUNT}] ${COLOR_CYAN}${MSG}${COLOR_OFF}\n"
  set -x
  sudo apt-get update
  sudo apt-get upgrade -y
  { set +x ; } 2>/dev/null
fi

COUNTER=`expr $COUNTER + 1`

# === set hide needrestart [sudo] ===
MSG="Hide needrestart"

bash -c "which needrestart >/dev/null 2>&1" || EXIST_CMD=$?
if [$MODE -le 0]; then
  printf "[${COUNTER}/${STEP_COUNT}] SKIP ${MSG} (Need sudo)\n"
elif [ EXIST_CMD -ne 0]; then
  printf "[${COUNTER}/${STEP_COUNT}] SKIP ${MSG} (No command needrestart)\n"
else
  printf "[${COUNTER}/${STEP_COUNT}] ${COLOR_CYAN}${MSG}${COLOR_OFF}\n"

  YN_SELECTOR=""
  printf "${COLOR_YELLOW}Hide \"Which services should be restarted?\"? (y/N): ${COLOR_OFF}"
  read YN_SELECTOR
  case "${YN_SELECTOR}" in
    [Yy]* )
      set -x
      echo "\$nrconf{restart} = 'a';" | sudo tee /etc/needrestart/conf.d/50local.conf
      { set +x ; } 2>/dev/null
      ;;
  esac
fi
COUNTER=`expr $COUNTER + 1`

# === INSTALL apt-fast [sudo] ===
MSG="INSTALL apt-fast"
bash -c "which apt-fast >/dev/null 2>&1" || EXIST_CMD=$?
if [$MODE -le 0]; then
  printf "[${COUNTER}/${STEP_COUNT}] SKIP ${MSG} (Need sudo)\n"
elif [ EXIST_CMD -eq 0]; then
  printf "[${COUNTER}/${STEP_COUNT}] SKIP ${MSG} (installed)\n"
else
  printf "[${COUNTER}/${STEP_COUNT}] ${COLOR_CYAN}${MSG}${COLOR_OFF}\n"

  set -x
  sudo add-apt-repository ppa:apt-fast/stable -y
  sudo apt-get update
  sudo apt-get -y install apt-fast
  { set +x ; } 2>/dev/null
fi
COUNTER=`expr $COUNTER + 1`

# === Select Japanese [sudo] ===
MSG="Set Japanese"
if [$MODE -le 0]; then
  printf "[${COUNTER}/${STEP_COUNT}] SKIP ${MSG} (Need sudo)\n"
else
  printf "[${COUNTER}/${STEP_COUNT}] ${COLOR_CYAN}${MSG}${COLOR_OFF}\n"
  YN_SELECTOR=""
  printf "${COLOR_YELLOW}SET JAPANESE? (y/N): ${COLOR_OFF}"
  read YN_SELECTOR
  case "${YN_SELECTOR}" in
    [Yy]* )
      set -x
      sudo apt-fast install -y language-pack-ja manpages-ja manpages-ja-dev
      sudo update-locale LANG=ja_JP.UTF-8
      { set +x ; } 2>/dev/null
      ;;
  esac
fi

COUNTER=`expr $COUNTER + 1`

# === INSTALL python & apt-selector [sudo] ===
MSG="INSTALL apt-select"
if [$MODE -le 0]; then
  printf "[${COUNTER}/${STEP_COUNT}] SKIP ${MSG} (Need sudo)\n"
else
  printf "[${COUNTER}/${STEP_COUNT}] ${COLOR_CYAN}${MSG}${COLOR_OFF}\n"

  set -x
  # install python tool
  sudo apt-fast install -y python3-setuptools
  # run python
  pip3 install apt-select

  # run
  apt-select -C JP -c -t 3 -m one-week-behind
  { set +x ; } 2>/dev/null
  # SELECT
  if [ -e ./sources.list ]; then
    set -x
    sudo cp ./sources.list /etc/apt/sources.list
    rm ./sources.list
    { set +x ; } 2>/dev/null
  fi

  set -x
  sudo apt-fast update
  { set +x ; } 2>/dev/null
fi

COUNTER=`expr $COUNTER + 1`

# === INSTALL git [sudo] ===
MSG="INSTALL git"
if [$MODE -le 0]; then
  printf "[${COUNTER}/${STEP_COUNT}] SKIP ${MSG} (Need sudo)\n"
else
  printf "[${COUNTER}/${STEP_COUNT}] ${COLOR_CYAN}${MSG}${COLOR_OFF}\n"

  set -x
  sudo apt-fast install -y git
  { set +x ; } 2>/dev/null
  printf "${COLOR_YELLOW}GEN SSH KEY? (y/N): ${COLOR_OFF}"
  read YN_SELECTOR
  case "${YN_SELECTOR}" in
    [Yy]* )
      set -x
      ssh-keygen -t ed25519
      { set +x ; } 2>/dev/null
      printf "${COLOR_YELLOW}GENERATED SSH KEY! [PressEnter]${COLOR_OFF}"
      read YN_SELECTOR
      ;;
  esac
fi

COUNTER=`expr $COUNTER + 1`

# == CLONE dotfiles.git ===
MSG="CLONE dotfiles.git"

bash -c "which git >/dev/null 2>&1" || EXIST_CMD=$?
if [ EXIST_CMD -ne 0]; then
  printf "[${COUNTER}/${STEP_COUNT}] SKIP ${MSG} (need git command)\n"
else
  printf "[${COUNTER}/${STEP_COUNT}] ${COLOR_CYAN}${MSG}${COLOR_OFF}\n"
  set -x
  cd ~
  rm -rf ./dotfiles
  git clone https://github.com/GunseiKPaseri/dotfiles.git
  bash ./dotfiles/dots_linux.sh
  { set +x ; } 2>/dev/null
fi

COUNTER=`expr $COUNTER + 1`

# === INSTALL vim ===
MSG="INSTALL vim"
bash -c "which vim >/dev/null 2>&1" || EXIST_CMD=$?
if [$MODE -le 0]; then
  printf "[${COUNTER}/${STEP_COUNT}] SKIP ${MSG} (Need sudo)\n"
elif [ EXIST_CMD -eq 0]; then
  printf "[${COUNTER}/${STEP_COUNT}] SKIP ${MSG} (installed)\n"
else
  printf "[${COUNTER}/${STEP_COUNT}] ${COLOR_CYAN}${MSG}${COLOR_OFF}\n"
  set -x
  sudo apt-fast install -y vim-gtk3
  { set +x ; } 2>/dev/null
fi

COUNTER=`expr $COUNTER + 1`

# === INSTALL tmux ===
MSG="INSTALL tmux"
bash -c "which tmux >/dev/null 2>&1" || EXIST_CMD=$?
if [$MODE -le 0]; then
  printf "[${COUNTER}/${STEP_COUNT}] SKIP ${MSG} (Need sudo)\n"
elif [ EXIST_CMD -eq 0]; then
  printf "[${COUNTER}/${STEP_COUNT}] SKIP ${MSG} (installed)\n"
else
  printf "[${COUNTER}/${STEP_COUNT}] ${COLOR_CYAN}${MSG}${COLOR_OFF}\n"
  set -x
  sudo apt-fast install -y tmux
  { set +x ; } 2>/dev/null
fi

COUNTER=`expr $COUNTER + 1`

# === INSTALL fish ===
MSG="INSTALL fish"
bash -c "which fish >/dev/null 2>&1" || EXIST_CMD=$?
if [$MODE -le 0]; then
  printf "[${COUNTER}/${STEP_COUNT}] SKIP ${MSG} (Need sudo)\n"
elif [ EXIST_CMD -eq 0]; then
  printf "[${COUNTER}/${STEP_COUNT}] SKIP ${MSG} (installed)\n"
else
  printf "[${COUNTER}/${STEP_COUNT}] ${COLOR_CYAN}${MSG}${COLOR_OFF}\n"
  set -x
  sudo add-apt-repository ppa:fish-shell/release-3 -y
  sudo apt-fast update
  sudo apt-fast install -y fish
  { set +x ; } 2>/dev/null
fi

COUNTER=`expr $COUNTER + 1`

# === INSTALL fisher ===
MSG="INSTALL fisher(fish package manager)"

printf "[${COUNTER}/${STEP_COUNT}] ${COLOR_CYAN}${MSG}${COLOR_OFF}\n"
set -x
curl https://git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish
{ set +x ; } 2>/dev/null

COUNTER=`expr $COUNTER + 1`

# === set thisfile ===
source ~/.bash_profile