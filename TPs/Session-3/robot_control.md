# Contrôle du robot — TurtleBot4

*Juan Daniel S. G. — [juandanielsg.eu](https://juandanielsg.eu)*

**Ce que vous allez faire :** piloter le TurtleBot4 avec le clavier et la manette, puis apprendre à lire et modifier les paramètres du robot à l'exécution.

---

## Prérequis

- ROS2 Humble sourcé et workspace compilé (voir Session 2)
- TurtleBot4 accessible sur le réseau
- Votre numéro de robot (utilisé comme namespace ; remplacez `<N>` tout au long)

---

## 1. Téléopération clavier

Installez le package de téléopération s'il n'est pas encore présent :

```bash
sudo apt install ros-humble-teleop-twist-keyboard
```

Lancez-le en remappant vers le namespace de votre robot :

```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard \
    --ros-args -r __ns:=/tbot<N>
```

Le terminal affichera les raccourcis clavier. Le robot ne se déplace que lorsque la fenêtre est au premier plan.

| Touche | Action |
|--------|--------|
| `i` | Avancer |
| `,` | Reculer |
| `j` / `l` | Rotation gauche / droite |
| `u` / `o` | Diagonale avant |
| `k` | Arrêt |
| `q` / `z` | Augmenter / diminuer la vitesse |

> **Pourquoi le remap ?** `teleop_twist_keyboard` publie sur le topic relatif `cmd_vel`. Avec `__ns:=/tbot<N>`, ROS2 résout ce chemin en `/tbot<N>/cmd_vel`, topic sur lequel votre robot écoute. Sans le remap, la commande n'arrive nulle part.

---

## 2. Manette de jeu

La manette se connecte au **Raspberry Pi** du robot, pas au PC. Une fois appairée, le nœud `joy2twist` intégré au robot traduit automatiquement les entrées de la manette en commandes de vitesse.

### Conduire avec la manette

| Entrée | Action |
|--------|--------|
| Maintenir **L1** ou **R1** | Activer le mouvement (interrupteur homme-mort) |
| **Joystick gauche** (en maintenant L1/R1) | Avancer/tourner |

L'interrupteur homme-mort est intentionnel : relâcher L1/R1 arrête immédiatement le robot.

---

## 3. Utiliser les paramètres

Les paramètres ROS2 permettent de lire et modifier la configuration d'un nœud en cours d'exécution, sans modifier son code ni le redémarrer.

### Commandes utiles

```bash
ros2 param list <node_name>               # list all parameters of a node
ros2 param get <node_name> <param>        # read a parameter value
ros2 param set <node_name> <param> <val>  # change a parameter at runtime
```

### Exemple pratique — désactiver les réflexes du Create3

La base Create3 dispose de réflexes de sécurité intégrés (par exemple, elle recule automatiquement en cas de choc). Ces réflexes interfèrent avec le contrôle manuel. Vous pouvez les désactiver via des paramètres :

```bash
# List parameters of the motion_control node
ros2 param list /motion_control

# Disable all reflexes at once
ros2 param set /motion_control reflexes_enable false

# Or disable a specific reflex
ros2 param set /motion_control reflexes.REFLEX_BUMP false
```

Liste complète des réflexes disponibles : https://iroboteducation.github.io/create3_docs/api/reflexes/

> Les paramètres sont réinitialisés au redémarrage du nœud. Pour rendre une modification permanente, elle doit être définie dans un fichier de lancement ou un fichier de paramètres.

---

## 4. Observer le mouvement dans RViz

Lancez RViz pendant que vous conduisez pour observer ce que rapportent les capteurs du robot :

```bash
ros2 launch turtlebot4_viz view_robot.launch.py namespace:=tbot<N>
```

Une fois RViz ouvert, explorez l'affichage et répondez aux questions suivantes :

- Que représente le **nuage de points rouge** autour du robot ?
- Ouvrez le flux caméra en réglant le topic d'image sur `/tbot<N>/oakd/rgb/preview/image_raw`. Qu'est-ce qui est superposé à l'image ?
- À l'aide du bouton **Add** dans le panneau gauche, ajoutez un plugin **TF** et configurez-le pour n'afficher que le repère `base_link`.

Puis déplacez le robot (clavier ou manette) en observant RViz :

- Avec **Fixed Frame = `base_link`** : que se passe-t-il avec la carte et le scan laser lorsque le robot bouge ?
- Changez **Fixed Frame** en `odom` et déplacez le robot à nouveau. Qu'est-ce qui change ?
- À quoi fait référence le terme `odom`, et pourquoi ce repère est-il important pour la navigation ?

Nous utiliserons abondamment le repère `odom` en Session 4.

---

## Dépannage

| Symptôme | Cause probable |
|----------|----------------|
| Le robot ne répond pas au clavier | Vérifiez le namespace : exécutez `ros2 topic list` et confirmez que `/tbot<N>/cmd_vel` existe |
| La LED de la manette clignote mais le robot ne bouge pas | La manette n'est pas appairée au Raspberry Pi du robot ; recommencez l'appairage via SSH |
| Le robot bouge de façon inattendue après un choc | Les réflexes du Create3 sont actifs ; désactivez-les avec `ros2 param set /motion_control reflexes_enable false` |
| `ros2 param list /motion_control` ne retourne rien | Le nœud n'est pas lancé ou le namespace est incorrect ; vérifiez avec `ros2 node list` |
