# Prendre une photo — TurtleBot4

**Ce que vous allez construire :** un nœud ROS2 qui capture une photo depuis la caméra du TurtleBot4 et la sauvegarde sur le disque chaque fois qu'il reçoit un message sur un topic de déclenchement. Il combine le patron d'abonnement de la Session 2 avec la gestion d'images via `cv_bridge`.

---

## Prérequis

- Session 2 terminée (nœud abonné)
- Robot désamarré (la caméra est inactive lorsqu'il est amarré ; voir `docked_mode.md`)
- Votre numéro de robot (remplacez `<N>` tout au long)

---

## 1. Topics de la caméra

Le TurtleBot4 est équipé d'une caméra stéréo **OAK-D Lite**. Le topic RGB principal est :

```
/tbot<N>/oakd/rgb/preview/image_raw
```

Pour confirmer qu'il publie :

```bash
ros2 topic hz /tbot<N>/oakd/rgb/preview/image_raw
```

Si le topic est absent ou que le taux est nul, vérifiez que le robot est désamarré et que le nœud caméra est bien lancé.

---

## 2. Installer les dépendances

Le package `cv_bridge` convertit entre les messages ROS2 `Image` et les images OpenCV :

```bash
sudo apt install ros-humble-cv-bridge python3-opencv
```

Ajoutez les dépendances dans votre `package.xml` :

```xml
<depend>sensor_msgs</depend>
<depend>std_msgs</depend>
<depend>cv_bridge</depend>
```

---

## 3. Le nœud

Créez un nouveau fichier `camera_snapshot.py` dans le répertoire de votre package (voir `multiple_nodes.md` pour savoir comment l'enregistrer).

```python
import cv2
from cv_bridge import CvBridge
from sensor_msgs.msg import Image
from std_msgs.msg import Empty

import rclpy
from rclpy.node import Node
from rclpy.qos import qos_profile_sensor_data, QoSProfile


class CameraSnapshot(Node):

    def __init__(self):
        super().__init__('camera_snapshot')

        # cv_bridge converts between ROS2 Image messages and OpenCV arrays
        self.bridge = CvBridge()

        # Hold the latest camera frame so we can save it on demand
        self.latest_frame = None

        # Subscribe to the camera; we always keep the most recent frame
        self.create_subscription(
            Image,
            'oakd/rgb/preview/image_raw',   # relative topic, namespace applied at launch
            self.image_callback,
            qos_profile_sensor_data)

        # Subscribe to the trigger topic; any message on it fires a snapshot
        # std_msgs/Empty carries no data; it is used purely as a signal
        self.create_subscription(
            Empty,
            'take_picture',                 # relative topic, namespace applied at launch
            self.trigger_callback,
            QoSProfile(depth=1))

        self.get_logger().info('Ready: publish on ~/take_picture to take a photo.')

    def image_callback(self, msg: Image):
        # Convert the ROS2 Image message to an OpenCV BGR image and cache it
        self.latest_frame = self.bridge.imgmsg_to_cv2(msg, desired_encoding='bgr8')

    def trigger_callback(self, _msg: Empty):
        # The message content is ignored; receiving it is the trigger
        self.save_photo()

    def save_photo(self):
        if self.latest_frame is None:
            # No frame received yet; camera may still be starting up
            self.get_logger().warn('No image received yet, cannot save.')
            return

        # Build a timestamped filename so photos are never overwritten
        timestamp = self.get_clock().now().to_msg()
        filename = f'snapshot_{timestamp.sec}.jpg'

        cv2.imwrite(filename, self.latest_frame)
        self.get_logger().info(f'Photo saved: {filename}')


def main(args=None):
    rclpy.init(args=args)
    node = CameraSnapshot()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
```

### Concepts clés

| Concept | Rôle dans cet exemple |
|---------|----------------------|
| `std_msgs/msg/Empty` | Message sans champ, utilisé comme signal pur pour déclencher une action |
| `CvBridge.imgmsg_to_cv2(msg, encoding)` | Convertit un message ROS2 `Image` en tableau NumPy qu'OpenCV comprend |
| `desired_encoding='bgr8'` | Demande une image BGR 8 bits standard, le format par défaut d'OpenCV |
| `cv2.imwrite(filename, image)` | Sauvegarde le tableau image OpenCV sur le disque en JPEG (ou PNG si l'extension est `.png`) |
| Mise en cache de `latest_frame` | La caméra publie en continu ; on stocke l'image la plus récente pour qu'elle soit prête dès l'arrivée du déclencheur |

---

## 4. Compiler et lancer

Enregistrez le nœud dans `setup.py` (voir `multiple_nodes.md`), puis compilez :

```bash
cd ~/turtlebot4_ws
colcon build --symlink-install --packages-select turtlebot4_python_tutorials
source install/local_setup.bash
```

Lancez avec le namespace de votre robot :

```bash
ros2 run turtlebot4_python_tutorials camera_snapshot --ros-args -r __ns:=/tbot<N>
```

Pour déclencher une capture depuis un autre terminal :

```bash
ros2 topic pub --once /tbot<N>/take_picture std_msgs/msg/Empty {}
```

La photo est sauvegardée sous `snapshot_<timestamp>.jpg` dans le répertoire de travail courant. N'importe quel autre nœud du système peut déclencher une capture en publiant sur le même topic, sans aucune modification du code.

---

## Dépannage

| Symptôme | Cause probable |
|----------|----------------|
| Avertissement `No image received yet` | La caméra ne publie pas ; vérifiez que le robot est désamarré et exécutez `ros2 topic hz` sur le topic image |
| Erreur d'import `cv_bridge` | Package non installé ; exécutez `sudo apt install ros-humble-cv-bridge` |
| L'image sauvegardée est noire ou déformée | Encodage incorrect ; essayez `desired_encoding='rgb8'` ou `'mono8'` et vérifiez l'encodage réel du topic avec `ros2 topic echo --once` |
| Le déclenchement n'a aucun effet | Namespace incorrect ; vérifiez avec `ros2 topic list \| grep take_picture` |
