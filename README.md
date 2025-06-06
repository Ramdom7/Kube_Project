# Projet Kubernetes - Déploiement des application de IC Group
 
## Objectif

Ce projet a pour objectifs de  conteneuriser, configurer et déployer les applications du IC Group dans un cluster Kubernetes tout en assurant la persistance des données des différentes ressources.  
- Odoo 13.0 : ERP open source  
- pgAdmin 4 : Interface Web d'administration pour PostgreSQL  
- Application web développer avec Flask permettant l'accès aux deux services ci-dessus.  
  

---
 
## Prérequis
 
- Un cluster Kubernetes fonctionnel
- `kubectl` installé et configuré
- Docker installé pour build et push les images
- Accès à Docker Hub
- Git
 
---


# Deploiement de l'application ic-webapp avec Docker

## Creation d'un Dockerfile

```bash
# Image de base
FROM python:3.6-alpine

# Définit le répertoire de travail
WORKDIR /opt

# Copie les fichiers de l’application dans l’image
COPY . .

# Installe Flask version 1.1.2
RUN pip install flask==1.1.2

# Expose le port 8080
EXPOSE 8080

# Définit les variables d’environnement
ENV ODOO_URL="https://www.odoo.com"
ENV PGADMIN_URL="https://www.pgadmin.org"

# Lance l’application
ENTRYPOINT ["python", "app.py"]
```

## Tester le Dockerfile

Pour commencer, il faut build l'image qu'on a crée avec notre Dockerfile avec la commande : 
```bash
docker build -t ic-webapp:1.0
```
![docker build](./images/docker-build.JPG)

On peut vérifier que l'image s'est correctement build avec la commande :
```bash
docker image ls
```
![docker build](./images/docker-image-ls.JPG)

Puis lancer la création de l'application conteneurisée :
```bash
docker run -d --name test-ic-webapp -p 8080:8080 -e ODOO_URL="https://www.odoo.com" -e PGADMIN_URL="https://www.pgmain.org" ic-webapp:1.0
```
Pour vérifier que le conteneur s'est bien créé, on utilise la commande docker suivante :
```bash
docker ps -a
```
![docker ps](./images/docker-ps.JPG)

On peut voir que le conteneur est bien en running


On peut essayer d'accéder la page odoo :
![odoo interface (docker)](./images/odoo-interface.JPG)

Notre image est bien fonctionnelle, on va pouvoir créer un tag et push l'image vers notre compte Docker Hub :

```bash
docker login
docker tag ic-webapp:1.0 kbysh01/ic-webapp:1.0
docker push kbysh01/ic-webapp:1.0
```
![docker push](./images/docker-push.JPG)


On peut ensuite stopper et supprimer le conteneur de test avec les commandes docker suivantes :
```bash
docker stop <container id>
docker rm <container id>
```
![docker rm](./images/docker-rm.JPG)

# Déploiement des ressources Kubernetes

Voici les fichiers manifests utilisés dans cette partie : 
![Files list](./images/ls.JPG)

## Deploiement de l'application web

```bash
## Création d'un namespace pour isoler nos ressources
kubectl create ns icgroup 
  
## Déploiement de l'apprlication web (Deployment et Service)
kubectl apply -f ic-webapp-deployment -n icgroup  
kubectl apply -f ic-webapp-service -n icgroup  
```
## Deploiement de PostgreSQL
```bash
## Déploiement de l'application web (persitentVolume, Deployment, Service)
kubectl apply -f postgresql.yaml -n icgroup  
```
On va se connecter à notre base de données afin de créer l'utilisateur utiliser par odoo :
```bash
kubectl exec -it <pod name> -n icgroup -- bash
psql -U postgres
CREATE USER odoo WITH PASSWORD <password>;  
ALTER USER odoo CREATEDB;
```
![New user](./images/psql-create-user.JPG)
![New permission](./images/psql-add-permission.JPG)
Ainsi, nous avons pu créer l'utilisateur Odoo et l'autoriser à créer une nouvelle base de données.

## Deploiement de Odoo
```bash
## Déploiement de Odoo (persitentVolume, Deployment, Service)
kubectl apply -f odoo.yaml -n icgroup  
```
## Deploiement de pgAdmin
```bash
## Déploiement de pgAdmin (persitentVolume, Deployment, Service et configmap)
kubectl apply -f pgadmin.yaml -n icgroup  
```
## Vérification de l'ensemble des ressources

```bash
kubectl get all -n icgroup  
```
![Toutes les ressources](./images/get-all.JPG) 
On retrouve bien toutes nos ressources créées et utilisées par notre application !  

```bash
kubectl get cm -n icgroup  
```
![configmap](./images/get-cm.JPG) 
Ainsi que notre configMap ! 

```bash
kubectl get cm -n icgroup  
```
![pvc](./images/get-pvc.JPG) 
Et nos volumes ! 

## Vérification du fonctionnement de l'application

On peut tenter d'accéder à l'interface web de notre Odoo depuis notre navigateur :
```bash
http://172.180.0.29:30090 
```
Odoo est bien joignable, on accède bien à son interface web !
On va pouvoir créer une nouvelle base de donnée :
![Odoo db creation](./images/odoo-create-db.JPG) 
![Odoo interface](./images/odoo-new-db.JPG) 

On peut effectuer la même procédure pour pgAdmin : 
```bash
http://172.180.0.29:30091 
```
![pgAdmin login](./images/pgadmin-login.JPG) 
pgAdmin est bien joignable, on accède bien à son interface web !
On va pouvoir essayer de se connecter à notre base de donnée :
![pgAdmin connected](./images/pgadmin-connected.JPG)
Nous sommes à présent connecté à notre base de donnée postgresql !
A présent, on va essayer de se connecter à notre base de donnée odoo avec le mot de passe que nous avons créer :
![pgAdmin connection to odoo](./images/pg-admin-connect-to-server.JPG)  
![pgAdmin connected to odoo](./images/pgadmin-connected-to-odoo.JPG)  
Nous sommes bien authentifié et connecté à Odoo !

A présent, nous allons voir si on arrive à joindre Odoo et pgAdmin depuis notre interface web "ic-webapp" :
```bash
http://172.180.0.29:30001  
```
Voici l'interface web avec nos deux outils de disponibles accessible cette voici depuis le port 30001 :
![Interface web (30001)](./images/web-interface-30001.JPG)  

On peut tenter de joindre Odoo et se connecter avec les identifiants renseignés dans notre fichier manifest :
![Odoo login](./images/odoo-login.JPG)  
On se retrouve sur le menu d'Odoo ! 

On peut à présent retourner sur notre page web et tenter de joindre pgadmin depuis celle ci :
![pgAdmin login](./images/pgadmin-login.JPG)  
Une fois connecté, on retombe bien sur la page suivante :
![pgAdmin connected to odoo](./images/pgadmin-connected-to-odoo.JPG)  

Tout est fonctionnelle ! Notre application est prête à être utilisée.
