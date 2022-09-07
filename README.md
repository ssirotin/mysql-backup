# mysql-backup

# Описание и применение скриптов
Скрипт *backupsql.sh* создает бекап всех существующих баз, привелегии на которые есть у указанного пользователя СУБД. Файлы бекапов БД будут хранится в сжатых архивах по пути *$HOME/backup_sql*, каждый в своей директории, имя которых указано в формате год**месяц**день_час**минуты**секунды. Также скрипт ищет директории с бекапами БД, которые не изменялись больше 30 дней, и удаляет их. Скрипт рекомендуется запускать по расписанию с помощью **cron**.
После клонирования репозитория необходимо дать права на выполнение скриптов командой *chmod +x* и выполнить некоторые настройки, которые указаны ниже.

## 1.Создание директории для хранения бэкапов БД в домашней папке пользователя
Перед запуском скрипта бекапа БД необходимо создать директорию *backup_sql* в домашней папке пользователя, под которым будет запускаться скрипт, и проверить права **rwx** для пользователя на эту директорию:
```bash 
mkdir ~/backup_sql
ls -l ~/ | grep backup_sql
```

## 2.Безопасное использование логина и пароля пользователя СУБД Mysql и MariaDB в скриптах
Для безопасности в скриптах не используются логин и пароль пользователя СУБД, вместо этого используется скрытый файл *.mylogin.cnf*.
Утилита *mysql_config_editor* позволяет хранить учетные данные аутентификации в скрытом файле с именем *.mylogin.cnf*. Расположение файла — домашний каталог текущего пользователя в системах, отличных от Windows. Файл может быть прочитан позже клиентскими программами MySQL для получения учетных данных аутентификации для подключения к серверу MySQL.

Формат файла *.mylogin.cnf* состоит из групп опций. Вот пример этого файла:

```mysql
[client]
user = mydefaultname
password = mydefaultpass
host = 127.0.0.1
[mypath]
user = myothername
password = myotherpass
host = localhost
```
При выполнении *mysql* без параметров считывается блок [client],  а *mysql --login-path=mypath* считываются данные из блока [mypath]  
В скриптах *mysql* выполняется без параметра *--login-path=mypath*

Чтобы указать свои параметры в файле *.mylogin.cnf* используем в терминале следующую команду: 
```bash
mysql_config_editor set --login-path=client --host=localhost --user=логин_пользователя_СУБД --password
Enter password: его_пароль
```
Проверить файл *.mylogin.cnf* можно командой:
```bash
mysql_config_editor print --all
```

В Mariadb утилиты *mysql_config_editor* нет, вместо нее надо создать скрытый файл в домашней директории пользователя *.my.cnf* и вписать блоки [client] и другие при необходимости. Далле *chmod 600 ~/.my.cnf* 

## 3.Настройка отправки уведомлений на эл. почту и Телеграм боту 
Скрипты отправляют уведомления на эл. почту и Телеграм боту. Значение эл. почты хранится в переменной $MYEMAIL, токен от Телеграм бота в $BOTTOKEN, id чата бота в $CHATID. Необходимо экспортировать эти переменные в переменные окружения, самый простой способ установить переменные окружения - использовать команду export: 
export VAR="value"
В таком случае переменные окружения не будут постоянными при перезапуске оболочки. Однако существует способ сделать изменения постоянными: с помощью системных файлов .bashrc или .bash_profile в домашней директории конкретного пользователя или в /etc/profile для всех пользователей

ИСПОЛЬЗОВАНИЕ ФАЙЛА .BASHRC
Файл .bashrc - это скрипт, выполняемый всякий раз, когда вы инициализируете сеанс интерактивной оболочки. Как следствие, когда вы запускаете новый терминал через интерфейс GNOME или просто используете screen сессию, вы будете использовать файл .bashrc
Например, добавьте следующие записи в ваш файл .bashrc:
```bash
export VAR="value"
```
Сохраните ваш файл и используйте команду source для перезагрузки файла bashrc для текущего сеанса оболочки:
```bash
source ~/.bashrc
```
ИСПОЛЬЗОВАНИЕ ФАЙЛА .BASH_PROFILE
В качестве альтернативы, если вы планируете подключаться к своим сеансам с помощью login оболочек, вы также можете добавить переменные окружения непосредственно в файл .bash_profile:
```bash
export VAR="value"
```
Сохраните ваш файл и используйте команду source для перезагрузки файла .bash_profile для текущего сеанса оболочки:
```bash
source ~/.bash_profile
```
