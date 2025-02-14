#!/bin/bash

echo "🔥 Iniciando la instalación de mejoras para tu terminal... 🔥"

# 1️⃣ **Actualizar el sistema y paquetes esenciales**
echo "📦 Actualizando paquetes..."
sudo apt update && sudo apt upgrade -y

# 2️⃣ **Instalar herramientas esenciales**
echo "🛠 Instalando herramientas de terminal..."
sudo apt install -y git curl wget zsh unzip net-tools

# 3️⃣ **Instalar Starship**
echo "🚀 Instalando Starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

# 4️⃣ **Configurar Starship**
echo "🖌 Configurando Starship..."
mkdir -p ~/.config
cat <<EOF > ~/.config/starship.toml
# Starship - Configuración Sobria y Funcional con Ruta Completa

format = """
[╭─](bold white) \
\$directory\$git_branch\$git_status\$cmd_duration\$battery\$memory_usage
[╰─](bold white)\$character
"""

# 📂 Directorio (Ruta completa)
[directory]
truncation_length = 0
truncate_to_repo = false
style = "bold white"

# 🌱 Git (Solo si estás en un repo)
[git_branch]
symbol = " "
style = "dimmed gray"
format = "[$symbol\$branch](\$style) "

[git_status]
style = "dimmed gray"
format = "([$all_status](\$style))"

# 🕒 Duración del último comando (Solo si tarda más de 500ms)
[cmd_duration]
min_time = 500
format = "[⏳ \$duration](dimmed gray) "

# 🔋 Estado de la batería (Solo si está por debajo del 20%)
[battery]
full_symbol = "🔋"
charging_symbol = "⚡"
discharging_symbol = "🔋"
disabled = false

[[battery.display]]
threshold = 20
style = "bold red"

# 🖥️ Uso de RAM (Solo si es mayor al 75%)
[memory_usage]
threshold = 75
format = "[🖥 \$ram_pct%](bold red) "
disabled = false

# ➜ Prompt con diseño sutil
[character]
success_symbol = "[➜](bold cyan) "
error_symbol = "[✖](bold red) "
EOF

# 5️⃣ **Configurar Starship en Bash y Zsh**
echo "🔧 Activando Starship en Bash y Zsh..."
echo 'eval "$(starship init bash)"' >> ~/.bashrc
echo 'eval "$(starship init zsh)"' >> ~/.zshrc

# 6️⃣ **Recargar la terminal para aplicar los cambios**
echo "🔄 Aplicando cambios..."
exec $SHELL

echo "✅ ¡Terminal mejorada con éxito! Reinicia tu terminal o abre una nueva sesión."
