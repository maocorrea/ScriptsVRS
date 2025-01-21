#!/bin/bash

BASE_DIR="/var/www/html"

# Solicitar el nombre del proyecto al usuario
read -p "Ingrese el nombre del proyecto PHP: " PROJECT_NAME

# Validar que se ingresó un nombre
if [ -z "$PROJECT_NAME" ]; then
    echo "Error: No se ingresó un nombre para el proyecto."
    exit 1
fi

PROJECT_PATH="$BASE_DIR/$PROJECT_NAME"

# Crear la estructura de carpetas
echo "Creando estructura de carpetas para el proyecto PHP..."
mkdir -p "$PROJECT_PATH/public"
mkdir -p "$PROJECT_PATH/src"
mkdir -p "$PROJECT_PATH/logs"
mkdir -p "$PROJECT_PATH/config"

# Crear archivos básicos
echo "Creando archivos base del proyecto..."
cat << 'EOF' > "$PROJECT_PATH/public/index.php"
<?php
// Archivo de inicio del proyecto
require_once '../src/bootstrap.php';

echo "Hola, bienvenido a $PROJECT_NAME!";
EOF

cat << 'EOF' > "$PROJECT_PATH/src/bootstrap.php"
<?php
// Configuración básica del proyecto
require_once '../config/config.php';
EOF

cat << 'EOF' > "$PROJECT_PATH/config/config.php"
<?php
// Configuración general del proyecto
define('APP_NAME', '$PROJECT_NAME');
EOF

cat << 'EOF' > "$PROJECT_PATH/.gitignore"
# Ignorar carpetas y archivos innecesarios
/logs/*
/vendor/*
EOF

# Ajustar permisos
echo "Ajustando permisos para la carpeta del proyecto..."
sudo chown -R $USER:$USER "$PROJECT_PATH"
sudo chmod -R 755 "$PROJECT_PATH"

# Mensaje final
echo "--------------------- SUCCESS -----------------------"
echo "Proyecto PHP creado dentro de: $PROJECT_PATH"
echo "Estructura de carpetas:"
echo "- public/: Archivos accesibles públicamente (index.php, CSS, JS, etc.)"
echo "- src/: Código fuente (clases, funciones, lógica)."
echo "- config/: Configuración del proyecto."
echo "- logs/: Archivos de registro."
echo "-----------------------------------------------------"
