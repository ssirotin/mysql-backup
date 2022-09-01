#!/usr/bin/env bash

################### ENV VARIABLES ###################
# These variables are stored in environment variables.

# $MYEMAIL
# $BOTTOKEN
# $CHATID

################### ENV VARIABLES ###################

########### VARIABLES ###########
BACKUP_DATA_DIR=$HOME/backup_sql
SETCOLOR_SUCCESS="echo -en \\033[1;32m"
SETCOLOR_FAILURE="echo -en \\033[1;31m"
SETCOLOR_NORMAL="echo -en \\033[0;39m"
########### VARIABLES ###########

############# interactive menu function #############
function menu() {
clear
  echo "1 - Restore Mysql backup"
  echo "2 - Send a message to Telegram bot"
  echo "3 - Send a file to Telegram bot"
  echo "q - Exit"
  echo -n "Choose action: "
  read -n 1 key
  echo -e "\n"
}
#####################################################

##################### alert ok ######################
function alert_ok() {
$SETCOLOR_SUCCESS
  echo -n "$(tput hpa $(tput cols))$(tput cub 6)[OK]"
  $SETCOLOR_NORMAL
  echo
}
#####################################################

#################### alert fail #####################
function alert_fail() {
$SETCOLOR_FAILURE
  echo -n "$(tput hpa $(tput cols))$(tput cub 6)[fail]"
  $SETCOLOR_NORMAL
  echo
}
#####################################################

################## function timer ###################
function timer() {
echo -n "exit to main menu: "
SECS=5
while [[ 0 -ne $SECS ]]; do
  echo -n "$SECS.."
  sleep 1
  SECS=$[$SECS-1]
done
}
#####################################################

######### recursive backup restore function #########
# This function will return to the dialog about restoring the backup again and again
function backup_restore_recursive() {
read -e -p "Select a backup and press Enter: " BACKUP_DIR
if [[ -d "${BACKUP_DATA_DIR}"/"${BACKUP_DIR}" ]] && 
   [[ "$BACKUP_DIR" =~ (20[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|1[0-9]|2[0-9]|3[0-1]))_(0[0-9]|1[0-9]|2[0-4])([0-5][0-9]){2} ]]; then
  echo -e "backup "$BACKUP_DIR" selected\n"
elif [ -z "$BACKUP_DIR" ]; then
  echo -e "You didn't enter anything!\n" >&2
  backup_restore_recursive
else
  echo -e "This is not a backup!\n" >&2
  backup_restore_recursive
fi
}
#####################################################

