# Navigation & SLAM — TurtleBot4

*Juan Daniel S. G. — [juandanielsg.eu](https://juandanielsg.eu)*

**Ce que vous allez faire :** construire une carte de l'environnement avec le SLAM, puis utiliser cette carte pour naviguer le robot de façon autonome vers n'importe quel point, et enfin combiner navigation et caméra pour réaliser une mission photo.

---

## Prérequis

- Sessions 2 à 4 terminées
- Nœud `camera_snapshot` de `take_picture.md` disponible dans votre package
- Votre numéro de robot (remplacez `<N>` tout au long)

---

## 1. Qu'est-ce que le SLAM ?

Le **SLAM** (*Simultaneous Localisation and Mapping*, localisation et cartographie simultanées) permet au robot de construire une carte de son environnement tout en se localisant dans cette carte. Il utilise le LIDAR pour détecter murs et obstacles, et l'odométrie de la Session 4 pour estimer ses déplacements.

Le résultat est une grille d'occupation 2D, une image en niveaux de gris où :
- **Blanc** = espace libre
- **Noir** = obstacle
- **Gris** = inconnu (pas encore exploré)

---

## 2. Construire une carte

### Lancer le SLAM

Dans un premier terminal, démarrez le nœud SLAM :

```bash
ros2 launch turtlebot4_navigation slam.launch.py namespace:=tbot<N>
```

Dans un second terminal, ouvrez RViz pour observer la carte se construire en temps réel :

```bash
ros2 launch turtlebot4_viz view_robot.launch.py namespace:=tbot<N>
```

Dans RViz, ajoutez un affichage **Map** (Add → By Topic → `/tbot<N>/map`). La carte apparaît quelques secondes après le lancement, une fois suffisamment de données LIDAR collectées.

### Explorer en conduisant

Utilisez le clavier ou la manette (Session 3) pour conduire le robot dans la zone à cartographier. Déplacez-vous lentement en couvrant chaque pièce ou couloir ; les zones jamais visitées resteront grises.

```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args -r __ns:=/tbot<N>
```

> La carte se met à jour en direct pendant que vous conduisez. Surveillez RViz pour voir quelles zones restent à explorer.

### Sauvegarder la carte

Une fois la carte satisfaisante, sauvegardez-la avec :

```bash
ros2 run nav2_map_server map_saver_cli -f ~/map
```

Cela produit deux fichiers dans votre répertoire personnel :
- `map.pgm` : l'image de la carte
- `map.yaml` : métadonnées (résolution, origine, seuils)

> Ne stoppez pas le lancement SLAM avant la sauvegarde ; la carte est en mémoire et sera perdue.

---

## 3. Naviguer avec la carte

### Lancer la pile de navigation

Arrêtez le lancement SLAM, puis démarrez la pile de navigation Nav2 avec la carte sauvegardée :

```bash
ros2 launch turtlebot4_navigation nav2.launch.py \
    namespace:=tbot<N> \
    map:=$HOME/map.yaml
```

### Envoyer un objectif de navigation depuis RViz

Dans RViz, utilisez l'outil **Nav2 Goal** (icône flèche dans la barre d'outils) pour cliquer sur une destination sur la carte. Cliquez une fois pour définir la position, faites glisser pour définir l'orientation. Le robot planifiera un chemin et s'y rendra de façon autonome.

### Envoyer un objectif de navigation par programmation

La pile de navigation expose une action `NavigateToPose`. La façon la plus simple de l'utiliser en Python est via la bibliothèque `nav2_simple_commander` :

```python
from geometry_msgs.msg import PoseStamped
from nav2_simple_commander.robot_navigator import BasicNavigator
import rclpy


def main():
    rclpy.init()
    navigator = BasicNavigator(namespace='tbot<N>')

    # Wait for Nav2 to be ready before sending any goal
    navigator.waitUntilNav2Active()

    # Build the target pose in the map frame
    goal = PoseStamped()
    goal.header.frame_id = 'map'
    goal.header.stamp = navigator.get_clock().now().to_msg()
    goal.pose.position.x = 1.0    # metres from the map origin
    goal.pose.position.y = 0.5
    goal.pose.orientation.w = 1.0  # facing forward (no rotation)

    navigator.goToPose(goal)

    # Block until the robot reaches the goal or fails
    while not navigator.isTaskComplete():
        pass

    print('Goal reached.')
    rclpy.shutdown()


if __name__ == '__main__':
    main()
```

