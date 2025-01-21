#!/bin/bash

# Actualizar paquetes del sistema
sudo apt update && sudo apt upgrade -y

# Instalar Python, pip y dependencias globales
sudo apt install -y python3 python3-pip python3-venv libmysqlclient-dev libpq-dev build-essential \
libpoppler-cpp-dev tesseract-ocr tesseract-ocr-eng libreoffice

# Instalar paquetes globales con pip
sudo pip3 install flask mysqlclient psycopg2-binary pandas numpy openpyxl xlrd pillow pytesseract

# Mostrar paquetes globales instalados
echo "Paquetes globales instalados:"
sudo pip3 freeze

# Crear un entorno virtual para el proyecto
mkdir -p ~/flask_env
cd ~/flask_env
python3 -m venv venv

# Activar el entorno virtual e instalar dependencias específicas
source venv/bin/activate
pip install pdfplumber

# Confirmar instalación de Flask y otros paquetes específicos del entorno
echo "Flask version (global):"
flask --version
echo "Paquetes del entorno virtual:"
pip freeze

# Mostrar mensajes de éxito
echo "--------------------- SUCCESS -----------------------"
echo "Herramientas globales instaladas correctamente:"
echo "- Python, pip"
echo "- Dependencias globales (Flask, MySQL, PostgreSQL, etc.)."
echo "Entorno virtual creado en ~/flask_env/venv."
echo "Dependencias específicas del proyecto instaladas."
echo "Para activarlo, ejecuta: source ~/flask_env/venv/bin/activate"
echo "-----------------------------------------------------"
