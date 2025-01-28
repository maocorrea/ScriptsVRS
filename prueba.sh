#!/bin/bash

# Token de acceso personal (codificado en base64)
ENCODED_TOKEN="Z2hwX1kyN3RmaTlTbFc0V1RxcVJPRmlIMEU4TTc2YjVWZzBCUEowNA=="

# Repositorio a clonar
REPO_URL="desarrollos-binariit/formulario_caracterizacion"

# Ruta de destino para clonar el repositorio
DEST_PATH="/data/data/com.termux/files/usr/share/apache2/default-site/htdocs"

# Comprobar si 'gh' está instalado
if ! command -v gh &> /dev/null; then
    echo "La herramienta 'gh' (GitHub CLI) no está instalada. Por favor, instálala primero."
    exit 1
fi

# Decodificar el token
GITHUB_TOKEN=$(echo "$ENCODED_TOKEN" | base64 --decode)

# Autenticarse con el token
echo "Autenticando con GitHub CLI..."
echo "$GITHUB_TOKEN" | gh auth login --with-token
if [ $? -ne 0 ]; then
    echo "Error: No se pudo autenticar en GitHub."
    exit 1
fi

# Clonar el repositorio en la ruta especificada
echo "Clonando el repositorio $REPO_URL en $DEST_PATH..."
gh repo clone "$REPO_URL" "$DEST_PATH"
if [ $? -ne 0 ]; then
    echo "Error: No se pudo clonar el repositorio."
    exit 1
fi

echo "Autenticación y clonación completadas con éxito."
