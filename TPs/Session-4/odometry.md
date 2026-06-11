# Odométrie — TurtleBot4

*Juan Daniel S. G. — [juandanielsg.eu](https://juandanielsg.eu)*

**Ce que vous allez apprendre :** ce qu'est l'odométrie, comment fonctionne le topic `/odom`, comment lire la position et l'orientation du robot à partir de celui-ci, et comment l'utiliser dans un nœud.

---

## Prérequis

- Sessions 2 et 3 terminées
- À l'aise avec l'écriture d'un nœud abonné de base (voir Session 2)
- Votre numéro de robot (remplacez `<N>` tout au long)

---

## 1. Qu'est-ce que l'odométrie ?

L'odométrie est une estimation de la position et de l'orientation du robot dans l'espace, calculée en intégrant les mouvements des roues au fil du temps. À chaque tour de roue, le robot déduit la distance parcourue et la direction prise.

Points essentiels à retenir :

- Le repère de référence est `odom`, un repère fixe dont l'origine est là où se trouvait le robot au démarrage.
- L'odométrie **accumule des erreurs** au fil du temps. Les petites imprécisions de mesure dues au glissement des roues s'additionnent : l'estimation dérive de la position réelle.
- Elle ne fournit aucune information sur l'environnement ; elle renseigne uniquement sur le mouvement propre du robot.

---

## 2. Inspecter le topic

```bash
# Confirm the topic exists
ros2 topic list | grep odom

# Print incoming messages
ros2 topic echo /tbot<N>/odom

# Check the message type
ros2 topic info /tbot<N>/odom

# Read the full message definition
ros2 interface show nav_msgs/msg/Odometry
```

Le type de message est `nav_msgs/msg/Odometry`.

---

## 3. Structure du message d'odométrie

```
nav_msgs/msg/Odometry
├── header
│   ├── stamp        : timestamp of the measurement
│   └── frame_id     : reference frame ("odom")
├── child_frame_id   : the robot frame ("base_link")
├── pose
│   └── pose
│       ├── position
│       │   ├── x    : meters (forward/backward)
│       │   ├── y    : meters (left/right)
│       │   └── z    : meters (up/down, usually ~0)
│       └── orientation
│           ├── x  ─╮
│           ├── y   │ quaternion
│           ├── z   │ (see Section 4)
│           └── w  ─╯
└── twist
    └── twist
        ├── linear
        │   └── x    : current forward velocity (m/s)
        └── angular
            └── z    : current rotation rate (rad/s)
```

En pratique, vous utiliserez principalement `pose.pose.position.x/y` pour la position et `pose.pose.orientation` pour l'orientation.

---

## 4. Orientation et quaternions

ROS2 exprime l'orientation sous forme de **quaternion** `(x, y, z, w)` plutôt que sous forme d'un angle unique. Cela évite les ambiguïtés liées aux angles d'Euler (blocage de cardan) et fonctionne uniformément en 3D.

Pour un robot terrestre se déplaçant dans un plan, seule la rotation autour de l'axe vertical (lacet, ou *yaw*) est pertinente. Le quaternion se simplifie alors :

```
x = 0
y = 0
z = sin(yaw / 2)
w = cos(yaw / 2)
```

Pour convertir vers un angle de lacet en Python :

```python
import math

def quaternion_to_yaw(orientation):
    # orientation is a geometry_msgs/msg/Quaternion
    siny_cosp = 2.0 * (orientation.w * orientation.z + orientation.x * orientation.y)
    cosy_cosp = 1.0 - 2.0 * (orientation.y ** 2 + orientation.z ** 2)
    return math.atan2(siny_cosp, cosy_cosp)   # result in radians
```

> Pour expérimenter interactivement avec les conversions d'orientation : https://www.andre-gaschler.com/rotationconverter/

---

## 5. Lire l'odométrie dans un nœud

Le patron est identique à celui du nœud abonné aux boutons de la Session 2 : s'abonner à `/odom` et traiter chaque message dans un callback.

```python
from nav_msgs.msg import Odometry
import math
import rclpy
from rclpy.node import Node
from rclpy.qos import qos_profile_sensor_data


def quaternion_to_yaw(orientation):
    siny_cosp = 2.0 * (orientation.w * orientation.z + orientation.x * orientation.y)
    cosy_cosp = 1.0 - 2.0 * (orientation.y ** 2 + orientation.z ** 2)
    return math.atan2(siny_cosp, cosy_cosp)


class OdomReader(Node):

    def __init__(self):
        super().__init__('odom_reader')

        self.create_subscription(
            Odometry,
            'odom',                         # relative (namespace applied at launch)
            self.odom_callback,
            qos_profile_sensor_data)

    def odom_callback(self, msg: Odometry):
        x   = msg.pose.pose.position.x
        y   = msg.pose.pose.position.y
        yaw = quaternion_to_yaw(msg.pose.pose.orientation)

        self.get_logger().info(
            f'Position: x={x:.3f} m  y={y:.3f} m  yaw={math.degrees(yaw):.1f}°'
        )


def main(args=None):
    rclpy.init(args=args)
    node = OdomReader()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
```

Lancez-le avec :

```bash
ros2 run <your_package> odom_reader --ros-args -r __ns:=/tbot<N>
```

Déplacez le robot (clavier ou manette) et observez comment `x`, `y` et `yaw` évoluent.

### Concepts clés

| Concept | Rôle dans cet exemple |
|---------|----------------------|
| `nav_msgs/msg/Odometry` | Message ROS2 standard portant la pose et la vitesse |
| `pose.pose.position` | Position du robot dans le repère `odom` (en mètres) |
| `pose.pose.orientation` | Orientation du robot sous forme de quaternion |
| `twist.twist.linear.x` | Vitesse d'avance actuelle (m/s) |
| `twist.twist.angular.z` | Vitesse de rotation actuelle (rad/s) |

---

## 6. Exercices

Ces exercices se construisent les uns sur les autres ; réalisez-les dans l'ordre.

**Exercice 1 — Mouvement de base**

Écrivez un nœud qui fait avancer le robot pendant 5 secondes, puis le fait tourner sur lui-même dans le sens trigonométrique pendant 5 secondes. Publiez sur `cmd_vel` (voir le type de message de la téléopération en Session 3).

**Exercice 2 — Mouvement guidé par le LIDAR**

Étendez le nœud précédent pour lire le LIDAR (topic `scan`). Le robot doit :
1. Tourner sur lui-même.
2. S'arrêter lorsqu'il fait face à un passage libre d'au moins 1 mètre.
3. Avancer d'1 mètre.

**Exercice 3 — Observer l'odométrie**

Ajoutez la journalisation de l'odométrie au nœud de l'Exercice 2 (abonnez-vous à `odom` en parallèle de `scan`). Exécutez le nœud et expliquez ce que représente chaque champ du message. Le robot se retrouve-t-il là où vous l'attendiez après la séquence ?

**Exercice 4 — Aller à un point cible**

En utilisant l'odométrie comme retour d'information, écrivez un nœud qui conduit le robot vers une position `(x, y)` fournie par l'utilisateur. La séquence doit être :
1. Pivoter pour faire face à la cible.
2. Avancer en ligne droite vers la cible.
3. Pivoter pour atteindre l'orientation cible (si fournie).

**Exercice 5 — Évitement d'obstacles**

Modifiez le nœud de l'Exercice 4 pour détecter et contourner les obstacles sur le chemin vers la cible.

> **Algorithmes à explorer.** Il existe plusieurs approches classiques pour l'évitement d'obstacles réactif ; en voici quelques-unes à investiguer avant de choisir celle que vous souhaitez implémenter :
>
> - **Champ de potentiel** — la cible exerce une force attractive sur le robot, chaque obstacle une force répulsive. Le robot suit la résultante de ces forces. Simple à coder, mais peut bloquer dans des minima locaux (cul-de-sac).
> - **Heuristique réactive (turn-and-go)** — si un obstacle est détecté devant, le robot tourne d'un angle fixe (ou jusqu'à trouver un passage libre dans le scan LIDAR), puis reprend sa route vers la cible. Robuste et facile à régler.
> - **Suivi de mur (wall-following)** — lorsqu'un obstacle est rencontré, le robot longe son bord jusqu'à pouvoir reprendre cap vers la cible. Complète davantage d'environnements que turn-and-go, mais la logique de sortie du suivi est plus délicate.
>
> Choisissez l'approche qui vous semble la plus intéressante ou la plus adaptée à l'environnement du laboratoire, et implémentez-la.

---

## Dépannage

| Symptôme | Cause probable |
|----------|----------------|
| Aucun message sur `/tbot<N>/odom` | Robot non démarré ou namespace incorrect ; vérifiez avec `ros2 topic list` |
| La position ne se réinitialise jamais à zéro | L'origine de l'odométrie est fixée au démarrage ; désarrimez et redémarrez le robot si nécessaire |
| Le lacet oscille entre +π et −π | Ce comportement est attendu : `atan2` effectue un enroulage à ±180° ; gérez-le dans votre code lors du calcul des différences d'angle |
