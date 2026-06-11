# Introduction à ROS — TurtleBot4

**Objectif de la session :** une première prise en main de ROS, du robot et des outils utilisés tout au long du cours. À la fin de cette session, vous aurez mis en marche un TurtleBot4, visualisé ses capteurs en direct dans RViz, et compris comment les différentes pièces s'articulent.

---

## 1. Qu'est-ce que ROS ?

**ROS** (Robot Operating System) n'est pas un système d'exploitation au sens traditionnel. C'est un framework middleware qui s'exécute par-dessus Linux. Son rôle est de permettre aux différents composants logiciels d'un robot de communiquer entre eux, quel que soit le langage de programmation utilisé ou l'ordinateur sur lequel ils tournent.

### Les trois concepts fondamentaux

| Concept | Ce que c'est | Analogie |
|---------|-------------|----------|
| **Nœud** | Un processus qui fait une seule chose (lit un capteur, contrôle un moteur, construit une carte…) | Un microservice |
| **Topic** | Un canal nommé sur lequel les nœuds publient ou s'abonnent à un flux de messages | Une fréquence radio |
| **Message** | Une structure de données typée envoyée sur un topic | Un paquet réseau |

Un robot sous ROS est un graphe de nœuds qui échangent des messages via des topics. Vous n'avez jamais à vous soucier des sockets, de la sérialisation ou de la synchronisation : ROS s'en charge.

```
[ nœud caméra ] ──/image──▶ [ nœud traitement ] ──/cmd_vel──▶ [ nœud moteurs ]
```

### Pourquoi c'est important

- **Réutilisation :** des milliers de nœuds prêts à l'emploi existent pour les capteurs, la navigation, la perception, etc. On repart rarement de zéro.
- **Introspection :** on peut inspecter chaque message circulant dans le système depuis le terminal, à tout moment, sans modifier le code.
- **Indépendance matérielle :** le même stack de navigation fonctionne sur un TurtleBot, un drone ou un bras robotique.

---

## 2. Le TurtleBot4

Le TurtleBot4 est un robot de recherche et d'enseignement composé de trois éléments principaux :

| Composant | Rôle |
|-----------|------|
| **iRobot Create3** | La base à roues (moteurs, roues, pare-chocs, capteurs IR, batterie) |
| **Raspberry Pi 4** | L'ordinateur embarqué (exécute ROS2, gère la caméra et le réseau) |
| **Caméra OAK-D Lite** | Une caméra stéréo RGB-D montée sur le dessus |

Le Create3 embarque également un **LIDAR 360°** (scanner laser) qui mesure les distances aux objets environnants. C'est le capteur principal pour la cartographie et l'évitement d'obstacles.

### Comment il se connecte à votre PC

Votre PC et le TurtleBot4 sont sur le même réseau WiFi. ROS2 utilise le multicast pour découvrir les nœuds automatiquement : dès que les deux machines sont sur le réseau et partagent le même **ROS_DOMAIN_ID**, votre PC voit les topics du robot comme s'ils étaient locaux.

```
[ Votre PC ] ── WiFi (RHOBAN_100) ── [ Raspberry Pi ] ── USB ── [ Create3 ]
```

Vous n'avez pas besoin de vous connecter au robot pour exécuter vos nœuds. Vous les écrivez et les lancez sur votre PC ; ils communiquent avec les nœuds du robot via le réseau de manière transparente.

---

## 3. Allumer le TurtleBot4

1. Placez le robot **hors** de sa station de recharge.
2. Appuyez brièvement sur le **bouton central** (grand bouton circulaire sur le dessus). L'anneau de LEDs s'animera et le robot jouera une courte mélodie.
3. Attendez environ 30 secondes que le Raspberry Pi démarre et que ROS2 soit prêt.
4. Vous pouvez confirmer que le robot est prêt quand des topics apparaissent dans votre terminal (voir Section 4).

> Lorsque vous avez fini, éteignez toujours le **LIDAR** avant de laisser le robot sans surveillance. Il consomme beaucoup d'énergie et déchargera la batterie même en charge.

