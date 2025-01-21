#!/bin/bash

# Ruta de descarga y archivo
URL="https://github.com/zzet/fp-docker/raw/master/kindlegen_linux_2.6_i386_v2_9.tar.gz"
TEMP_DIR="/tmp/kindlegen_install"
INSTALL_DIR="/usr/local/bin"

# Crear carpeta temporal para la instalación
echo "Creando carpeta temporal para la instalación en $TEMP_DIR..."
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Descargar kindlegen
echo "Descargando kindlegen desde $URL..."
wget -q "$URL" -O kindlegen.tar.gz

# Extraer el archivo
echo "Extrayendo el archivo..."
tar -xvzf kindlegen.tar.gz

# Mover binario a la carpeta de binarios del sistema
echo "Instalando kindlegen en $INSTALL_DIR..."
sudo mv kindlegen "$INSTALL_DIR/"

# Verificar instalación
if command -v kindlegen &> /dev/null; then
    echo "kindlegen se instaló correctamente y está disponible en el sistema."
    kindlegen -locale es
else
    echo "Error: kindlegen no se instaló correctamente."
fi

# Limpiar archivos temporales
echo "Limpiando archivos temporales..."
rm -rf "$TEMP_DIR"

echo "Instalación completada."