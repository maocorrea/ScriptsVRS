#!/bin/bash

# Variables globales
WEB_DIR="/data/data/com.termux/files/usr/share/apache2/default-site/htdocs"
PROJECT_NAME="formulario_caracterizacion"
REPO_URL="desarrollos-binariit/formulario_caracterizacion"
DOWNLOADS_DIR="/sdcard/Downloads"
MYSQL_ROOT_PASSWORD="alohomora"
PHPMYADMIN_VERSION="5.1.4"
PHP_INI_PATH="/data/data/com.termux/files/usr/etc/php/php.ini"
SESSION_DIR="/data/data/com.termux/files/usr/tmp"
LOG_DIR="/data/data/com.termux/files/usr/var/log"
SYMLINK_PATH="/sdcard/htdocs"

# 1. Solicitar el token al usuario
get_github_token() {
    echo "Por favor, introduce tu token de acceso personal de GitHub:"
    read -s GITHUB_TOKEN
    if [[ -z "$GITHUB_TOKEN" ]]; then
        echo "Error: El token de GitHub no puede estar vacío."
        exit 1
    fi

    echo "Iniciando autenticación en GitHub CLI..."
    echo "$GITHUB_TOKEN" | gh auth login --with-token
    if [ $? -ne 0 ]; then
        echo "Error: La autenticación en GitHub falló. Verifica tu token."
        exit 1
    fi
    echo "Autenticación en GitHub completada con éxito."
}

# 2. Instalar dependencias necesarias
install_dependencies() {
    echo "Instalando dependencias necesarias..."
    pkg update && pkg upgrade -y
    pkg install -y php apache2 mariadb wget tar openssl git gh
    echo "Dependencias instaladas correctamente."
}

# 3. Configurar Apache con ServerName
configure_apache() {
    echo "Configurando Apache..."
    APACHE_CONF="/data/data/com.termux/files/usr/etc/apache2/httpd.conf"
    if ! grep -q "^ServerName" "$APACHE_CONF"; then
        echo "ServerName 127.0.0.1" >> "$APACHE_CONF"
        echo "ServerName agregado a la configuración de Apache."
    else
        echo "ServerName ya está configurado en Apache."
    fi
}

# 4. Configurar MariaDB
setup_mariadb() {
    echo "Configurando MariaDB..."
    mysql_install_db --datadir=/data/data/com.termux/files/usr/var/lib/mysql
    mysqld_safe --datadir=/data/data/com.termux/files/usr/var/lib/mysql &
    sleep 5
    mysqladmin -u root password "$MYSQL_ROOT_PASSWORD"
    echo "Contraseña de root establecida: $MYSQL_ROOT_PASSWORD"
}

# 5. Configurar PHP y php.ini
configure_php() {
    echo "Configurando PHP..."
    mkdir -p "$(dirname "$PHP_INI_PATH")"
    if [ ! -f "$PHP_INI_PATH" ]; then
        cat <<EOL > "$PHP_INI_PATH"
[PHP]
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = Off
log_errors = On
error_log = $LOG_DIR/php_errors.log

[Session]
session.save_handler = files
session.save_path = "$SESSION_DIR"
EOL
    fi

    mkdir -p "$SESSION_DIR" "$LOG_DIR"
    chmod 1777 "$SESSION_DIR"
    touch "$LOG_DIR/php_errors.log"
    chmod 666 "$LOG_DIR/php_errors.log"

    echo "PHP configurado correctamente."
}

# 6. Descargar y configurar phpMyAdmin
setup_phpmyadmin() {
    echo "Instalando phpMyAdmin versión $PHPMYADMIN_VERSION..."
    mkdir -p "$WEB_DIR"
    cd "$WEB_DIR"
    wget https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz
    tar -xzf phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz
    mv phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages "$WEB_DIR/db_admin"
    rm phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz
    cd "$WEB_DIR/db_admin"
    cp config.sample.inc.php config.inc.php
    cat <<EOL >> config.inc.php

/* Configuración del servidor de MariaDB */
\$cfg['Servers'][1]['host'] = '127.0.0.1';
\$cfg['Servers'][1]['port'] = '';
\$cfg['Servers'][1]['user'] = 'root';
\$cfg['Servers'][1]['password'] = '$MYSQL_ROOT_PASSWORD';
\$cfg['Servers'][1]['auth_type'] = 'cookie';
EOL
    echo "phpMyAdmin configurado correctamente."
}

# 7. Clonar repositorio y verificar archivo SQL
clone_repository_and_check_sql() {
    echo "Clonando repositorio de GitHub..."
    gh repo clone "$REPO_URL" "$WEB_DIR/$PROJECT_NAME"
    if [ $? -ne 0 ]; then
        echo "Error: No se pudo clonar el repositorio."
        exit 1
    fi
    echo "Repositorio clonado correctamente en $WEB_DIR/$PROJECT_NAME."

 
}

# 8. Iniciar servicios
start_services() {
    echo "Iniciando servicios..."
    apachectl start
    mysqld_safe --datadir=/data/data/com.termux/files/usr/var/lib/mysql &
    echo "Servicios iniciados correctamente."
}

# 9. Mensaje final
final_message() {
    # Buscar archivo SQL
    SQL_FILE=$(find "$WEB_DIR/$PROJECT_NAME" -type f -name "*.sql")
    if [[ -n "$SQL_FILE" ]]; then
        echo "Se encontró un archivo SQL: $SQL_FILE"

        # Copiar archivo SQL a la carpeta Downloads
        cp "$SQL_FILE" "$DOWNLOADS_DIR"
        if [ $? -eq 0 ]; then
            echo "Archivo SQL copiado a $DOWNLOADS_DIR correctamente."
        else
            echo "Error al copiar el archivo SQL a $DOWNLOADS_DIR."
        fi
    else
        echo "No se encontró ningún archivo SQL en el repositorio clonado."
    fi

    echo "---------------------------------------------------------------"
    echo "Instalación completa."
    echo "Accede al proyecto en: http://localhost:8081"
    echo "Accede a phpMyAdmin en: http://localhost:8082"
    echo "Usuario MariaDB: root | Contraseña: alo****** "
    echo "---------------------------------------------------------------"
}

# Función principal
main() {
    get_github_token
    install_dependencies
    configure_apache
    setup_mariadb
    configure_php
    setup_phpmyadmin
    clone_repository_and_check_sql
    start_services
    final_message
}

main