Pour éteindre le robot : maintenez le bouton central appuyé 10 secondes jusqu'à ce qu'il joue une mélodie et que les LEDs s'éteignent.

---

## 4. Vos premières commandes ROS2

Ouvrez un terminal sur votre PC, sourcez ROS2, puis essayez les commandes suivantes.

```bash
source /opt/ros/humble/setup.bash
```

**Lister tous les topics actifs :**

```bash
ros2 topic list
```

Vous devriez voir plusieurs dizaines de topics préfixés par `/tbot<N>/` (un préfixe par robot sur le réseau). Chaque topic est un flux de données en direct depuis le robot.

**Afficher les données d'un topic :**

```bash
ros2 topic echo /tbot<N>/battery_state
```

Cela affiche l'état de la batterie en temps réel. Appuyez sur `Ctrl+C` pour arrêter.

**Obtenir des informations sur un topic :**

```bash
ros2 topic info /tbot<N>/battery_state
```

**Inspecter un type de message :**

```bash
ros2 interface show sensor_msgs/msg/BatteryState
```

Ces quatre commandes (`list`, `echo`, `info`, `interface show`) constituent le cœur de votre boîte à outils de débogage ROS2. Vous les utiliserez constamment.

---

## 5. Découvrir RViz

RViz est l'outil de visualisation intégré à ROS2. Il vous permet de voir les données des capteurs, les modèles de robots, les cartes et les transformations dans une vue 3D, sans écrire de code.

Lancez-le avec le modèle TurtleBot4 :

```bash
ros2 launch turtlebot4_viz view_robot.launch.py namespace:=tbot<N>
```

### Configurer la vue

1. Dans le panneau **Displays** à gauche, réglez **Fixed Frame** sur `base_link`.
2. Cliquez sur **Add → By Topic**, trouvez `/tbot<N>/scan`, et sélectionnez **LaserScan**. Vous devriez voir un anneau de points rouges autour du robot (lecture du LIDAR).
3. Cliquez sur **Add → By Topic**, trouvez `/tbot<N>/oakd/rgb/preview/image_raw`, et sélectionnez **Image**. Une petite fenêtre de flux caméra apparaîtra (uniquement quand le robot n'est pas sur sa base).

### Ce que vous observez

| Affichage | Ce qu'il montre |
|-----------|----------------|
| Modèle robot | Le modèle 3D URDF du TurtleBot4 |
| LaserScan (`/scan`) | Mesures de distance du LIDAR 360° |
| Image (`/oakd/…`) | Flux RGB en direct de la caméra OAK-D |

Essayez de déplacer un objet devant le robot et observez la réaction du scan LIDAR en temps réel.

---

## 6. L'évaluation

Sur les trois jours, vous remplirez progressivement un **diaporama** qui documente votre travail. Considérez-le comme un carnet de laboratoire sous forme de présentation.

- Ajoutez **une diapositive par session** au fur et à mesure. Ne laissez pas cela pour le dernier jour.
- Incluez **des captures d'écran et de courtes vidéos** de vos sorties terminal, de RViz et du robot en mouvement. Ce sont vos principales preuves.
- La présentation finale (Session 6) dure 15 minutes par groupe. Vous exposerez ce que vous avez fait, ce que vous avez observé et ce que vous avez compris.

Une liste de contrôle détaillant ce qu'il faut capturer à chaque session se trouve dans [evaluation.md](../Session-6/evaluation.md).

---

## Dépannage

| Symptôme | Cause probable |
|----------|---------------|
| `ros2 topic list` ne renvoie rien | ROS2 non sourcé, ou robot pas encore démarré. Attendez 30 s et réessayez |
| Les topics apparaissent avec un préfixe différent | C'est le robot d'un autre groupe ; vérifiez votre numéro de robot et cherchez `/tbot<N>/` |
| RViz se lance mais le modèle est invisible | Mauvais Fixed Frame ; réglez-le sur `base_link` |
| Pas d'image caméra dans RViz | Le robot est sur sa base. La caméra est inactive en mode chargement (voir [docked_mode.md](../General/docked_mode.md)) |
