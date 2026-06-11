Introduction à ROS2 avec Turtlebot4
===================================

La formation sera conduite avec comme support le robot TurtleBot 4.
Base de documentation : https://turtlebot.github.io/turtlebot4-user-manual/

L'évaluation sera faite par un exposé de 15mn durant la dernière séance qui expliquera votre cheminement durant toutes les séances. L'exposé commencera par une présentation (très succincte) de ROS, puis il détaillera les différentes étapes et expérimentation que vous avez faite.
Ainsi, durant toutes vos expérimentations, prenez des photos et des vidéos pour alimenter l'exposé.

# Préliminaires

- connexion au PC: Rhoban / _turtlebot4
- vérifier que le PC est connecté au réseau wifi: RHOBAN_100 / h12D!5j_
- placer le robot sur sa base d'accueil (il se met en marche automatiquement)
- pour l'éteindre (plus tard):
    - le déplacer hors de sa base d'accueil, puis appuyer sur le bouton central (gros bouton circulaire) pendant 10 sec jusqu'à ce qu'il s'éteigne (il émet une mélodie).

- il y a deux composants dans le Turtlebot4: 
  - la raspberry pi 4 (ordinateur de bord, adjointe à une carte mère comportant notamment le petit écran d'information, des leds et des boutons) 
  - la base mobile, le "create 3".
  Les deux composants sont connectés au réseau wifi (RHOBAN_100).

- tous les robots (et les PC) sont sur le même réseau wifi, en revanche chaque paire Robot/PC est "compartimentée" (par des ROS_DOMAIN_ID, cf. partie Multiple Robots) 

- le robot comporte un certain nombre de nœuds ROS, tout comme le Create3. Cela va nous permettre de le piloter depuis le PC.

# Premiers pas avec ROS2

## Commandes utiles

Package :​

    ros2 run <nom_package> <nom_executable>​
    ros2 launch <nom_package> <nom_launch>​
    rqt_graph​

Node :​

    ros2 node list​
    ros2 node info <nom_node>​


Topic :​

    ros2 topic list​
    ros2 topic info <nom_topic>​
    ros2 topic type <nom_topic>​
    ros2 topic echo <nom_topic>​
    ros2 topic pub <fréquence> <nom_topic> <commande>​

Service :​

    ros2 service list​
    ros2 service type <nom_service>​
    ros2 service find <nom_service>
    ros2 service call <nom_service> <type_service> <arguments>​

Action : ​

    ros2 action list​
    ros2 action info <nom_action>​
    ros2 action send_goal <nom_action> <type_action> <valeurs>​

## Visualisation et utilisation basique du robot

- Le robot publie un certain nombre de topics. Ils correspondent aux capteurs, mais également aux actions possibles avec le robot. Pour lister les topics disponibles, tapez la commande suivante dans un terminal (pour ouvrir un terminal, cliquez sur "activités" puis chercher "terminal", ou utilisez le raccourci `CTRL + ALT + T`):
```
ros2 topic list
``` 

- Nous les explorerons un peu plus tard. Dans l'immédiat, pour voir l'étendue des possibilités, vous pouvez lancer la visualisation du robot. Pour cela, explorez la documentation Rviz2 et du Turtlebot4. Vous pouvez notamment regarder les différents arguments que l'ont peut passer à une commande `ros2 launch` en utilisant l'option `-s` ou `--show-args`.
(à noter que la caméra n'est pas active tant que le robot est sur sa station d'accueil et qu'il faudra probablement modifier à l'aide de l'interface graphique le topic utilisé par Rviz et le remplacer un topic se terminant par `image_raw`) {nom du topic en entier : `/tbot<robot_number>/oakd/rgb/preview/image_raw`}.
    - à quoi correspond le nuage de point rouge ?
    - observez l'image de la caméra, que voit-on en surimpression ? 
    - en utilisant le bouton "add" sur la gauche, puis en ajoutant le plugin "TF", faites en sorte d'afficher (seulement) le repère de base du robot (base_link).

- Tout en concervant la fenêtre de visualisation:
    - ouvrez un autre terminal
    - tapez la commande suivante:
    ``` 
    ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args --remap cmd_vel:=/tbot<robot_number>/cmd_vel
    ```
    Cela permet de piloter de façon très grossière le robot avec les touches du clavier (il faut que le terminal ait le focus). Vous pouvez modifier la vitesse. Cependant, ce mode de téléopération n'est pas très pratique.
    - vous pouvez le piloter avec la manette. Pour cela allumez la manette (bouton home), contrôler que la led de la manette est bleue. Déplacez le robot en maintenant L1 ou R1 et en vous servant du joystick de gauche (Attention, l'appairage de la manette est parfois très lent).
    - déplacez le robot, qu'observez vous dans la fenêtre de visualisation ?
    - dans la fenêtre de visualisation, sur la gauche, changez la "Fixed Frame" de "base_link" à "odom". Déplacez de nouveau le robot. Qu'observez-vous ?
    - à quoi fait référence le terme "odom" ?

## Exploration des topics

Le concept de topic est central dans ROS. Il permet d'envoyer et de recevoir des messages aux différents composants du robots.

- Dans un terminal, exécutez la commande:
```
ros2 topic --help
```
En déduire la commande pour lister les différentes topic disponibles (déjà vue).
{soluce: `ros2 topic list`}

- repérez le topic liée à la batterie du robot, quel est son identifiant ?
{soluce: `/tbot<robot_number>/battery_state`}
- affichez l'état de la batterie (soyez patient, c'est un peu long, l'état de la batterie n'est pas donné à haute fréquence). C'est toujours au moyen de `ros2 topic < ... >`, mais avec une autre commande
{soluce: `ros2 topic echo /tbot<robot_number>/battery_state`}
- pour avoir plus d'information, cherchez la définition du message lié au topic de la batterie. Pour ce faire, utiliser les commandes suivantes :
```
ros2 topic info <topic_id>
ros2 interface show <topic_type>
```
Vous obtiendrez des informations plus précises (si le message est bien rédigé!). Notamment, quelle est l'unité de la capacité de la batterie ?
- comparez avec le topic `/tbot<robot_number>/imu`
- à quoi sert ce dernier topic ?
- à quoi sert la commande `ros2 topic bw` ?
{soluce: à donner une évaluation de la bande passante en octet/sec}
- explorez les topics suivantes (à quoi servent-ils?):
    - `/tbot<robot_number>/cliff_intensity`
    - `/tbot<robot_number>/dock_status`
    - `/tbot<robot_number>/hazard_detection`
    - `/tbot<robot_number>/ip`
    - `/tbot<robot_number>/joy`
    - `/tbot<robot_number>/odom`
    - `/tbot<robot_number>/wheel_vels`
    - `/tbot<robot_number>/diagnostics`

- répondez aux questions suivantes:
    - en quoi sont exprimées les vitesses des roues ?
{soluce: `ros2 topic info /tbot<robot_number>/wheel_vels` puis `ros2 interface show irobot_create_msgs/msg/WheelVels`}
    - quel sont les types des informations fournies par `odom` et à quoi servent-ils ?
    L'orientation d'un robot est un concept compliqué, il ne s'agit pas de le comprendre totalement à notre niveau. Néanmoins, on retiendra que plusieurs systèmes sont possibles: Euler, matrices de rotation, quaternion. N'hésitez pas à chercher un peu. On peut passer de l'un à l'autre grâce à cet outil: https://www.andre-gaschler.com/rotationconverter/.
    {soluce: PoseWithCovariance, Pose, Point, Quaternion}

- toujours en ligne de commande, en utilisant le topic `cmd_vel`, mais cette fois pour y publier un message et faire bouger le robot ! Le robot a un certain temps de latence, il faut publier plusieurs fois avant d'avoir un résultat, n'hésitez pas à consultez l'aide de la commande que vous utiliserez. 

## Écriture d'un nœud ROS

Dans cette partie, nous allons écrire un premier nœud ROS.

- Testez le nœud proposé par la documentation du turtlebot4 ici:
 https://turtlebot.github.io/turtlebot4-user-manual/tutorials/first_node_python.html
 (attention, le bouton dont parle l'exemple est le bouton du Create3, pas du "chapeau" Clearpath robotics au dessus) {info : attention, penser à rajouter le namespace `/tbot<robot_number>` au topic auquel le node s'abonne.}

- En vous inspirant de cet exemple, écrire un nœud (en python) dont la seule fonction est d'afficher un état partiel de la batterie (en indiquant les unités des valeurs):
  - sa tension 
  - sa température
  - sa capacité

## Déplacements du robot

- Écrire un nœud qui fait avancer le robot pendant 5 secondes, et le fait tourner sur lui-même pendant 5 secondes dans le sens trigonométrique. Vous vous inspirerez de l'exemple pour publier dans le topic `cmd_vel`

- Modifier le nœud précédent en intégrant la lecture du lidar (`scan`). Faites en sorte que le robot tourne sur lui-même, et s'arrête lorsque qu'il fait face à un passage libre sur un mètre. À ce moment là, le robot avance d'un mètre. Concrètement:
    - le robot tourne sur lui-même.
    - s'arrête lorsqu'il fait face à un passage (suffisamment large pour lui) d'au moins un mètre.
    - le robot avance alors d'un mètre.

- Intégrez l'affichage de l'odométrie au nœud précédent (`odom`), et expliquez les informations qu'il fournit.

- En utilisant les informations fournies pas le topic `odom`, écrivez un nœud permettant de se rendre à un point de coordonnées fournies par l'utilisateur sous forme cartésiennes (x,y). Dans un second temps, on pourra tenir compte d'une orientation cible fournie également par l'utilisateur.
Concrètement, le robot se tournera vers sa cible, puis s'y rendra en ligne droite, et enfin, tournera sur lui-même pour prendre l'orientation cible.

- Modifiez le nœud précédent de telle sorte à éviter d'éventuels obstacles.

## Slam

- Testez les fonctionnalités de slam et de navigation décrites dans la documentation.

# Annexes

## Installation de ROS et du Turtlebot4
- sous Ubuntu 22.04 (avec droits d'administrateur)

Installation de : 
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







