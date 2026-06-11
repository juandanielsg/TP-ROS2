# Aide-mémoire pour l'évaluation — Session 6

La dernière session est une **présentation de 15 minutes** qui retrace votre travail tout au long du cours. Ce document vous aide à la préparer.

---

## Format

- 15 minutes par groupe, suivies de quelques questions
- Format diaporama (n'importe quel outil : PowerPoint, Google Slides, LibreOffice Impress)
- Incluez des photos et vidéos prises pendant les sessions — elles constituent la principale preuve de votre travail

---

## Structure suggérée

### 1. Qu'est-ce que ROS ?
Une brève introduction non technique pour quelqu'un qui n'a jamais entendu parler de ROS :
- Quel problème résout-il ?
- Concepts clés : nœuds, topics, messages
- Pourquoi est-il utile en robotique

### 2. Le TurtleBot4
- De quel matériel il est composé (Raspberry Pi, Create3, LIDAR, caméra OAK-D)
- Comment il se connecte au réseau et à votre PC

### 3. Bilan des sessions
Parcourez chaque session dans l'ordre et montrez ce que vous avez accompli. Restez factuel : quel était l'objectif, qu'avez-vous lancé ou construit, et qu'avez-vous observé ? Utilisez captures d'écran, sorties terminal et vidéos.

| Session | Éléments clés à montrer |
|---------|------------------------|
| 2 | RViz en fonctionnement, sortie de `ros2 topic list`, sortie du nœud de surveillance batterie |
| 3 | Robot se déplaçant avec le clavier et la manette, RViz avec le repère odom |
| 4 | Sortie de l'odométrie dans le terminal, robot atteignant un point cible |
| 5 | Construction de la carte SLAM en cours, navigation autonome du robot, photo prise à destination |

### 4. Conclusion
- Bilan et réflexions.

---

## Liste de contrôle — À collecter pendant les sessions

Parcourez cette liste au fil de votre travail et assurez-vous d'avoir des preuves pour chaque point avant la Session 6.

**Session 2**
- [ ] Capture d'écran de la sortie de `ros2 topic list`
- [ ] Capture d'écran ou vidéo du lancement de RViz avec le modèle robot
- [ ] Sortie terminal de `ros2 topic echo /tbot<N>/battery_state`
- [ ] Sortie terminal de votre nœud de surveillance batterie en fonctionnement

**Session 3**
- [ ] Vidéo de la téléopération clavier
- [ ] Vidéo du contrôle avec la manette
- [ ] Capture d'écran de RViz avec le scan laser affiché et Fixed Frame = `odom`

**Session 4**
- [ ] Sortie terminal de votre nœud de lecture d'odométrie
- [ ] Vidéo du robot se dirigeant vers un point cible

**Session 5**
- [ ] Capture d'écran ou vidéo de la construction de la carte SLAM en temps réel
- [ ] Le fichier `map.pgm` sauvegardé (ouvrez-le et prenez une capture d'écran)
- [ ] Vidéo de la navigation autonome vers un objectif
- [ ] Photo prise par le robot à la fin de la mission

---

## Conseils

- **Commencez le diaporama tôt** — n'attendez pas la Session 6 pour ouvrir un fichier de présentation. Ajoutez une diapositive par session au fur et à mesure.
- **Racontez, ne lisez pas** — les diapositives illustrent ce que vous dites ; elles ne doivent pas contenir toutes vos phrases.
- **Expliquez votre raisonnement** — la présentation valorise la compréhension plus que l'achèvement. Un résultat partiel bien expliqué vaut mieux qu'un résultat complet que vous ne savez pas expliquer.
- **Montrez aussi les échecs** — si quelque chose n'a pas fonctionné, expliquez ce que vous avez essayé et ce que vous pensez qui s'est mal passé. Cela démontre votre compréhension.
