# mysql-backup
Утилита mysql_config_editor позволяет хранить учетные данные аутентификации в скрытом файле с именем .mylogin.cnf. Расположение файла — домашний каталог текущего >

Формат файла .mylogin.cnf состоит из групп опций. Вот пример этого файла:

[client]
user = mydefaultname
password = mydefaultpass
host = 127.0.0.1
[mypath]
user = myothername
password = myotherpass
host = localhost

При выполнении mysql без параметров считывается блок [client],  а mysql --login-path=mypath считываются данные из блока [mypath]

В Mariadb утилиты mysql_config_editor нет, вместо нее надо создать скрытый файл в домашней директории пользователя .my.cnf и вписать блоки [client] и другие при н>

Это удобно при использовании в скриптах, чтобы в скриптах не хранить логины и пароли пользователей базы данных.

