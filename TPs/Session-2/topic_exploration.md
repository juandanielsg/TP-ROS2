# Exploration des topics — TurtleBot4

**Ce que vous allez faire :** explorer les topics publiés par votre TurtleBot4 à l'aide des outils en ligne de commande, comprendre ce que fournit chaque capteur, et publier votre premier message depuis le terminal.

---

## Prérequis

- ROS2 Humble sourcé et workspace compilé (voir `first_node.md`)
- TurtleBot4 allumé et accessible (remplacez `<N>` tout au long)

---

## 1. Découvrir les topics

Exécutez la commande suivante et déduisez du texte d'aide quelle sous-commande liste tous les topics actifs :

```bash
ros2 topic --help
```

Une fois trouvée, exécutez-la. Vous devriez voir plusieurs dizaines de topics préfixés par `/tbot<N>/`.

---

## 2. Le topic de la batterie

**Trouver le topic de la batterie :**

```bash
ros2 topic list | grep battery
```

**Lire sa valeur actuelle** (soyez patient ; l'état de la batterie est publié à basse fréquence) :

```bash
ros2 topic echo /tbot<N>/battery_state
```

**Inspecter le type de message en détail :**

```bash
ros2 topic info /tbot<N>/battery_state
ros2 interface show sensor_msgs/msg/BatteryState
```

Questions auxquelles répondre :
- Dans quelle unité est exprimée la capacité de la batterie ?
- Que représente le champ `voltage` ?
- Quelle est la signification du champ `power_supply_status` ?

---

## 3. Bande passante d'un topic

`ros2 topic bw` mesure la quantité de données qui transitent par un topic par seconde. Testez-le sur un topic haute fréquence :

```bash
ros2 topic bw /tbot<N>/scan
```

Puis sur un topic basse fréquence :

```bash
ros2 topic bw /tbot<N>/battery_state
```

Pourquoi la bande passante du LIDAR est-elle bien plus élevée ? Qu'implique-t-elle pour la conception des nœuds ?

---

## 4. Exploration des topics principaux

Pour chaque topic ci-dessous, utilisez `ros2 topic echo` et `ros2 interface show` pour comprendre ce qu'il publie. Répondez à la question associée à chacun.

| Topic | Question |
|-------|----------|
| `/tbot<N>/imu` | Que mesure l'IMU ? Quelles sont ses unités ? |
| `/tbot<N>/cliff_intensity` | Dans quel cas ce capteur se déclencherait-il ? |
| `/tbot<N>/dock_status` | Comment savoir si le robot est sur sa base ? |
| `/tbot<N>/hazard_detection` | Quels types de dangers sont détectés ? |
| `/tbot<N>/ip` | Quelle information ce topic publie-t-il ? |
| `/tbot<N>/joy` | Que contient ce topic lorsque vous appuyez sur un bouton de la manette ? |
| `/tbot<N>/wheel_vels` | Dans quelle unité sont exprimées les vitesses des roues ? |
| `/tbot<N>/diagnostics` | Que résume ce topic ? |

Pour inspecter le type de message d'un topic :

```bash
ros2 topic info /tbot<N>/<topic_name>
ros2 interface show <message_type>
```

---

## 5. L'odométrie en ligne de commande

Le topic `/tbot<N>/odom` fournit des estimations de position et d'orientation. Écoutez-le et répondez :

- Quels sont les types des champs de `pose` ? (`PoseWithCovariance`, `Pose`, `Point`, `Quaternion`)
- Que représente le champ `covariance` ?
- Quelle est la différence entre `pose` et `twist` dans ce message ?

L'orientation est exprimée en **quaternion** dans ROS2, et non sous forme d'angle simple. Plusieurs représentations existent (angles d'Euler, matrices de rotation, quaternions). Vous pouvez convertir entre elles à l'aide de cet outil : https://www.andre-gaschler.com/rotationconverter/

---

## 6. Publier depuis le terminal

Vous pouvez publier sur n'importe quel topic directement depuis le terminal sans écrire de nœud. Utilisez ceci pour faire bouger le robot :

```bash
ros2 topic pub --once /tbot<N>/cmd_vel geometry_msgs/msg/Twist \
    "{linear: {x: 0.2, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}"
```

Le robot a une latence ; il faudra peut-être publier plusieurs fois avant qu'il réagisse. Utilisez `--rate 5` à la place de `--once` pour publier en continu à 5 Hz.

- Que se passe-t-il si vous donnez une valeur négative à `linear.x` ?
- Quel champ contrôle la rotation ? Autour de quel axe ?
- Comment arrêter le robot ?

---

## 7. Exercice — Nœud de surveillance de la batterie

Écrivez un nœud Python qui s'abonne à `/tbot<N>/battery_state` et journalise les champs suivants à chaque message, avec leurs unités :

- Tension
- Température
- Capacité restante
- Pourcentage de charge

Utilisez le patron d'abonnement de `first_node.md`. Le type de message est `sensor_msgs/msg/BatteryState`.

```python
from sensor_msgs.msg import BatteryState
```

Note : le champ `percentage` est compris entre 0.0 et 1.0 ; multipliez par 100 pour l'afficher en pourcentage.

Format attendu des logs :

```
[INFO] [battery_monitor]: Voltage: 16.34 <?> | Temp: 28.1 <?> | Capacity: 1.83 <?> | Charge: 87.4 <?>
```
