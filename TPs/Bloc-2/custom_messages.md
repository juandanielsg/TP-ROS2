# Messages personnalisés — TurtleBot4

*Juan Daniel S. G. — [juandanielsg.eu](https://juandanielsg.eu)*

**Ce que cette session couvre :** définir ses propres types de messages ROS2, les compiler et les utiliser dans une paire publisher/subscriber.

---

## 1. Pourquoi des messages personnalisés

ROS2 fournit des packages de messages standard qui couvrent la grande majorité des types de données courants :

| Package | Contenu typique |
|---------|----------------|
| `std_msgs` | Primitives : `Bool`, `Int32`, `Float64`, `String`, … |
| `geometry_msgs` | Poses, vitesses, transformations, points |
| `sensor_msgs` | Scans LIDAR, images, IMU, état de la batterie |
| `nav_msgs` | Odométrie, grilles d'occupation, chemins |

Quand aucun de ces types ne correspond exactement à vos données, vous définissez votre propre fichier `.msg`. Le système de build génère automatiquement le code Python et C++ correspondant.

---

## 2. Syntaxe de définition de message

Un fichier `.msg` est une liste de champs typés en texte brut, un par ligne :

```
string  label
float64 value
bool    is_valid
```

Types primitifs disponibles : `bool`, `byte`, `char`, `float32`, `float64`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `string`.

Vous pouvez également imbriquer des types de messages existants comme champs :

```
std_msgs/Header header
geometry_msgs/Point position
float32         confidence
```

Et déclarer des tableaux de taille fixe ou variable :

```
float32[3]  rgb           # tableau fixe de 3 éléments
string[]    labels        # tableau de taille variable
```

---

## 3. Structure du package

Les définitions de messages personnalisés doivent se trouver dans un **package dédié** qui ne contient que des fichiers d'interface — pas de code Python ou C++. Cela dissocie l'interface de toute implémentation et permet aux autres packages d'en dépendre proprement.

```
my_msgs/
├── msg/
│   └── MyMessage.msg     ← un fichier par type de message
├── CMakeLists.txt
└── package.xml
```

Les noms de fichiers de messages utilisent le **UpperCamelCase**. La classe Python générée porte le même nom.

---

## 4. Exercice — Contrôleur de pose

Vous allez construire un contrôleur en boucle fermée minimal, réparti en trois éléments :

1. Un **message personnalisé** qui transporte les poses courante et désirée ensemble.
2. Un **nœud publisher** qui envoie ce message.
3. Un **nœud subscriber** qui lit le message et publie la commande de vitesse nécessaire pour atteindre la pose désirée.

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

Ajoutez un nœud à votre package `turtlebot4_python_tutorials` existant qui publie des messages `PoseTarget` sur `/pose_target`. Pour cet exercice, codez en dur une pose désirée fixe (par exemple `x=1.0`, `y=0.0`, `theta=0.0`) et lisez la pose courante depuis `/tbot<N>/odom`.

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

Commencez avec `k_linear = 0.3` et `k_angular = 1.0`. Mettez `linear.x` à zéro quand l'erreur de cap est grande (plus de ~0.3 rad) pour que le robot tourne sur place avant d'avancer.

Arrêtez de publier des vitesses (envoyez un `Twist` nul) quand la distance au goal est inférieure à un seuil de votre choix.

### Étape 4 — Tester

Lancez les deux nœuds avec le namespace du robot :

```bash
ros2 run turtlebot4_python_tutorials pose_publisher \
    --ros-args -r __ns:=/tbot<N>

ros2 run turtlebot4_python_tutorials pose_controller \
    --ros-args -r __ns:=/tbot<N>
```

Vérifiez le topic intermédiaire avec :

```bash
ros2 topic echo /tbot<N>/pose_target
ros2 topic echo /tbot<N>/cmd_vel
```

Le robot devrait tourner pour faire face au goal, puis avancer vers lui.

---

## Dépannage

| Symptôme | Cause probable |
|----------|---------------|
| `ModuleNotFoundError` à l'import du message | Package non compilé, ou `install/local_setup.bash` non sourcé |
| `Unknown message type` dans `ros2 topic echo` | Idem — sourcez l'overlay du workspace |
| Le build échoue avec une erreur `rosidl` | `CMakeLists.txt` ou `package.xml` manque l'appel à `rosidl_generate_interfaces` |
| Collision de nom de champ | Les noms de champs doivent être en `snake_case` ; les noms en CamelCase sont rejetés par le parseur |
