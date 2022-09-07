#!/usr/bin/env bash

################### ENV VARIABLES ###################
# These variables are stored in environment variables.

# $MYEMAIL
# $BOTTOKEN
# $CHATID

################### ENV VARIABLES ###################

##################### VARIABLES #####################
BACKUP_DATA_DIR=$HOME/backup_sql
BACKUP_DIR=$BACKUP_DATA_DIR/$(date +%Y%m%d_%H%M%S)
DAYS_TO_STORE=30
##################### VARIABLES ####################

echo "Started at: "$(date)
mkdir $BACKUP_DIR

if mysqldump --opt --force --events --all-databases > $BACKUP_DIR/all.sql; then
  echo "Database dump created"
else
  echo "mysqldump return non-zero code at: "$(date)"" >&2
  sleep 5
  echo -e "mysqldump return non-zero code at: "$(date)"\n" | mail -s "dump fault" "$MYEMAIL"
  curl -s -X POST https://api.telegram.org/bot"$BOTTOKEN"/sendMessage -d chat_id="$CHATID" -d text="mysqldump return non-zero code at: `date`" &> /dev/null
  exit $?
fi

#Здесь мы создаем архив созданного бекапа. c-создать, j-сжать bzip, f-файл. Указываем как будет называться наш сжатый архив $BACKUP_DIR/all.sql.tbz
# --directory $BACKUP_DIR/ выполняем эту опцию, чтобы перейти в каталог, где лежит файл для архивации all.sql
if tar -cjf $BACKUP_DIR/all.sql.tbz --directory $BACKUP_DIR/ all.sql; then
  echo "Database backup was comressed"
else
  echo "Error comressing backup at: "$(date)"" >&2
  sleep 5
  echo -e "Error comressing backup at: "$(date)"\n" |  mail -s "error comressing backup" "$MYEMAIL"
  curl -s -X POST https://api.telegram.org/bot"$BOTTOKEN"/sendMessage -d chat_id="$CHATID" -d text="Error comressing backup at: `date`" &> /dev/null
  exit $?
fi

rm $BACKUP_DIR/all.sql  # удаляем бекап, оставляя только сжатый архив
chmod -R 700 $BACKUP_DIR

#Removing old directories
find $BACKUP_DATA_DIR/* -type d -mtime +$DAYS_TO_STORE | xargs -r rm -R    # Ищем каталоги, которые не изменялись больше 30 дней и удаляем их
echo -e "Database backup finished and comressed. Finished at: "$(date)"\n"
sleep 5
echo -e "Database backup finished and comressed. Finished at: "$(date)"\n" | mail -s "backup finished" "$MYEMAIL"
curl -s -X POST https://api.telegram.org/bot"$BOTTOKEN"/sendMessage -d chat_id="$CHATID" -d text="Database backup finished and compressed. Finished at: `date`" &> /dev/null

