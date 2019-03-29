#!/bin/bash

SCRIPT_DIR="$(dirname $(readlink -f "$0"))"
if [[ $# -ne 0 ]]; then
  "$SCRIPT_DIR/load.sh" "$@"
  echo
fi

echo -e "\033[0mNO COLOR"
echo -e "\033[1;37mWHITE\t\033[0;30mBLACK"
echo -e "\033[0;31mRED\t\033[1;31mLIGHT_RED"
echo -e "\033[0;32mGREEN\t\033[1;32mLIGHT_GREEN"
echo -e "\033[0;33mYELLOW\t\033[1;33mLIGHT_YELLOW"
echo -e "\033[0;34mBLUE\t\033[1;34mLIGHT_BLUE"
echo -e "\033[0;35mPURPLE\t\033[1;35mLIGHT_PURPLE"
echo -e "\033[0;36mCYAN\t\033[1;36mLIGHT_CYAN"
echo
echo -e "\033[48;5;0m  \033[48;5;1m  \033[48;5;2m  \033[48;5;3m  \033[48;5;4m  \033[48;5;5m  \033[48;5;6m  \033[48;5;7m  \033[0m"
echo -e "\033[48;5;8m  \033[48;5;9m  \033[48;5;10m  \033[48;5;11m  \033[48;5;12m  \033[48;5;13m  \033[48;5;14m  \033[48;5;15m  \033[0m"
