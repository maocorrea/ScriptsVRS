#!/bin/bash

# Variables globales
WEB_DIR="/data/data/com.termux/files/usr/share/apache2/default-site/htdocs"
PROJECT_NAME="equipos_basicos"
DB_ADMIN_DIR="$WEB_DIR/db_admin"
MYSQL_ROOT_PASSWORD="alohomora"
PHPMYADMIN_VERSION="5.1.4"
PHP_INI_PATH="/data/data/com.termux/files/usr/etc/php/php.ini"
SESSION_DIR="/data/data/com.termux/files/usr/tmp"
LOG_DIR="/data/data/com.termux/files/usr/var/log"

# 1. Instalar dependencias necesarias
install_dependencies() {
    echo "Instalando dependencias necesarias..."
    pkg update && pkg upgrade -y
    pkg install -y php apache2 mariadb wget tar openssl
    echo "Dependencias instaladas correctamente."
}

# 2. Configurar Apache con ServerName
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

# 3. Configurar MariaDB
setup_mariadb() {
    echo "Configurando MariaDB..."
    # Inicializar MariaDB
    mysql_install_db --datadir=/data/data/com.termux/files/usr/var/lib/mysql
    mysqld_safe --datadir=/data/data/com.termux/files/usr/var/lib/mysql &
    sleep 5
    # Establecer contraseña de root
    mysqladmin -u root password "$MYSQL_ROOT_PASSWORD"
    echo "Contraseña de root establecida: $MYSQL_ROOT_PASSWORD"
}

# 4. Configurar PHP y php.ini
configure_php() {
    echo "Configurando PHP..."
    # Crear el archivo php.ini si no existe
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
        echo "Archivo php.ini creado en $PHP_INI_PATH."
    else
        echo "Archivo php.ini ya existe en $PHP_INI_PATH."
    fi

    # Crear directorios necesarios
    mkdir -p "$SESSION_DIR"
    chmod 1777 "$SESSION_DIR"
    mkdir -p "$LOG_DIR"
    touch "$LOG_DIR/php_errors.log"
    chmod 666 "$LOG_DIR/php_errors.log"

    echo "PHP configurado correctamente."
}

# 5. Descargar y configurar phpMyAdmin (versión 5.1.4)
setup_phpmyadmin() {
    echo "Instalando phpMyAdmin versión $PHPMYADMIN_VERSION..."
    mkdir -p "$WEB_DIR"
    cd "$WEB_DIR"

    # Descargar phpMyAdmin
    wget https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz

    # Extraer el archivo descargado
    tar -xzf phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz

    # Renombrar la carpeta extraída
    EXTRACTED_DIR=$(find "$WEB_DIR" -maxdepth 1 -type d -name "phpMyAdmin-*")
    if [ -n "$EXTRACTED_DIR" ]; then
        mv "$EXTRACTED_DIR" "$DB_ADMIN_DIR"
        echo "phpMyAdmin renombrado a $DB_ADMIN_DIR."
    else
        echo "Error: No se encontró la carpeta phpMyAdmin después de la extracción."
        exit 1
    fi

    # Eliminar el archivo tar.gz para limpieza
    rm phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz

    # Configurar phpMyAdmin
    echo "Configurando phpMyAdmin..."
    cd "$DB_ADMIN_DIR"
    cp config.sample.inc.php config.inc.php

    # Agregar configuración del servidor de MariaDB
    cat <<EOL >> config.inc.php

/* Configuración del servidor de MariaDB */
\$cfg['Servers'][1]['host'] = '127.0.0.1'; // Dirección del servidor MariaDB
\$cfg['Servers'][1]['port'] = '';          // Usa el puerto predeterminado (3306)
\$cfg['Servers'][1]['user'] = 'root';      // Usuario de MariaDB
\$cfg['Servers'][1]['password'] = '$MYSQL_ROOT_PASSWORD'; // Contraseña del usuario root
\$cfg['Servers'][1]['auth_type'] = 'cookie';  // Método de autenticación

EOL
    echo "phpMyAdmin configurado correctamente."
}

# 6. Crear proyecto "equipos_basicos"
create_project() {
    echo "Creando proyecto $PROJECT_NAME..."
    PROJECT_DIR="$WEB_DIR/$PROJECT_NAME"
    mkdir -p "$PROJECT_DIR"
    echo "<?php echo '<h1>Equipos básicos</h1>'; ?>" > "$PROJECT_DIR/index.php"
    echo "Proyecto $PROJECT_NAME creado en $PROJECT_DIR."
}

# 7. Iniciar servicios y levantar servidores PHP
start_services_and_projects() {
    echo "Iniciando servicios..."
    apachectl start
    mysqld_safe --datadir=/data/data/com.termux/files/usr/var/lib/mysql &
    echo "Servicios iniciados correctamente."

    echo "Levantando servidor PHP para $PROJECT_NAME en localhost:8081..."
    php -S localhost:8081 -t "$WEB_DIR/$PROJECT_NAME" &
    echo "Servidor PHP para $PROJECT_NAME levantado en http://localhost:8081"

    echo "Levantando servidor PHP para db_admin en localhost:8082..."
    php -S localhost:8082 -t "$DB_ADMIN_DIR" &
    echo "Servidor PHP para phpMyAdmin levantado en http://localhost:8082"
}

# 8. Mensaje final
final_message() {
    echo "---------------------------------------------------------------"
    echo "Instalación completa."
    echo "Accede al proyecto en: http://localhost:8081"
    echo "Accede a phpMyAdmin en: http://localhost:8082"
    echo "Usuario MariaDB: root | Contraseña: $MYSQL_ROOT_PASSWORD"
    echo "---------------------------------------------------------------"
}

# Función principal
main() {
    install_dependencies
    configure_apache
    setup_mariadb
    configure_php
    setup_phpmyadmin
    create_project
    start_services_and_projects
    final_message
}

main
