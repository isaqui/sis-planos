#!/bin/bash
set -e

echo "Entrypoint verificar variable HOSTUSUCPANEL='$HOSTUSUCPANEL'"

chown -R www-data:www-data /var/www/html/imagenes \
                            /var/www/html/docs \
                            /var/www/html/importacion \
							/var/www/html/cron_jobs \
                            /var/www/html/doc_imp || true

# Ejecuta el comando principal (p.ej. apache2)
exec "$@"