Ajoutez `nav2_simple_commander` à votre `package.xml` :

```xml
<depend>nav2_simple_commander</depend>
```

---

## 4. Mission — Naviguer et prendre une photo

En combinant la navigation avec le nœud `camera_snapshot` de `take_picture.md`, vous pouvez envoyer le robot à n'importe quel point de la carte et déclencher une photo à l'arrivée.

Lancez le nœud de capture dans un terminal :

```bash
ros2 run turtlebot4_python_tutorials camera_snapshot --ros-args -r __ns:=/tbot<N>
```

Puis étendez le nœud de navigation pour publier sur `take_picture` une fois l'objectif atteint :

```python
from geometry_msgs.msg import PoseStamped
from nav2_simple_commander.robot_navigator import BasicNavigator
from std_msgs.msg import Empty
import rclpy
from rclpy.qos import QoSProfile


def main():
    rclpy.init()
    navigator = BasicNavigator(namespace='tbot<N>')

    # Publisher on the snapshot trigger topic (same namespace as the robot)
    trigger_pub = navigator.create_publisher(
        Empty, '/tbot<N>/take_picture', QoSProfile(depth=1))

    navigator.waitUntilNav2Active()

    goal = PoseStamped()
    goal.header.frame_id = 'map'
    goal.header.stamp = navigator.get_clock().now().to_msg()
    goal.pose.position.x = 1.0
    goal.pose.position.y = 0.5
    goal.pose.orientation.w = 1.0

    navigator.goToPose(goal)

    while not navigator.isTaskComplete():
        pass

    # Trigger the snapshot once the robot has stopped at the goal
    trigger_pub.publish(Empty())
    navigator.get_logger().info('Goal reached; photo triggered.')

    rclpy.shutdown()


if __name__ == '__main__':
    main()
```

> Le nœud de capture et le nœud de navigation sont indépendants et ne communiquent qu'à travers le topic `take_picture`. Vous pouvez remplacer l'un ou l'autre sans modifier le second.

---

## 5. Exercices

**Exercice 1 — Construire une carte**

Lancez le SLAM et conduisez le robot jusqu'à ce que la carte couvre toute la zone. Sauvegardez la carte et inspectez les fichiers `.pgm` et `.yaml`. Que signifie le champ `resolution` dans le fichier YAML ?

**Exercice 2 — Naviguer vers un point**

Lancez la navigation avec votre carte sauvegardée. Utilisez l'outil de goal RViz pour envoyer le robot vers trois positions différentes. Observez le chemin planifié : prend-il toujours le chemin le plus court ?

**Exercice 3 — Naviguer par programmation**

Écrivez un nœud utilisant `BasicNavigator` qui fait parcourir au robot une séquence de waypoints. Le robot doit visiter chaque point dans l'ordre et journaliser son arrivée à chacun.

**Exercice 4 — Mission photo**

Étendez l'Exercice 3 pour que le robot prenne une photo à chaque waypoint avant de passer au suivant.

---

## Dépannage

| Symptôme | Cause probable |
|----------|----------------|
| La carte reste grise après le lancement du SLAM | Le SLAM s'initialise ; attendez quelques secondes puis commencez à conduire |
| La carte se déforme pendant la conduite | Le robot va trop vite ; ralentissez pour laisser le temps au LIDAR de se mettre à jour |
| `map_saver_cli` sauvegarde une carte vide | La carte n'est pas encore peuplée ; explorez davantage avant de sauvegarder |
| Nav2 refuse de planifier un chemin | L'objectif est dans un obstacle ou une zone inconnue ; choisissez une zone clairement blanche sur la carte |
| `waitUntilNav2Active()` bloque indéfiniment | Nav2 n'est pas entièrement démarré ; attendez plus longtemps ou vérifiez les erreurs avec `ros2 node list` |
| La photo n'est pas sauvegardée après la mission | Le nœud `camera_snapshot` n'est pas lancé, ou le namespace de `take_picture` ne correspond pas |
