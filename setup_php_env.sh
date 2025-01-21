#!/bin/bash

# Rango de puertos a verificar
PORT_RANGE_START=8000
PORT_RANGE_END=8010

# Función para verificar si un puerto está en uso
is_port_in_use() {
    netstat -tuln | grep -q ":$1 "
}

# Buscar un puerto disponible en el rango
find_available_port() {
    for ((port=$PORT_RANGE_START; port<=$PORT_RANGE_END; port++)); do
        if ! is_port_in_use "$port"; then
            echo "$port"
            return
        fi
    done
    echo "0"  # Devuelve 0 si no se encuentra un puerto disponible
}

# Actualizar repositorios e instalar dependencias necesarias
echo "Actualizando repositorios e instalando dependencias necesarias..."
sudo apt update && sudo apt install -y apache2 php libapache2-mod-php mysql-server phpmyadmin unzip net-tools

# Verificar si Apache está en ejecución y en qué puerto
APACHE_PORT=$(sudo netstat -tuln | grep ':80 ' | awk '{print $4}' | sed 's/.*://')
if [ -n "$APACHE_PORT" ]; then
    echo "Apache ya está en ejecución en el puerto $APACHE_PORT."
    AVAILABLE_PORT=$(find_available_port)
    if [ "$AVAILABLE_PORT" -eq 0 ]; then
        echo "Error: No hay puertos disponibles en el rango $PORT_RANGE_START-$PORT_RANGE_END."
        exit 1
    else
        echo "Configurando Apache para usar el puerto $AVAILABLE_PORT..."
        sudo sed -i "s/Listen 80/Listen $AVAILABLE_PORT/" /etc/apache2/ports.conf
        sudo systemctl restart apache2
        echo "Apache está ahora configurado en el puerto $AVAILABLE_PORT."
    fi
else
    echo "Apache no estaba en ejecución. Configurando en el puerto 80."
fi

# Configuración de MySQL
echo "Configurando MySQL..."
sudo systemctl start mysql
sudo mysql_secure_installation

# Configuración de phpMyAdmin
echo "Configurando phpMyAdmin..."
sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

# Mensaje final
echo "--------------------- SUCCESS -----------------------"
echo "El ambiente global para PHP está configurado:"
echo "- Apache está corriendo en el puerto: ${AVAILABLE_PORT:-80}."
echo "- MySQL está instalado y configurado."
echo "- phpMyAdmin está disponible en: http://localhost:${AVAILABLE_PORT:-80}/phpmyadmin"
echo "-----------------------------------------------------"
