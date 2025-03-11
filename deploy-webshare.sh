#!/bin/bash
# v.01 

# Pedir al usuario el puerto en el que quiere que escuche Caddy
echo -n "Ingrese el puerto en el que desea que escuche Caddy: "
read puerto

# Definir el nombre del contenedor en base al puerto
nombre_contenedor="caddy-${puerto}"

# Crear las carpetas necesarias para almacenar los archivos compartidos y la configuración de Caddy
mkdir -p ./shared ./caddy_data ./caddy_config

# Generar un nombre de usuario aleatorio con el formato usuarioXXX
# Se elige un número aleatorio entre 100 y 999 y se concatena con 'usuario'
numero=$(shuf -i 100-999 -n 1)
usuario="usuario${numero}"

# Generar una contraseña aleatoria de 12 caracteres que incluya al menos un guion (-) y no empiece con '-'
while true; do
    # Generar una cadena aleatoria de 12 caracteres alfanuméricos y con al menos un guion (-)
    contrasena=$(< /dev/urandom tr -dc 'A-Za-z0-9-' | head -c12)
    # Verificar que la contraseña contenga al menos un guion (-) y que no comience con '-'
    if [[ "$contrasena" == *"-"* && "${contrasena:0:1}" != "-" ]]; then
        break
    fi
done

# Mostrar el nombre de usuario y la contraseña generados
echo "========================================="
echo " CREDENCIALES GENERADAS PARA CADDY "
echo "========================================="
echo "Usuario:     $usuario"
echo "Contraseña:  $contrasena"
echo "========================================="

# Generar el hash de la contraseña utilizando caddy hash-password dentro de un contenedor temporal
hash_contrasena=$(docker run --rm caddy:latest caddy hash-password --plaintext "$contrasena")
# hash_contrasena=$(docker run --rm caddy:latest caddy hash-password -plaintext "test")


# Crear el archivo Caddyfile con la configuración de Caddy
cat <<EOL > Caddyfile
{
    email admin@example.com
}

:${puerto} {
    root * /srv/shared  # Configurar la raíz del servidor en la carpeta compartida
    file_server browse # Habilitar el listado de archivos en el navegador
    basic_auth * {
        $usuario $hash_contrasena  # Configurar autenticación básica con usuario y contraseña generados
    }
    # tls internal  # Utilizar TLS interno de Caddy para cifrar las conexiones
}
EOL

# Crear el archivo docker-compose.yml con la configuración del servicio
cat <<EOL > docker-compose.yml
version: '3.8'

services:
  ${nombre_contenedor}:
    image: caddy:latest  # Imagen de Caddy en Docker Hub
    container_name: ${nombre_contenedor}  # Nombre del contenedor basado en el puerto
    restart: unless-stopped  # Reiniciar el contenedor a menos que se detenga manualmente
    ports:
      - "${puerto}:${puerto}"  # Exponer el puerto dinámico
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro  # Montar el archivo de configuración
      - ./shared:/srv/shared:ro  # Carpeta compartida para servir archivos
      - ./caddy_data:/data  # Almacén de datos de Caddy
      - ./caddy_config:/config  # Configuración persistente de Caddy
    environment:
      - CADDY_ADMIN_DISABLED=true  # Deshabilitar la API de administración de Caddy
EOL

# Obtener la IP pública si está disponible
ip_publica=$(curl -s ifconfig.me)
if [[ $ip_publica =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "IP pública detectada: $ip_publica"
else
    ip_publica="No detectada"
fi

# Mensaje final indicando los detalles del despliegue
echo "========================================="
echo " CADDY DEPLOYMENT INFORMATION "
echo "========================================="
echo "Carpetas creadas:"
echo " - shared (Archivos servidos por Caddy)"
echo " - caddy_data (Datos de Caddy)"
echo " - caddy_config (Configuración de Caddy)"
echo ""
echo "Copiar los archivos que se desean servir en: ./shared"
echo ""
echo "El servidor está configurado para escuchar en el puerto: ${puerto}"
echo "Puedes acceder desde: http://$ip_publica:${puerto}"
echo "(Si la IP pública no está disponible, usa la IP local del servidor)"
echo "========================================="
echo "Para iniciar el servicio, ejecutar:"
echo "docker compose up -d"
echo "========================================="
