#!/bin/bash

CONTAINER_DIR="$HOME/php_container"
ENCRYPTED_ARCHIVE="$HOME/php_container.enc"
PASSWORD="alohomora"

# Función para verificar e instalar dependencias necesarias en Termux
install_dependencies_in_termux() {
    echo "Verificando dependencias en Termux..."
    if ! command -v git &> /dev/null; then
        echo "Instalando Git..."
        pkg update && pkg install -y git
    fi
    if ! command -v openssl &> /dev/null; then
        echo "Instalando OpenSSL..."
        pkg update && pkg install -y openssl
    fi
    if ! command -v proot &> /dev/null; then
        echo "Instalando Proot..."
        pkg update && pkg install -y proot tar
    fi
}

# Función para crear un contenedor
create_container() {
    echo "Creando el contenedor PHP aislado..."
    mkdir -p "$CONTAINER_DIR"

    # Copiar el sistema base de Termux al contenedor
    echo "Preparando el entorno PHP dentro del contenedor..."
    proot -0 cp -r /data/data/com.termux/files/usr/* "$CONTAINER_DIR"

    echo "Instalando paquetes dentro del contenedor..."
    proot -b "$CONTAINER_DIR" -0 bash -c "
        unset LD_PRELOAD &&
        apt update -y &&
        apt install -y apache2 php mariadb-server php-mysqli &&
        mkdir -p /var/www/html/php_projects &&
        echo '<?php phpinfo(); ?>' > /var/www/html/php_projects/index.php &&
        echo 'Contenedor PHP listo para usarse.'
    "

    # Cifrar el contenedor
    echo "Cifrando el contenedor con PBKDF2 y 100000 iteraciones..."
    tar -cf - -C "$HOME" php_container | openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -e -out "$ENCRYPTED_ARCHIVE" -k "$PASSWORD"
    rm -rf "$CONTAINER_DIR"
    echo "El contenedor ha sido cifrado y almacenado en $ENCRYPTED_ARCHIVE."
}

# Función para descifrar el contenedor
decrypt_container() {
    echo "Descifrando el contenedor con PBKDF2 y 100000 iteraciones..."
    mkdir -p "$CONTAINER_DIR"
    openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -d -in "$ENCRYPTED_ARCHIVE" -k "$PASSWORD" | tar -xf - -C "$HOME"
}

# Función para iniciar el contenedor
start_container() {
    echo "Iniciando el contenedor PHP..."
    proot -b "$CONTAINER_DIR" -0 bash -c "
        service apache2 start &&
        service mysql start &&
        echo 'Contenedor iniciado. Accede a http://localhost:8080/php_projects'
    "
}

# Función principal
main() {
    install_dependencies_in_termux

    if [ ! -f "$ENCRYPTED_ARCHIVE" ]; then
        echo "No se encontró un contenedor cifrado. Creándolo por primera vez..."
        create_container
    else
        echo "Contenedor cifrado encontrado. Descifrando..."
        decrypt_container
        start_container
    fi
}

main
