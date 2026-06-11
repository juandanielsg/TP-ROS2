- Connexion au PC: etudiant / _turtlebot4
Réseau wifi: RHOBAN_100 / h12D!5j_


En général:
- problème de caméra, en particulier sur le 4
- gros problème de charge de batterie: éteindre le lidar !...


doc spécifique TurtleBot: https://turtlebot.github.io/

installation de ROS2 Humble : https://docs.ros.org/en/humble/Installation/Ubuntu-Install-Debians.html

Plan de travail pour les 3 jours

Séance 1:
- Intro sur ROS (1h)
- Découverte, connexions (install).
- allumage du Turtle bot
- découverte de Rvis
- Explication de l'architecture de travail.
- explicatioin de l'évaluation: un slideware à dérouler et à faire au fur et à mesure des 3 jours.
  - photos/vidéos.

Séance 2:
- découverte des topics
- commande des base ros2 (ros2 topic, etc...)
- Workspace
- Mon premier noeud ROS: voir livre
- Ecriture d'un noeud de monitoring du Turtlebot.
  - de l'affichage
  - batterie
  - bumpers
  - boutons
  - joypad
- les rqt graphs ? (revoir le livre et toutes les notions)

Séance 3:
- pilotage du robot.
- pilotage du robot avec le joystick
- utiliser les paramètres !!

Séance 4:
- Odometrie: comprendre le noeud odom
- un noeud ros pour se rendre à un point donné, avec l'odométrie
- se rendre à un point donné avec l'odométrie en évitant les obstacles au bumper
- se rendre à un point donné avec l'odométrie en évitant les obstacle au lidar. 

- puis utiliser le navigator (qui fait tout tout seul)

Séance 5:
- navigation / slam
- mise en forme de la carte
- mission prise de photo, on clique sur la carte, et le robot va prendre une photo

Séance 6:
- slide d'une exposé de 15mn, retour sur les 3 jours photos et vidéos


TODO:
- first node
- making map

- qos_profile_sensor_data ?...

*** First node:
https://turtlebot.github.io/turtlebot4-user-manual/tutorials/first_node_python.html


dock

pour avoir de la documentation
ros2 interface show sensor_msgs/msg/BatteryState

ip address

Accès Routeur: 192.168.13.1 / passeword rhoban classique: RhobanW00dSt0ck
Réseau wifi: RHOBAN_100 / h12D!5j_

connexion aux PC: etudiant/_turtlebot4

ros-pc1: 64:5D:86:C7:17:D5 ==> 192.168.13.103
ros-pc2: D4:25:8B:93:30:0F ==> 192.168.13.105
ros-pc3: 64:5D:86:C7:17:C6 ==> 192.168.13.107
ros-pc4: 4C:1D:96:38:B4:4F ==> 192.168.13.108
ros-pc5: 4C:1D:96:39:3D:D4 ==> 192.168.13.111


pour se connecter à la raspberry des turtlebot: ubuntu/turtlebot4
on ne se connecte pas au create.
mac Turtle 1:
  rasp: D8:3A:DD:36:AD:AD ==> 192.168.13.114
  create: 4C-B9-EA-2E-8B-A3 ==> 192.168.13.115
mac Turtle 2:
  rasp: D8-3A-DD-B8-71-D1 ==> 192.168.13.101
  create: 50-14-79-44-68-EF ==> 192.168.13.102
mac Turtle 3:
  rasp: D8-3A-DD-34-F1-8C ==> 192.168.13.109
  create: 4C:B9:EA:2E:8B:E6 ==> 192.168.13.110
mac Turtle 4: 
  rasp : D8-3A-DD-36-AE-7E   ==> 192.168.13.100
  create: 4C-B9-EA-2E-96-7D  ==> 192.168.13.104
mac Turtle 5: 
  rasp : D8:3A:DD:40:AC:69   ==> 192.168.13.116
  create: 4C-B9-EA-2E-94-FC  ==> 192.168.13.117 


