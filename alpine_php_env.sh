#!/bin/bash

# Actualizar repositorios y paquetes
echo "Actualizando repositorios y paquetes..."
apk update && apk upgrade -y

# Instalar Apache, PHP, MySQL y Git
echo "Instalando Apache, PHP, MySQL y Git..."
apk add apache2 php php-apache2 mariadb mariadb-client php-mysqli git curl

# Configurar Apache
echo "Configurando Apache..."
rc-update add apache2
rc-service apache2 start

# Configurar MySQL
echo "Configurando MySQL (MariaDB)..."
rc-update add mariadb
rc-service mariadb setup
rc-service mariadb start

# Configuración manual de MySQL
echo "Configuración manual de MySQL:"
echo "-------------------------------------------------------------"
echo "A continuación, deberás configurar el usuario y contraseña."
echo "Ejecuta los siguientes comandos dentro del cliente MySQL:"
echo "1. Establece la contraseña para root:"
echo "   ALTER USER 'root'@'localhost' IDENTIFIED BY 'tu_contraseña';"
echo "2. Opcional: Crea un nuevo usuario y dale permisos:"
echo "   CREATE USER 'nuevo_usuario'@'localhost' IDENTIFIED BY 'su_contraseña';"
echo "   GRANT ALL PRIVILEGES ON *.* TO 'nuevo_usuario'@'localhost' WITH GRANT OPTION;"
echo "3. Aplica los cambios:"
echo "   FLUSH PRIVILEGES;"
echo "-------------------------------------------------------------"
echo "Abriendo el cliente MySQL..."
mysql -u root

# Crear directorio para proyectos PHP
echo "Creando directorio para proyectos PHP..."
mkdir -p /var/www/localhost/htdocs/php_projects

# Configurar permisos para Apache
echo "Configurando permisos para Apache..."
chown -R apache:apache /var/www/localhost/htdocs/php_projects
chmod -R 755 /var/www/localhost/htdocs/php_projects

# Crear un archivo PHP de prueba
echo "Creando archivo PHP de prueba..."
echo "<?php phpinfo(); ?>" > /var/www/localhost/htdocs/php_projects/index.php

# Reiniciar servicios para aplicar cambios
echo "Reiniciando servicios..."
rc-service apache2 restart
rc-service mariadb restart

# Mensaje final
echo "--------------------- CONFIGURACIÓN COMPLETA -----------------------"
echo "El entorno PHP ha sido configurado exitosamente en Alpine Linux."
echo "Accede a tu proyecto en: http://localhost/php_projects"
echo "-------------------------------------------------------------------"
echo "Recuerda configurar manualmente las credenciales de MySQL."
echo "-------------------------------------------------------------------"
