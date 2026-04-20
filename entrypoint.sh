#!/bin/bash
set -e

echo "Entrypoint verificar variable HOSTUSUCPANEL='$HOSTUSUCPANEL'"

chown -R www-data:www-data /var/www/html/uploads \
                            /var/www/html/cache || true

# Ejecuta el comando principal (p.ej. apache2)
exec "$@"