Essaie de déplacement au clavier: ok
> ros2 run teleop_twist_keyboard teleop_twist_keyboard

manette:
> bluetoothctl 
> scan on

Tom:
http://intranet.iut.u-bordeaux.fr/info/assa/json_form/edit/6373?token=75279fd16181b1619dbfd53b

Valentin:
http://intranet.iut.u-bordeaux.fr/info/assa/json_form/edit/6382?token=f8578d05881e423661b834ef


NOTE: docké, le turtlebot n'a pas le mm comportement (power saving)
Note: source code: https://github.com/turtlebot

TODO:
> script qui monitore quel robot est en ligne

source turtlebot4_ws/install/setup.bash



lancement de rviz:
> ros2 run rviz2 rviz2
ou avec le modèle du turtlebot:
> ros2 launch turtlebot4_viz view_model.launch.py (vue modele)
> ros2 launch turtlebot4_viz view_robot.launch.py (vue robot)
  (prendre le base_link comme frame)
> 

=> modifier la frame: base_link
=> ajout du scan: "add" puis "by topic" puis prendre "/scan" => laserscan

la caméra marche pas... vu qu'une fois ... (pourquoi ?...)


** explorer les topics

Hazard detection: il n'y a que le bumper ?

** explorer les functions

Comment connecter le create au réseau ?...

Les paquets sont bien installés.

* pour la gestion du réseau, de base, pas de ifconfig, ni de iwconfig. On utilise nmcli
ou hostname -I pour avoir les adresses IP actives.

* journalctl pour voir le log de systemd, utile en cherchant NetworkManager pour voir l'historique des connexions.
(ex: journalctl -u NetworkManager.service | grep "Apr 10 19" > ~/log-connexion.txt)
hostname -I
nmcli radio wifi on
nmcli device wifi list
sudo nmcli device wifi connect RHOBAN-2-4Ghz --ask
sudo nmcli device wifi connect RHOBAN --ask

sudo netplan generate
sudo netplan apply
sudo nmcli con down id "netplan-wlan0-RHOBAN"
sudo nmcli con up id "netplan-wlan0-RHOBAN"

oublier une connexion:
nmcli connection delete id <connection name>


sudo rmmod brcmfmac
sudo modprobe brcmfmac roamoff=1
sudo modprobe brcmfmac roamoff=1 feature_disable=0x82000     // ???
sudo nmcli con up id "netplan-wlan0-RHOBAN" 

en retirant les usb, et en connectant le robot au doc, ca a reconnecté ...

A mettre dans /etc/modprobe.d/brcmfmac.conf (?)

en meme temps on a fait un apt update && apt upgrade

sudo /Applications/Wireshark.app/Contents/MacOS/Wireshark

"sudo nmcli device wifi connect RHOBAN --ask"
a marché en donnant le mot de passe, mais il se déconnecte au bout d'une minute ...
puis il ne le voit plus...

cat /var/log/syslog | grep -Ei 'dhcp'

sudo nmcli device wifi connect MAKERUS password "makers!!!"

adresse du create 3: 192.168.1.171

TODO:
- mettre la machine virtuelle au carré
  (c'est mieux de fonctionner sous Ubuntu, compatible avec tout ce qu'on va faire, y compris EcoSat)
  [done]
- unpacking du turtlebot en suivant tout le tuto
  - installation de ros2
  [done]
  - relecture du livre sur ros2
  - https://www.youtube.com/watch?v=QN01AXjoLdQ
- test de toutes les features du turtlebot
- dérouler un TP
  - découverte des features. Les concepts de base de ROS
  - navigation
  - perception
  - evitement d'obstacle
  - cartographie
  - mission ?


Manette:
voir tuto: https://turtlebot.github.io/turtlebot4-user-manual/setup/basic.html#turtlebot-4-controller-setup


