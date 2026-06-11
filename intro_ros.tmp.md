Introduction à ROS2 avec Turtlebot4
===================================

La formation sera conduite avec comme support le robot TurtleBot 4.
Base de documentation : https://turtlebot.github.io/turtlebot4-user-manual/)

L'évaluation sera faite par un exposé de 15mn durant la dernière séance qui expliquera votre cheminement durant toutes les séances. L'exposé commencera par une présentation (très succinte) de ROS, puis il détaillera les différentes étapes et expérimentation que vous avez faite.
Ainsi, durant toutes vos expérimentations, prenez des photos et des vidéos pour alimenter l'exposé.

# Préliminaires

- connexion au PC: etudiant / _turtlebot4
- vérifier que le PC est connecté au réseau wifi: RHOBAN_100 / h12D!5j_
- placer le robot sur sa base d'acceuil (il se met en marche automatiquement)
- pour l'éteindre (plus tard):
    - le déplacer hors de sa base d'accueil, puis appuyer sur le bouton central (gros bouton circulaire) pendant 10 sec jusqu'à ce qu'il s'éteigne (il émet une mélodie).

- il y a deux composants dans le Turtlebot4: 
  - la raspberry pi 4 (ordinateur de bord, adjointe à une carte mère comportant notamment le petit écran d'information, des leds et des boutons) 
  - la base mobile, le "create 3".
  Les deux composants sont connectés au réseau wifi (RHOBAN_100).

- tous les robots (et les PC) sont sur le même réseau wifi, en revanche chaque paire Robot/PC est "compartimentée" (par des ROS_DOMAIN_ID, cf. partie Multiple Robots) 

- le robot comporte un certain nombre de noeuds ROS, tout comme le create. Cela va nous permettre de le piloter depuis le PC.

# Premier pas avec ROS2

## Visualisaation et utilisation basique du robot

- le robot publie un certain nombre de topics. Elle correspondent aux capteurs, mais également aux actions possibles avec le robot. Pour lister les topics disponibles, tappez la commande suivante dans un terminal (pour ouvrir un terminal, cliquez sur "activités" puis chercher "terminal"):
```
ros2 topic list
```

- nous les explorerons un peu plus tard. Dans l'immédiat, pour voir l'étendue des possibilités, vous pouvez lancer la visualisation du robot. Pour cela, explorez la documentation Rviz2.
(à noter que la caméra n'est pas active tant que le robot est sur sa station d'accueil).
    - à quoi correspond le nuage de point rouge ?
    - observez l'image de la caméra, que voit-on en surimpression ?
    - en utilisant le bouton "add" sur la gauche, puis en ajoutant le pluggin "TF", faites en sorte d'afficher (seulement) le repère de base du robot (base_link).

- tout en concervant la fenêtre de visualisation:
    - ouvrez un autre terminal
    - tappez la commande suivante:
    ``` 
    ros2 run teleop_twist_keyboard teleop_twist_keyboard
    ```
    Cela permet de piloter de façon très grossière le robot avec les touches du clavier (il faut que le terminal ait le focus). Vous pouvez modifier la vitesse. Ca n'est pas trop trop pratique.
    - vous pouvez le piloter avec le joypad. Pour cela allumez le joypad (bouton central), contrôler que la led du joypad est bleue. Déplacez le robot en maintenant L1 ou R1 et en vous servant du joystick de gauche (!! l'appairage du joypad est parfois très lent !!).
    - deplacez le robot, qu'observez vous dans la fenêtre de visualisation ?
    - dans la fenêtre de visualisation, sur la gauche, changez la "Fixed Frame" de "base_link" à "odom". Déplacez de nouveau le robot. Qu'observez vous ?
    - A quoi fait référence le terme "odom" ?

## Exploration des topics

Le concept de topic est central dans ROS. Il permet d'obtenir et d'envoyer des informations aux différents composants du robots.

- Dans un terminal, exécutez la commande:
```
ros2 topic --help
```
En déduire la commande pour lister les différentes topic disponibles (déjà vue).
- repérez la topic liée à la batterie du robot, quel est son identifiant ?
- affichez l'état de la batterie (soyez patient, c'est un peu long, l'état de la battery n'est pas donné à haute fréquence). C'est toujours au moyen de `ros2 topic`, mais avec une autre commande
- pour avoir plus d'information, cherchez la définition du message lié à la topic de la batterie. Pour ce faire, utiliser les commandes
```
ros2 topic info <topic_id>
ros2 interface show <topic_type>
```
Vous obtiendrez des informations plus précise (si le message est bien rédigé!). Notamment, quelle est l'unité de la capacité de la batterie ?
- comparez avec la topic `/imu`
- à quoi sert cette dernière topic ?
- à quoi sert la commande `ros2 topic bw` ?
- explorez les topics suivantes (à quoi servent-elles?):
    - `/cliff_intensity`
    - `/dock_status`
    - `/hazard_detection`
    - `/ip`
    - `/joy`
    - `/odom`
    - `/wheel_vels`
    - `/diagnostics`
Répondez aux questions suivantes:
    - en quoi sont exprimées les vitesses des roues ?
    - quel sont les types des informations fournies par `odom` et à quoi servent-ils ?
 
- toujours en ligne de commande, en utilisant la topic `cmd_vel`, mais cette fois pour publier dedans, faite bouger le robot ! Le robot a un certain temps de latence, il faut publier plusieurs fois avant d'avoir un résultat, n'hésitez pas à consultez l'aide de la commande que vous utiliserez. 

## Ecriture d'un Noeud ROS

Dans cette partie, on va écrire notre premier noeud ROS.

- Testez le noeud proposé par la documentation du turtlebot4 ici:
 https://turtlebot.github.io/turtlebot4-user-manual/tutorials/first_node_python.html

- En vous inspirant de cet exemple, écrire un noeud (en python) dont la seule fonction est d'afficher un état partiel de la batterie:
  - sa tension 
  - sa température
  - sa capacité
  En indiquant les unités utilisées.

## Déplacements du robot

- Ecrire un noeud qui fait avancer le robot pendant 5 secondes, et le fait tourner sur lui-même pendant 5 secondes dans le sens trigo. Vous vous inspirerez de l'exemple pour publier dans la topic /cmd_vel

- Modifier le noeud précédent en intégrant la lecture du lidar (/scan). Faite en sorte que le robot tourne sur lui-même, et s'arrête lorsque qu'il fait face à un passage libre sur un mètre. A ce moment là, le robot avance d'un mètre. Concrètement:
    - le robot tourne sur lui-même.
    - l'arrête lorsqu'il fait face à un passage (suffisamment large pour lui) d'au moins 1 mètre.
    - le robot avance alors d'un mètre.

- intégrez l'affichage de l'odométrie au noeud précédent (/odom), et expliquez les informations qu'il fournit.

- En utilisant les informations fournies pas le topic /odom, écrivez un noeud permettant de se rendre à un point de coordonnées fournies par l'utilisateur sous forme cartésiennes (x,y). Dans un second temps, on pourra tenir compte d'une orientation cible fournie également par l'utilisateur.
Concrêtement, le robot se tournera vers sa cible, puis s'y rendra en ligne droite, et enfin, tournera sur lui-même pour prendre l'orientation cible.

- Modifiez le noeux précédent de telle sorte à éviter d'éventuel obstacle.

## Slam

- testez les fonctionnalités de slam et de navigation décrite dans la documentation.

# Annexes

## Installation de ROS et du Turtlebot4
- sous Ubuntu 22.04.4 (avec droit d'administrateur)

installation de 
- RO2 humble (https://docs.ros.org/en/humble/Installation/Ubuntu-Install-Debians.html)
- puis Turtlebot4 (https://turtlebot.github.io/turtlebot4-user-manual/)
```
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository universe -y
sudo apt update && sudo apt install curl -y
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
sudo apt update -y
sudo apt upgrade -y

sudo apt install -y ros-humble-desktop
echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
source /opt/ros/humble/setup.bash
sudo apt install -y ros-dev-tools
sudo rosdep init
rosdep update
source ~/.bashrc
sudo apt install -y ros-humble-turtlebot4-desktop
mkdir -p ~/turtlebot4_ws/src
cd ~/turtlebot4_ws/src
git clone https://github.com/turtlebot/turtlebot4.git -b humble
cd ~/turtlebot4_ws
rosdep install --from-path src -yi --rosdistro humble
colcon build --symlink-install
sudo apt install ros-humble-turtlebot4-navigation -y
echo "source ~/turtlebot4_ws/install/setup.bash" >> ~/.bashrc
cd ~
git clone https://github.com/moogly-jungle/TP_ROS.git
echo "L'installation est terminée ! Have fun ..."
```




