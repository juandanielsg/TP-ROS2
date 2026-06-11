# TP ROS2 — TurtleBot4

Dépôt des travaux pratiques ROS2 Humble avec simulation TurtleBot4 Standard sous Ignition Fortress (Gazebo).

---

## Contenu du dépôt

```
.devcontainer/
  devcontainer.json     Configuration VS Code Dev Containers

docker/
  Dockerfile            Image Docker (ROS2 Humble + TurtleBot4 + Ignition Fortress)
  docker-compose.yml    Configuration du conteneur (X11, montage workspace, GPU)
  entrypoint.sh         Source ROS2 automatiquement à chaque nouveau terminal
  start.sh              Lancement rapide sans VS Code
  worlds/
    empty.sdf           Monde vide local (sans dépendance réseau)

Lectures/               Notes et exercices de session (anglais)
TPs/                    Notes et exercices de session (français)
scripts/                Scripts utilitaires pour le robot physique
src/                    Packages ROS2 du workspace (à créer)
```

---

## Prérequis

| Outil | Version minimale | Remarque |
|---|---|---|
| OS | Linux | L'affichage X11 pour Gazebo et RViz2 ne fonctionne nativement que sous Linux |
| Docker Engine | 20.10 | [docs.docker.com/engine/install](https://docs.docker.com/engine/install/) |
| Docker Compose | v2 | Intégré à Docker Desktop ou via le plugin `docker-compose-plugin` |
| VS Code + extension Dev Containers | — | Uniquement pour la méthode 1 |

La première construction de l'image prend **10 à 20 minutes** (téléchargement de ROS2 Humble, Ignition Fortress et des packages TurtleBot4).

---

## Méthode 1 — VS Code Dev Containers (recommandée)

Permet d'éditer le code sur la machine hôte avec IntelliSense ROS2 complet, tout en exécutant dans le conteneur.

**Prérequis supplémentaire :** installer l'extension [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) dans VS Code.

1. Ouvrir le dépôt dans VS Code
2. `F1` → **Dev Containers: Reopen in Container**
3. VS Code construit l'image puis ouvre un terminal à l'intérieur du conteneur
4. Le workspace est disponible dans `/ros_ws`

L'accès X11 pour Gazebo est configuré automatiquement via `initializeCommand` dans `devcontainer.json`.

Pour reconstruire l'image après une modification du `Dockerfile` :
`F1` → **Dev Containers: Rebuild Container**

---

## Méthode 2 — Docker (terminal)

Pour lancer la simulation avec interface graphique sans VS Code.

```bash
cd docker/
./start.sh
```

Ce script autorise l'accès X11, démarre le conteneur en arrière-plan et ouvre un terminal interactif. Pour ouvrir des terminaux supplémentaires dans le même conteneur :

```bash
docker exec -it turtlebot4-sim bash
```

Pour arrêter le conteneur :

```bash
cd docker/
docker compose down
```

---

## Lancer la simulation

Une fois dans le conteneur :

```bash
# Monde vide (aucun obstacle)
ros2 launch turtlebot4_ignition_bringup turtlebot4_ignition.launch.py world:=empty

# Entrepôt (monde par défaut)
ros2 launch turtlebot4_ignition_bringup turtlebot4_ignition.launch.py world:=depot
```

---

## Créer un package ROS2

```bash
# Créer le dossier source si nécessaire
mkdir -p /ros_ws/src
cd /ros_ws/src

# Package Python
ros2 pkg create --build-type ament_python nom_du_package

# Package C++
ros2 pkg create --build-type ament_cmake nom_du_package

# Compiler le workspace
cd /ros_ws
colcon build --symlink-install
source install/setup.bash
```

Les fichiers créés dans `/ros_ws` sont synchronisés avec le dépôt sur la machine hôte grâce au montage défini dans `docker-compose.yml`.
