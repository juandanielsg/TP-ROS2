# Premier nœud Python — TurtleBot4

*Juan Daniel S. G. — [juandanielsg.eu](https://juandanielsg.eu)*

**Ce que vous allez construire :** un nœud ROS2 qui écoute les boutons physiques du TurtleBot et contrôle l'anneau de LEDs en réponse. Il illustre les deux patrons fondamentaux de ROS2 : **s'abonner** à un topic et **publier** sur un topic.

---

## Prérequis

- ROS2 Humble installé et sourcé
- Un TurtleBot4 accessible sur le réseau (ou en simulation)
- Notions de base en Python

---

## 1. Créer le workspace

Si vous n'avez pas encore de workspace :

```bash
mkdir -p ~/turtlebot4_ws/src
```

> Cette commande crée la structure de répertoires. Le workspace n'est pas utilisable tant qu'il n'a pas été compilé au moins une fois ; nous le ferons à la [Section 5](#5-compiler).

---

## 2. Créer le package

```bash
source /opt/ros/humble/setup.bash
cd ~/turtlebot4_ws/src
ros2 pkg create --build-type ament_python \
    --node-name turtlebot4_first_python_node \
    turtlebot4_python_tutorials
```

La commande génère la structure suivante :

```
turtlebot4_python_tutorials/
├── package.xml
├── setup.cfg
├── setup.py
└── turtlebot4_python_tutorials/
    └── turtlebot4_first_python_node.py   ← votre nœud
```

---

## 3. Déclarer les dépendances

Ouvrez `package.xml` et ajoutez les deux dépendances nécessaires :

```xml
<depend>rclpy</depend>
<depend>irobot_create_msgs</depend>
```

- `rclpy` est la bibliothèque cliente Python de ROS2.
- `irobot_create_msgs` fournit les types de messages pour la base Create3 (boutons, anneau de LEDs, etc.).

---

## 4. Écrire le nœud

Remplacez le contenu de `turtlebot4_first_python_node.py` par le code suivant.

> **Note sur le namespace :** les noms de topics ci-dessous sont *relatifs* (sans `/` initial). Ils s'adaptent automatiquement au namespace passé au lancement, ce qui est utile dans un laboratoire avec plusieurs robots. Voir la [Section 6](#6-lancer-le-nœud) pour définir le namespace.

```python
from irobot_create_msgs.msg import InterfaceButtons, LightringLeds

import rclpy
from rclpy.node import Node
from rclpy.qos import qos_profile_sensor_data


class TurtleBot4FirstNode(Node):
    lights_on_ = False

    def __init__(self):
        super().__init__('turtlebot4_first_python_node')

        # Subscribe to button events from the Create3 base
        self.interface_buttons_subscriber = self.create_subscription(
            InterfaceButtons,
            'interface_buttons',          # relative topic (namespace is applied at launch)
            self.interface_buttons_callback,
            qos_profile_sensor_data)

        # Publisher to control the LED ring
        self.lightring_publisher = self.create_publisher(
            LightringLeds,
            'cmd_lightring',              # relative topic
            qos_profile_sensor_data)

    def interface_buttons_callback(self, create3_buttons_msg: InterfaceButtons):
        if create3_buttons_msg.button_1.is_pressed:
            self.get_logger().info('Button 1 Pressed!')
            self.button_1_function()

    def button_1_function(self):
        lightring_msg = LightringLeds()
        lightring_msg.header.stamp = self.get_clock().now().to_msg()

        if not self.lights_on_:
            lightring_msg.override_system = True   # take control from the system

            # Set colors for each of the 6 LEDs (RGB values 0–255)
            lightring_msg.leds[0].red = 255; lightring_msg.leds[0].blue = 0;   lightring_msg.leds[0].green = 0
            lightring_msg.leds[1].red = 0;   lightring_msg.leds[1].blue = 255; lightring_msg.leds[1].green = 0
            lightring_msg.leds[2].red = 0;   lightring_msg.leds[2].blue = 0;   lightring_msg.leds[2].green = 255
            lightring_msg.leds[3].red = 255; lightring_msg.leds[3].blue = 255; lightring_msg.leds[3].green = 0
            lightring_msg.leds[4].red = 255; lightring_msg.leds[4].blue = 0;   lightring_msg.leds[4].green = 255
            lightring_msg.leds[5].red = 0;   lightring_msg.leds[5].blue = 255; lightring_msg.leds[5].green = 255
        else:
            lightring_msg.override_system = False  # give control back to the system

        self.lightring_publisher.publish(lightring_msg)
        self.lights_on_ = not self.lights_on_


def main(args=None):
    rclpy.init(args=args)
    node = TurtleBot4FirstNode()
    rclpy.spin(node)          # blocks until Ctrl+C
    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
```

### Concepts clés

| Concept | Rôle dans cet exemple |
|---------|----------------------|
| `create_subscription(MsgType, topic, callback, qos)` | Enregistre une fonction appelée à chaque message reçu sur `topic` |
| `create_publisher(MsgType, topic, qos)` | Crée un canal sortant sur `topic` |
| `qos_profile_sensor_data` | Profil QoS adapté aux flux de capteurs (best-effort, derniers 10 messages) |
| `rclpy.spin(node)` | Maintient le nœud actif et traite les messages entrants en boucle |
| `override_system = True/False` | Indique au Create3 si votre nœud ou le firmware du robot contrôle l'anneau de LEDs |

---

## 5. Compiler

```bash
cd ~/turtlebot4_ws
colcon build --symlink-install --packages-select turtlebot4_python_tutorials
source install/local_setup.bash
```

`--symlink-install` évite de recompiler après chaque modification d'un fichier Python.

---

## 6. Lancer le nœud

### Sans namespace (robot unique ou simulation)

```bash
ros2 run turtlebot4_python_tutorials turtlebot4_first_python_node
```

Le nœud s'abonnera à `interface_buttons` et publiera sur `cmd_lightring`.

### Avec un namespace (plusieurs robots dans le laboratoire)

Passez le namespace du robot pour que les topics soient correctement routés vers *votre* robot :

```bash
ros2 run turtlebot4_python_tutorials turtlebot4_first_python_node \
    --ros-args -r __ns:=/turtlebot1
```

Le nœud s'abonnera alors à `/turtlebot1/interface_buttons` et publiera sur `/turtlebot1/cmd_lightring`, sans aucune modification du code source.

Remplacez `turtlebot1` par le namespace du robot avec lequel vous travaillez.

---

## 7. Tester

1. Appuyez sur le **Bouton 1** (celui marqué `1` sur le dessus du robot).
2. L'anneau de LEDs doit s'allumer avec 6 couleurs différentes.
3. Appuyez à nouveau ; les LEDs doivent s'éteindre et rendre le contrôle au système.

Vous devriez également voir ceci dans le terminal :

```
[INFO] [turtlebot4_first_python_node]: Button 1 Pressed!
```

---

## Dépannage

| Symptôme | Cause probable |
|----------|----------------|
| Aucun message reçu | Namespace incorrect ; vérifiez avec `ros2 topic list` |
| `irobot_create_msgs` introuvable | Exécutez `sudo apt install ros-humble-irobot-create-msgs` |
| Les LEDs ne changent pas | Le TurtleBot est peut-être sur sa base (le mode d'économie d'énergie bloque la prise en charge des LEDs) |
| Avertissement de mismatch `qos_profile_sensor_data` | Les profils QoS du publisher et du subscriber doivent correspondre ; utilisez `qos_profile_sensor_data` des deux côtés |
