#!/bin/bash

BASE_DIR="/home/pi/sambashare"

# Solicitar el nombre del proyecto al usuario
read -p "Ingrese el nombre del proyecto Flask: " PROJECT_NAME

# Validar que se ingresó un nombre
if [ -z "$PROJECT_NAME" ]; then
    echo "Error: No se ingresó un nombre para el proyecto."
    exit 1
fi

PROJECT_PATH="$BASE_DIR/$PROJECT_NAME"

# Verificar que la carpeta sambashare existe
if [ ! -d "$BASE_DIR" ]; then
    echo "Error: La carpeta $BASE_DIR no existe. Asegúrate de configurarla previamente."
    exit 1
fi

# Crear la estructura de carpetas para el proyecto Flask
echo "Creando estructura de carpetas para el proyecto Flask..."
mkdir -p "$PROJECT_PATH/app/static"
mkdir -p "$PROJECT_PATH/app/templates"
mkdir -p "$PROJECT_PATH/instance"
mkdir -p "$PROJECT_PATH/tests"

# Crear archivos básicos del proyecto
echo "Creando archivos base del proyecto..."
cat << EOF > "$PROJECT_PATH/app/__init__.py"
from flask import Flask

def create_app():
    app = Flask(__name__)
    app.config.from_mapping(
        SECRET_KEY='dev',  # Cambiar por una clave segura en producción
    )

    @app.route('/')
    def hello():
        return "Hello, Flask!"

    return app
EOF

cat << 'EOF' > "$PROJECT_PATH/app/routes.py"
# Aquí se pueden definir rutas adicionales para la aplicación
EOF

cat << 'EOF' > "$PROJECT_PATH/config.py"
# Configuraciones adicionales para Flask pueden ir aquí
EOF

cat << 'EOF' > "$PROJECT_PATH/instance/config.py"
# Configuraciones específicas de instancia (no versionar)
EOF

cat << EOF > "$PROJECT_PATH/tests/test_app.py"
import pytest
from app import create_app

@pytest.fixture
def app():
    app = create_app()
    return app

def test_hello(client):
    response = client.get('/')
    assert response.data == b'Hello, Flask!'
EOF

cat << EOF > "$PROJECT_PATH/wsgi.py"
from app import create_app

app = create_app()

if __name__ == "__main__":
    app.run(debug=True)
EOF

cat << EOF > "$PROJECT_PATH/requirements.txt"
Flask
pytest
pdfplumber
pandas
numpy
openpyxl
xlrd
pillow
pytesseract
EOF

# Crear entorno virtual e instalar dependencias del proyecto
echo "Creando entorno virtual e instalando dependencias del proyecto..."
python3 -m venv "$PROJECT_PATH/venv"
source "$PROJECT_PATH/venv/bin/activate"
pip install -r "$PROJECT_PATH/requirements.txt"

# Ajustar permisos para la carpeta
echo "Ajustando permisos de $PROJECT_PATH..."
sudo chown -R pi:sambashare "$PROJECT_PATH"
sudo chmod -R 775 "$PROJECT_PATH"

# Instalar tree si no está disponible
if ! command -v tree &> /dev/null; then
    echo "Instalando tree para visualizar la estructura del proyecto..."
    sudo apt update && sudo apt install -y tree
fi

# Mostrar estructura final del proyecto
echo "Estructura creada:"
tree "$PROJECT_PATH"

# Mensaje final
echo "--------------------- SUCCESS -----------------------"
echo "Proyecto Flask creado dentro de: $PROJECT_PATH"
echo "Para ejecutarlo:"
echo "1. Activa el entorno virtual: source $PROJECT_PATH/venv/bin/activate"
echo "2. Ejecuta: python $PROJECT_PATH/wsgi.py"
echo "-----------------------------------------------------"
