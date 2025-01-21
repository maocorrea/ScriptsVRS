#!/bin/bash

# Variables globales
WEB_DIR="/data/data/com.termux/files/usr/share/caddy/html"
PHP_MYADMIN_DIR="$WEB_DIR/db_admin" # Nombre final para phpMyAdmin
MYSQL_ROOT_PASSWORD="alohomora"
CADDYFILE="/data/data/com.termux/files/usr/etc/Caddyfile"

# 1. Instalar dependencias necesarias
install_dependencies() {
    echo "Instalando dependencias necesarias..."
    pkg update && pkg upgrade -y
    pkg install -y caddy php php-fpm mariadb wget tar openssl lsof
    echo "Dependencias instaladas correctamente."
}

# 2. Verificar y liberar el puerto
check_port() {
    PORT=$1
    if lsof -i :"$PORT" &>/dev/null; then
        echo "Error: El puerto $PORT ya está en uso por otro proceso."
        echo "Por favor, libera el puerto o utiliza otro en el archivo Caddyfile."
        exit 1
    fi
}

# 3. Configurar Caddy
configure_caddy() {
    echo "Configurando Caddy..."
    mkdir -p "$WEB_DIR"
    rm -f "$WEB_DIR/index.html" # Eliminar archivos residuales
    cat <<EOL > "$CADDYFILE"
:8088 {
    root * $WEB_DIR
    php_fastcgi 127.0.0.1:9000
    file_server
}
EOL
    echo "Caddy configurado para usar PHP en el puerto 8088."
}

# 4. Configurar PHP-FPM
configure_php_fpm() {
    echo "Configurando PHP-FPM..."
    PHP_FPM_CONF="/data/data/com.termux/files/usr/etc/php-fpm.d/www.conf"
    if grep -q "^listen =" "$PHP_FPM_CONF"; then
        sed -i "s|^listen =.*|listen = 127.0.0.1:9000|g" "$PHP_FPM_CONF"
    else
        echo "listen = 127.0.0.1:9000" >> "$PHP_FPM_CONF"
    fi
    echo "PHP-FPM configurado para escuchar en 127.0.0.1:9000."
}

# 5. Configurar MariaDB
setup_mariadb() {
    echo "Configurando MariaDB..."
    mysql_install_db --datadir=/data/data/com.termux/files/usr/var/lib/mysql
    mysqld_safe --datadir=/data/data/com.termux/files/usr/var/lib/mysql &
    sleep 5
    mysqladmin -u root password "$MYSQL_ROOT_PASSWORD"
    echo "Contraseña de root establecida: $MYSQL_ROOT_PASSWORD"
}

# 6. Descargar y configurar phpMyAdmin
setup_phpmyadmin() {
    echo "Instalando phpMyAdmin..."
    mkdir -p "$WEB_DIR"
    cd "$WEB_DIR"
    wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
    tar -xzf phpMyAdmin-latest-all-languages.tar.gz
    EXTRACTED_DIR=$(find "$WEB_DIR" -maxdepth 1 -type d -name "phpMyAdmin-*")
    if [ -n "$EXTRACTED_DIR" ]; then
        mv "$EXTRACTED_DIR" "$PHP_MYADMIN_DIR"
        echo "phpMyAdmin renombrado a $PHP_MYADMIN_DIR."
    else
        echo "Error: No se encontró la carpeta phpMyAdmin después de la extracción."
        exit 1
    fi
    rm phpMyAdmin-latest-all-languages.tar.gz
    cd "$PHP_MYADMIN_DIR"
    cp config.sample.inc.php config.inc.php
    sed -i "s/\$cfg\['blowfish_secret'\] = '';/\$cfg\['blowfish_secret'\] = '$(openssl rand -base64 32)';/" config.inc.php
    echo "phpMyAdmin configurado correctamente."
}

# 7. Crear archivo phpinfo.php
create_phpinfo() {
    echo "Creando archivo phpinfo.php..."
    echo "<?php phpinfo(); ?>" > "$WEB_DIR/phpinfo.php"
    echo "Archivo phpinfo.php creado en $WEB_DIR."
}

# 8. Iniciar servicios
start_services() {
    echo "Iniciando servicios..."
    pkill -f httpd
    pkill -f nginx
    pkill -f caddy
    check_port 8088
    php-fpm
    caddy start
    mysqld_safe --datadir=/data/data/com.termux/files/usr/var/lib/mysql &
    echo "Servicios iniciados correctamente."
}

# 9. Mensaje final
final_message() {
    echo "---------------------------------------------------------------"
    echo "La instalación del entorno PHP con Caddy se ha completado."
    echo "Accede a phpMyAdmin en: http://localhost:8088/db_admin"
    echo "Accede a phpinfo en: http://localhost:8088/phpinfo.php"
    echo "Usuario MariaDB: root | Contraseña: $MYSQL_ROOT_PASSWORD"
    echo "---------------------------------------------------------------"
}

# Función principal
main() {
    install_dependencies
    configure_caddy
    configure_php_fpm
    setup_mariadb
    setup_phpmyadmin
    create_phpinfo
    start_services
    final_message
}

main
