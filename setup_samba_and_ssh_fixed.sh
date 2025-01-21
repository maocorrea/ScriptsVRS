#!/bin/bash

# Actualizar paquetes e instalar OpenSSH Server
sudo apt update && sudo apt install -y openssh-server

# Configurar SSH
sudo sed -i 's/^#Port 22/Port 22/' /etc/ssh/sshd_config
sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^UsePAM no/UsePAM yes/' /etc/ssh/sshd_config

# Validar configuración de SSH y reiniciar servicio
sudo sshd -t && sudo systemctl restart ssh

# Crear el script de instalación de Samba
cat << 'EOF' > install_samba.sh
#!/bin/bash

# Configuración fija
FOLDERPATH="/home/pi/sambashare"
USER="pi"

# Instalar Samba
sudo apt-get update && sudo apt-get install samba -y
sudo systemctl stop smbd

# Obtener información del sistema
HOSTNAME=$(hostname)
IPADDR=$(hostname -I | cut -f1 -d' ')
SMBVER=$(smbd --version)

# Crear la carpeta compartida
sudo mkdir -p $FOLDERPATH

# Resguardar archivo de configuración anterior de Samba
sudo mv /etc/samba/smb.conf /etc/samba/smb.conf.bak

# Crear nuevo archivo de configuración de Samba con configuración fija
printf "[global]
    log level = 1

[sambashare]
    comment = Folder Shared by Samba Server
    path = $FOLDERPATH
    public = yes
    read only = no
    writable = yes
    guest ok = no
    valid users = pi
    create mask = 0755
    directory mask = 0755
" | sudo tee /etc/samba/smb.conf

# Crear alias de host (opcional)
echo "$IPADDR $HOSTNAME" | sudo tee -a /etc/hosts

# Agregar usuario a Samba
sudo smbpasswd -a $USER

# Reiniciar servicio de Samba
sudo systemctl restart smbd

# Mostrar información de acceso
echo "--------------------- SUCCESS -----------------------"
echo "SAMBA $SMBVER was installed correctly"
echo "You can access your folder with:"
echo "\\\\$IPADDR\\sambashare"
echo "or"
echo "\\\\$HOSTNAME\\sambashare"
echo "With username: $USER"
echo "------------------------------------------------------"
EOF

# Dar permisos de ejecución al script y ejecutarlo
sudo chmod +x install_samba.sh
sudo ./install_samba.sh

# Crear el grupo para Samba y agregar usuario
sudo groupadd sambashare
sudo useradd -m -s /bin/bash pi || true  # Ignorar si el usuario ya existe
sudo smbpasswd -a pi
sudo usermod -aG sambashare pi

# Ajustar permisos para la carpeta compartida
sudo chown -R pi:sambashare /home/pi/sambashare
sudo chmod -R 775 /home/pi/sambashare

# Verificar configuración final
ls -ld /home/pi/sambashare