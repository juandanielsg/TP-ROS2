# TP ROS2 — TurtleBot4

Notes et exercices des travaux pratiques ROS2 Humble avec le TurtleBot4 Standard.

> Cette branche contient uniquement les supports de cours. Pour l'environnement de simulation Docker, voir la branche `main`.

---

## Contenu

### `Lectures/` — Sessions en anglais

| Dossier | Contenu |
|---------|---------|
| `Session-1/` | Introduction à ROS, prise en main du TurtleBot4, premières commandes, RViz |
| `Session-2/` | Premier nœud Python, publication et abonnement à des topics |
| `Session-3/` | Contrôle du robot, commandes de vitesse (`/cmd_vel`) |
| `Session-4/` | Odométrie, repère de référence, transformations TF |
| `Session-5/` | Navigation autonome et SLAM |
| `Session-6/` | Évaluation finale, grille de notation |
| `General/` | Fiches de référence (mode amarré, caméra, RQT, nœuds multiples) |

### `TPs/` — Sessions en français

Même contenu que ci-dessus, traduit en français.

### `scripts/` — Scripts utilitaires

Scripts shell pour interagir avec le robot physique (connexion SSH, détection sur le réseau, configuration de l'environnement, visualisation).

---

## Prérequis

- ROS2 Humble installé et sourcé sur votre machine
- Un TurtleBot4 accessible sur le réseau WiFi du laboratoire (`RHOBAN_100`)
- Le même `ROS_DOMAIN_ID` configuré sur votre PC et sur le robot
