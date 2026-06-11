# Annexe — Exercices supplémentaires

*Juan Daniel S. G. — [juandanielsg.eu](https://juandanielsg.eu)*

Ce contenu a été développé comme expansion de la documentation originale du cours. Il est fourni ici à titre d'approfondissement et va au-delà du périmètre requis. **Il ne sera pas évalué.** Utilisez-le si vous souhaitez aller plus loin après avoir terminé les exercices principaux.

---

## 1. Messages personnalisés — Contrôleur de pose

Cet exercice introduit les types de messages ROS2 personnalisés et les applique à un contrôleur en boucle fermée minimal. Vous définirez un message, construirez un publisher qui lit l'odométrie et envoie des commandes de pose, et un subscriber qui calcule et publie la vitesse requise.

```
[ publisher de pose ] ──/pose_target──▶ [ nœud contrôleur ] ──/cmd_vel──▶ [ robot ]
```

### Étape 1 — Définir le message

Créez un nouveau package nommé `turtlebot4_msgs` avec la structure suivante :

```
turtlebot4_msgs/
├── msg/
│   └── PoseTarget.msg
├── CMakeLists.txt
└── package.xml
```

Le message transporte deux poses 2D :

```
geometry_msgs/Pose2D current
geometry_msgs/Pose2D desired
```

`Pose2D` comporte trois champs : `x` (mètres), `y` (mètres) et `theta` (radians).

Dans `package.xml`, déclarez :

```xml
<buildtool_depend>rosidl_default_generators</buildtool_depend>
<exec_depend>rosidl_default_runtime</exec_depend>
<depend>geometry_msgs</depend>
<member_of_group>rosidl_interface_packages</member_of_group>
```

Dans `CMakeLists.txt`, enregistrez le message auprès du système de build :

```cmake
find_package(rosidl_default_generators REQUIRED)
find_package(geometry_msgs REQUIRED)

rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/PoseTarget.msg"
  DEPENDENCIES geometry_msgs
)
```

Compilez le package et sourcez le workspace avant de continuer.

### Étape 2 — Écrire le publisher

Ajoutez un nœud à votre package `turtlebot4_python_tutorials` existant qui publie des messages `PoseTarget` sur `/pose_target`. Codez en dur une pose désirée fixe (par exemple `x=1.0`, `y=0.0`, `theta=0.0`) et lisez la pose courante depuis `/tbot<N>/odom`.

Le type du message `odom` est `nav_msgs/msg/Odometry`. Les champs pertinents sont :

```
pose.pose.position.x
pose.pose.position.y
pose.pose.orientation   ← quaternion ; à convertir en theta avec une fonction utilitaire
```

Pour convertir un quaternion en angle de lacet, utilisez `tf_transformations` :

```python
from tf_transformations import euler_from_quaternion
```

`euler_from_quaternion` prend une liste `[x, y, z, w]` et retourne `(roll, pitch, yaw)`. Le yaw est l'angle de cap en radians.

### Étape 3 — Écrire le subscriber/contrôleur

Ajoutez un second nœud qui s'abonne à `/pose_target` et publie un `geometry_msgs/msg/Twist` sur `cmd_vel`.

À chaque message reçu, calculez la commande de vitesse à l'aide d'un contrôleur proportionnel simple :

| Quantité | Formule |
|----------|---------|
| Distance au goal | `sqrt((desired.x - current.x)^2 + (desired.y - current.y)^2)` |
| Cap désiré | `atan2(desired.y - current.y, desired.x - current.x)` |
| Erreur de cap | `cap_désiré - current.theta` |
| `linear.x` | `k_linear * distance` |
| `angular.z` | `k_angular * erreur_de_cap` |

Commencez avec `k_linear = 0.3` et `k_angular = 1.0`. Mettez `linear.x` à zéro quand l'erreur de cap est grande (plus de ~0.3 rad) pour que le robot tourne sur place avant d'avancer. Arrêtez de publier (envoyez un `Twist` nul) quand la distance au goal est inférieure à un seuil de votre choix.

### Étape 4 — Tester

```bash
ros2 run turtlebot4_python_tutorials pose_publisher \
    --ros-args -r __ns:=/tbot<N>

ros2 run turtlebot4_python_tutorials pose_controller \
    --ros-args -r __ns:=/tbot<N>
```

Vérifiez le topic intermédiaire :

```bash
ros2 topic echo /tbot<N>/pose_target
ros2 topic echo /tbot<N>/cmd_vel
```

---

## 2. Navigation par programmation

Cette section va au-delà de l'outil de goal RViz et montre comment envoyer des objectifs de navigation depuis du code Python via la bibliothèque `nav2_simple_commander`. Elle nécessite une carte sauvegardée et une pile Nav2 active (voir Bloc 5).

### Envoyer un objectif avec BasicNavigator

```python
from geometry_msgs.msg import PoseStamped
from nav2_simple_commander.robot_navigator import BasicNavigator
import rclpy


def main():
    rclpy.init()
    navigator = BasicNavigator(namespace='tbot<N>')

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

    print('Goal reached.')
    rclpy.shutdown()


if __name__ == '__main__':
    main()
```

Ajoutez à `package.xml` :

```xml
<depend>nav2_simple_commander</depend>
```

**Exercice — Séquence de waypoints**

Écrivez un nœud utilisant `BasicNavigator` qui fait parcourir au robot une séquence de waypoints. Le robot doit visiter chaque point dans l'ordre et journaliser son arrivée à chacun.

### Naviguer et prendre une photo

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

    trigger_pub.publish(Empty())
    navigator.get_logger().info('Goal reached; photo triggered.')

    rclpy.shutdown()


if __name__ == '__main__':
    main()
```

> Le nœud de capture et le nœud de navigation sont indépendants et ne communiquent qu'à travers le topic `take_picture`. Vous pouvez remplacer l'un ou l'autre sans modifier le second.

**Exercice — Mission photo**

Étendez l'exercice de séquence de waypoints pour que le robot prenne une photo à chaque waypoint avant de passer au suivant.
