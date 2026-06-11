# rqt — Outils de débogage graphiques

**Ce que c'est :** une collection de plugins graphiques pour inspecter et interagir avec un système ROS2 en fonctionnement. Chaque outil complète les outils en ligne de commande que vous connaissez déjà, en présentant les mêmes informations dans une interface plus facile à parcourir.

---

## Lancer rqt

Tous les plugins peuvent être chargés depuis une seule fenêtre :

```bash
rqt
```

Ouvrez ensuite un plugin depuis le menu : **Plugins → (catégorie) → (outil)**.

Chaque outil peut également être lancé directement en fenêtre autonome, comme indiqué dans chaque section ci-dessous.

---

## rqt_graph — Graphe des nœuds et topics

Affiche le graphe en direct de tous les nœuds et des topics qui les relient. Indispensable pour comprendre quels nœuds communiquent entre eux et repérer les connexions manquantes.

```bash
rqt_graph
```

| Bouton | Effet |
|--------|-------|
| Actualiser | Redessine le graphe avec l'état actuel |
| Nodes only | Masque les topics, affiche uniquement les connexions nœud à nœud |
| Nodes/Topics (all) | Affiche tous les topics, y compris ceux sans abonné actif |

> Utilisez cet outil chaque fois qu'un nœud ne semble pas recevoir de messages : si l'arête attendue est absente du graphe, c'est qu'il y a une incohérence de namespace ou un nœud non démarré.

---

## rqt_topic — Navigateur de topics

L'équivalent graphique de `ros2 topic list` et `ros2 topic echo` combinés. Permet de parcourir tous les topics actifs, voir leurs types et fréquences, et développer les champs de messages sans taper le nom complet du topic.

```bash
ros2 run rqt_topic rqt_topic
```

Cochez la case à côté d'un topic pour commencer à afficher ses valeurs dans le tableau. Utile pour explorer rapidement le contenu d'un message avant d'écrire un abonné.

---

## rqt_plot — Tracé de données en direct

Trace les champs numériques d'un topic en fonction du temps. Utile pour surveiller des valeurs qui évoluent en continu : tension de la batterie, vitesses des roues, position en odométrie, distances LIDAR.

```bash
rqt_plot
```

Saisissez le chemin d'un champ de topic dans la boîte de saisie et appuyez sur Entrée pour l'ajouter au tracé. La syntaxe est :

```
/tbot<N>/odom/pose/pose/position/x
/tbot<N>/battery_state/voltage
/tbot<N>/wheel_vels/velocity_left
```

Plusieurs champs peuvent être tracés simultanément sur le même graphe.

---

## rqt_console — Visionneuse de logs

Affiche la sortie de log de tous les nœuds en cours d'exécution au même endroit, avec filtrage par niveau de sévérité et par nom de nœud. Plus pratique que de lire plusieurs terminaux lorsque plusieurs nœuds tournent en parallèle.

```bash
ros2 run rqt_console rqt_console
```

| Niveau | Signification |
|--------|---------------|
| DEBUG | Informations internes détaillées |
| INFO | Messages de fonctionnement normal |
| WARN | Quelque chose d'inattendu mais récupérable |
| ERROR | Une défaillance affectant le comportement du nœud |
| FATAL | Le nœud ne peut pas continuer |

---

## rqt_image_view — Visionneuse de caméra

Affiche le flux d'images de n'importe quel topic image. Plus simple que de configurer RViz lorsque vous voulez simplement voir ce que voit la caméra.

```bash
ros2 run rqt_image_view rqt_image_view
```

Sélectionnez le topic dans la liste déroulante en haut. Pour la caméra du TurtleBot4 :

```
/tbot<N>/oakd/rgb/preview/image_raw
```

> La caméra est inactive lorsque le robot est amarré ; si aucune image n'apparaît, vérifiez d'abord l'état d'amarrage (voir `docked_mode.md`).

---

## Référence rapide

| Outil | Commande de lancement | Équivalent CLI |
|-------|----------------------|----------------|
| Graphe nœuds/topics | `rqt_graph` | `ros2 node list` + `ros2 topic list` |
| Navigateur de topics | `ros2 run rqt_topic rqt_topic` | `ros2 topic echo` |
| Tracé en direct | `rqt_plot` | `ros2 topic echo` + lecture manuelle |
| Visionneuse de logs | `ros2 run rqt_console rqt_console` | sortie terminal |
| Visionneuse caméra | `ros2 run rqt_image_view rqt_image_view` | — |
