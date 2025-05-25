# Image de base
FROM python:3.6-alpine

# Définir le répertoire de travail
WORKDIR /opt

# Copier les fichiers de l’application dans l’image
COPY . .

# Installer Flask version 1.1.2
RUN pip install flask==1.1.2

# Exposer le port 8080
EXPOSE 8080

# Définir les variables d’environnement (valeurs par défaut optionnelles)
ENV ODOO_URL="https://www.odoo.com"
ENV PGADMIN_URL="https://www.pgadmin.org"

# Lancer l’application
ENTRYPOINT ["python", "app.py"]