idée d'exo:
- modifier le controle par la manette
- faire un controleur au clavier (en langue naturelle ?...)
- regarder les roues: faire de l'odométrie !... (en se branchant la topic /wheel_vel /wheel_tick)
- en ros: faire des comportements élémentaires pour se familiariser aux topics, actions...
    avancer et se stopper au bumper, au détecteur IR, etc..
    tourner..

idées:
- un noeud ros pour les paramètres ?
- un jeu de test de setup, passed, etc...
- utiliser la manette pour les tests ?
- faire du fast DDS ?...
- génial les topics quand meme. Il faut le mettre en oeuvre rapidement sur EcoSat !...



ros2 topic list – Find all Topics on your graph
ros2 topic echo – Print the data going through a Topic
ros2 topic info/type – Get more details about a Topic
ros2 topic pub – Publish to a topic from the terminal
ros2 topic hz – Check if your publishers/subscribers manage to follow the rhythm
ros2 topic bw – Check how much data is going through a Topic
Find topic info directly from a node’s name
ros2 topic: A complete tool set to debug your Topics

apt install ros-humble-gazebo-ros (?)


Essayer la simulation sur l'ancienne machine !

compilation de ignition gazebo 
libgz-cmake3
libgz-cmake3-dev
libgz-utils2-dev
gz-tools2
libgz-cmake3-dev libgz-tools2-dev libgz-utils2-cli-dev
libgz-plugin2-dev
libgz-utils2-cli
libgz-utils2-dev

Install du livre:
* installation de ros2 ici: https://docs.ros.org/en/humble/Installation/Ubuntu-Install-Debians.html
> sudo apt install ros-humble-desktop
> sudo apt install ros-humble-ros-base (pas indiqué dans le livre)
> sudo apt install ros-dev-tools (pas indiqué dans le livre)
> source /opt/ros/humble/setup.bash
  - à mettre dans le bashrc  


==> faire un docker ? <==


A essayer:
ros2 launch turtlebot4_navigation slam.launch.py



ouvrir ssh sur le PC:

sudo apt install openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh


- construction de map

> ros2 launch turtlebot4_navigation slam.launch.py

Attendre , la map n'apparait que quelques instants après le lancement le temps que la map s'initialise.

pour la sauvegarde de la map:
> ros2 service call /slam_toolbox/save_map slam_toolbox/srv/SaveMap
(ca ne marche pas en mettant un nom de map)

Pour désactiver les réflexes du create3:
explorer les params de motion_control
> ros2 node list
> ros3 param list /tbo2/motion_control
puis
> ros2 param set /tbot2/motion_control reflexes.REFLEX_BUMP false

TODO: désactiver tous les reflexes...


TODO:

- remonter le robot 1

Finir les installations
- configurer les derniers robots
- supprimer le .tp-ros du PC1
- configurer les adresses wifi sur le rooter
- mettre en oeuvre les ROS_DOMAIN pour les couples 1,4,5
- regarder les dépendances de l'exemple (les fichiers xml du noeud)

Désactiver les controles moteurs (regarder le graphe)
ce sont les reflexes du create du noeud /motion_control, pour les désactiver, on doit pouvoir 
jouer avec les paramètres: https://iroboteducation.github.io/create3_docs/api/reflexes/
> ros2 param list /motion_control
  (marche quand ça veut...)
> ros2 param set /motion_control reflexes_enable

un script de recherche d'information
Comment faire plusieurs noeuds dans un mm package ?

----
Dans l'énoncé:

TODO: doc sur l'odométrie.

TODO:
- Odometrie: comprendre le noeud odom
- un noeud ros pour se rendre à un point donné, avec l'odométrie
- se rendre à un point donné avec l'odométrie en évitant les obstacles au bumper
- se rendre à un point donné avec l'odométrie en évitant les obstacle au lidar. 


- navigation / slam
- mise en forme de la carte
- mission prise de photo, on clique sur la carte, et le robot va prendre une photo



