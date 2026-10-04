# Image de la version web : nginx + build/web déjà construit.
#
#   flutter build web --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://…
#   docker build -f deploy/web/Dockerfile -t eteelo-web:<version> .
#
# Construit depuis la RACINE du dépôt (le contexte doit contenir build/web).
FROM nginx:1.27-alpine
COPY deploy/web/nginx.conf /etc/nginx/conf.d/default.conf
COPY build/web /usr/share/nginx/html
