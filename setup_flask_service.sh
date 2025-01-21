#!/bin/bash

BASE_DIR="/home/pi/sambashare"

# Verificar que la carpeta sambashare existe
if [ ! -d "$BASE_DIR" ]; then
    echo "Error: La carpeta $BASE_DIR no existe. Asegúrate de configurarla previamente."
    exit 1
fi

# Buscar proyectos Flask (carpetas con wsgi.py)
echo "Buscando proyectos Flask en $BASE_DIR..."
PROJECTS=()
while IFS= read -r -d '' project; do
    PROJECTS+=("$project")
done < <(find "$BASE_DIR" -mindepth 1 -maxdepth 1 -type d -exec test -f {}/wsgi.py \; -print0)

if [ ${#PROJECTS[@]} -eq 0 ]; then
    echo "No se encontraron proyectos Flask en $BASE_DIR."
    exit 1
fi

echo "Proyectos detectados:"
for i in "${!PROJECTS[@]}"; do
    echo "$((i + 1)). $(basename "${PROJECTS[$i]}")"
done
echo "q. Cancelar y salir"

# Solicitar al usuario que elija un proyecto
read -p "Selecciona el número del proyecto que deseas montar como servicio (o 'q' para cancelar): " CHOICE

if [[ "$CHOICE" == "q" ]]; then
    echo "Operación cancelada por el usuario. Saliendo..."
    exit 0
fi

if [[ ! "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt "${#PROJECTS[@]}" ]; then
    echo "Selección inválida. Por favor, intenta nuevamente."
    exit 1
fi

SELECTED_PROJECT="${PROJECTS[$((CHOICE - 1))]}"
PROJECT_NAME=$(basename "$SELECTED_PROJECT")
SERVICE_FILE="/etc/systemd/system/$PROJECT_NAME.service"

echo "Configurando $PROJECT_NAME como servicio del sistema..."

# Crear el archivo de servicio
sudo bash -c "cat <<EOF > $SERVICE_FILE
[Unit]
Description=Flask Project: $PROJECT_NAME
After=network.target

[Service]
User=pi
Group=sambashare
WorkingDirectory=$SELECTED_PROJECT
Environment=\"PATH=$SELECTED_PROJECT/venv/bin\"
ExecStart=$SELECTED_PROJECT/venv/bin/python wsgi.py

[Install]
WantedBy=multi-user.target
EOF"

# Recargar systemd y habilitar el servicio
sudo systemctl daemon-reload
sudo systemctl enable "$PROJECT_NAME.service"
sudo systemctl start "$PROJECT_NAME.service"

# Verificar el estado del servicio
sudo systemctl status "$PROJECT_NAME.service"

# Mensaje final
echo "--------------------- SUCCESS -----------------------"
echo "El proyecto $PROJECT_NAME se ha configurado como un servicio."
echo "Se ejecutará automáticamente al iniciar el CT."
echo "Para verificar el servicio, usa: sudo systemctl status $PROJECT_NAME.service"
echo "-----------------------------------------------------"