############# backup restore function ###############
function backup_restore() {
echo "Started at: ""$(date)"
echo -e "Mysql database backups are stored in a directory "$HOME"/backup_sql now you will be moved to this directory\nsucces\n"
cd "$BACKUP_DATA_DIR"
echo -e "This directory contains several backups sorted by dates:\n"$(ls --color)"\n"
read -e -p "Select a backup and press Enter: " BACKUP_DIR
if [[ -d "${BACKUP_DATA_DIR}"/"${BACKUP_DIR}" ]] && 
   [[ "$BACKUP_DIR" =~ (20[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|1[0-9]|2[0-9]|3[0-1]))_(0[0-9]|1[0-9]|2[0-4])([0-5][0-9]){2} ]]; then
  echo -e "backup "$BACKUP_DIR" selected\n"
elif [ -z "$BACKUP_DIR" ]; then
  echo -e "You didn't enter anything!\n" >&2
  backup_restore_recursive
else
  echo -e "This is not a backup!\n" >&2
  backup_restore_recursive
fi

if [ -e "${BACKUP_DATA_DIR}"/"${BACKUP_DIR}"/all.sql.tbz ]; then
  echo "Found compressed backup archive now it will be unpacked"
else
  echo -e "Error: Compressed backup archive not found. Finished at: "$(date)"\n" >&2
  echo -e "Error: Compressed backup archive not found. Finished at: "$(date)"\n" | mail -s "Database backup restore fault" "$MYEMAIL"
  curl -s -X POST https://api.telegram.org/bot"$BOTTOKEN"/sendMessage -d chat_id="$CHATID" -d text="Database backup restore fault. Error: Compressed backup archive not found. Finished at: `date`" &> /dev/null
  timer
  return $?
fi

tar -xjf "${BACKUP_DATA_DIR}"/"${BACKUP_DIR}"/all.sql.tbz --directory "${BACKUP_DATA_DIR}"/"${BACKUP_DIR}"/ all.sql

if mysql < "${BACKUP_DATA_DIR}"/"${BACKUP_DIR}"/all.sql; then
  echo -e "Database backup restore finished. Finished at: "$(date)"\n"
  echo -e "Database backup restore finished. Finished at: "$(date)"\n" | mail -s "backup restore finished" "$MYEMAIL"
  curl -s -X POST https://api.telegram.org/bot"$BOTTOKEN"/sendMessage -d chat_id="$CHATID" -d text="Database backup restore finished. Finished at: `date`" &> /dev/null
  rm "${BACKUP_DATA_DIR}"/"${BACKUP_DIR}"/all.sql
  timer
else
  echo -e "Database backup restore return non-zero code at: "$(date)"\n" >&2
  echo -e "Database backup restore return non-zero code at: "$(date)"\n" | mail -s "Database backup restore fault" "$MYEMAIL"
  curl -s -X POST https://api.telegram.org/bot"$BOTTOKEN"/sendMessage -d chat_id="$CHATID" -d text="Database backup restore return non-zero code at: `date`" &> /dev/null
  rm "${BACKUP_DATA_DIR}"/"${BACKUP_DIR}"/all.sql
  timer
  return $?
fi
}
#####################################################  

########### send message to telegram bot ############
function send_message() {
read -e -p "Enter the text of the message to send to the bot: " SEND_MESSAGE
if [ -n "$SEND_MESSAGE" ]; then
  alert_ok
  curl -s -X POST https://api.telegram.org/bot"$BOTTOKEN"/sendMessage -d chat_id="$CHATID" -d text="$SEND_MESSAGE" &> /dev/null
  echo -e "Message sent to bot\n"
  read -n 1 -p "Do you want to continue [Y/n]?: " KEY
    case $KEY in
      "n" | "N" ) menu;;
      "y" | "Y" ) echo -e "\n"; send_message;;
    esac
else
  alert_fail
  echo -e "String length is zero!\n" >&2
  read -n 1 -p "Do you want to continue [Y/n]?: " KEY
    case $KEY in
    "n" | "N" ) menu;;
    "y" | "Y" ) echo -e "\n"; send_message;;
    esac
fi
}
#####################################################

############# send file to telegram bot #############
function send_file() {
read -e -p "Enter the absolute path to the file: " SEND_FILE
if [ -n "$SEND_FILE" ]; then
  if [ -f "$SEND_FILE" ]; then
    echo "Selected file "$SEND_FILE""
  else
    alert_fail
    echo -e "File not exist!\n" >&2
    send_file
  fi
  if [[ -r "$SEND_FILE" ]]; then
    alert_ok
    curl -s -F document=@"$SEND_FILE" https://api.telegram.org/bot"$BOTTOKEN"/sendDocument?chat_id="$CHATID"
    echo
    echo -e "File "$SEND_FILE" sent to bot\n"
    send_file
  else
    alert_fail
    echo -e "Permission denied\n" >&2
    send_file
  fi
else
  alert_fail
  echo -e "You have not selected a file!\n" >&2
  send_file
fi
}
#####################################################

while true
do
  case "$key" in
    "x" | "q" | "X" | "Q" ) break;;
    "1" )
       backup_restore
    ;;
    "2" )
       send_message
    ;;
    "3" )
       send_file
    ;;
  esac
  menu
done
