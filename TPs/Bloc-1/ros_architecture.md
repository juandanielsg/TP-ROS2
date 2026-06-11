# Architecture ROS — Patrons de communication

*Juan Daniel S. G. — [juandanielsg.eu](https://juandanielsg.eu)*

**Ce que cette session couvre :** les trois primitives de communication que ROS2 propose — les topics, les services et les actions. Savoir quand utiliser chacune d'elles est la base de tout système ROS2 que vous construirez.

---

## 1. Publishers et Subscribers

Le patron **pub/sub** est la façon la plus courante d'échanger des données entre nœuds dans ROS2. Un publisher envoie des messages sur un topic nommé ; n'importe quel nombre de subscribers les reçoit indépendamment.

```
[ nœud capteur ]
      │  publie /scan
      ▼
  [ topic /scan ]
      ├──▶ [ nœud cartographie ]
      ├──▶ [ nœud évitement d'obstacles ]
      └──▶ [ nœud journalisation ]
```

Le publisher ne sait pas qui écoute, ni si quelqu'un écoute. Les subscribers ne savent pas d'où viennent les données. Les deux côtés se mettent uniquement d'accord sur le **nom du topic** et le **type de message**. La communication est **asynchrone** : le publisher envoie et passe à autre chose ; le subscriber est rappelé à chaque arrivée d'un message.

### Propriétés clés

| Propriété | Valeur |
|-----------|--------|
| Direction | Un-vers-plusieurs (fan-out) |
| Timing | Asynchrone |
| Couplage | Anonyme — aucun des deux côtés ne connaît l'autre |
| Idéal pour | Flux de données continus (capteurs, estimations d'état, images) |

### Inspecter les topics depuis le terminal

```bash
ros2 topic list                        # tous les topics actifs
ros2 topic echo /tbot<N>/scan          # afficher les messages à leur arrivée
ros2 topic info /tbot<N>/scan          # type de message et nombre de connexions
ros2 topic hz   /tbot<N>/scan          # fréquence de publication
ros2 topic bw   /tbot<N>/scan          # bande passante en octets/s
```

### QoS

Chaque publisher et subscriber déclare un profil de **Qualité de Service**. Les paramètres les plus importants sont :

| Paramètre | Options | Effet |
|-----------|---------|-------|
| Fiabilité | `RELIABLE` / `BEST_EFFORT` | Si les messages perdus sont retransmis |
| Durabilité | `VOLATILE` / `TRANSIENT_LOCAL` | Si les subscribers tardifs reçoivent le dernier message mis en cache |
| Historique | `KEEP_LAST(N)` / `KEEP_ALL` | Combien de messages sont mis en mémoire tampon |

Les données de capteurs utilisent généralement `BEST_EFFORT` (vitesse plutôt que garantie). Les données de configuration ou d'état utilisent `RELIABLE` + `TRANSIENT_LOCAL` pour qu'un nœud démarré tard reçoive quand même la dernière valeur.

> Une incompatibilité de QoS est une source fréquente de défaillances silencieuses : la connexion apparaît dans `ros2 topic info` mais aucun message n'est jamais délivré.

---

## 2. Services

Un **service** est une interaction synchrone requête-réponse. Le client envoie une **requête** et se bloque jusqu'à ce que le serveur retourne une **réponse**. Contrairement à un topic, il n'y a pas de flux continu — c'est un échange unique et atomique.

```
[ nœud client ] ──── requête ────▶ [ nœud serveur ]
                ◀─── réponse ────
```

### Propriétés clés

| Propriété | Valeur |
|-----------|--------|
| Direction | Un client vers un serveur |
| Timing | Synchrone — le client se bloque jusqu'à la réponse |
| Idéal pour | Configuration, commandes ponctuelles, requêtes d'état |

### Quand utiliser un service plutôt qu'un topic

Utilisez un service quand :
- L'appelant a besoin d'une réponse garantie avant de continuer.
- L'opération est une commande ou une requête, pas un flux de données.
- L'interaction se produit ponctuellement, pas en continu.

### Inspecter les services depuis le terminal

```bash
ros2 service list                                            # tous les services actifs
ros2 service type /tbot<N>/e_stop                           # type du service
ros2 interface show irobot_create_msgs/srv/EStop            # définition requête/réponse
ros2 service call /tbot<N>/e_stop \
    irobot_create_msgs/srv/EStop "{e_stop_on: true}"        # appel direct
```

### Exemples TurtleBot4

| Service | Ce qu'il fait |
|---------|--------------|
| `/tbot<N>/e_stop` | Engage ou relâche l'arrêt d'urgence |
| `/tbot<N>/robot_power` | Éteint la base Create3 |
| `/tbot<N>/motion_control` | Active ou désactive le contrôle moteur |

> N'utilisez pas un service pour des opérations qui prennent plus d'une fraction de seconde. Le nœud appelant est gelé pendant toute la durée. Pour tout ce qui dure plus longtemps, utilisez une action (Section 3).

---

## 3. Serveurs d'action

Une **action** est conçue pour les tâches de longue durée où le client veut un **feedback** périodique pendant l'exécution et la possibilité d'**annuler** en cours de route. Le résultat n'a de sens qu'une fois la tâche terminée.

```
[ client ]
   │  envoie le Goal
   ▼
[ serveur d'action ]              [ client ]
   │                                  ▲
   ├── Feedback (répété) ─────────────┤
   │                                  │
   └── Result (une fois, à la fin) ───┘
```

Chaque action comporte exactement trois parties :

| Partie | Quand elle est envoyée | Contenu |
|--------|----------------------|---------|
| **Goal** | Une fois, par le client | Ce qu'il faut faire |
| **Feedback** | Répétitivement, par le serveur | Mises à jour de progression |
| **Result** | Une fois, par le serveur | Résultat final (succès ou échec) |

### Propriétés clés

| Propriété | Valeur |
|-----------|--------|
| Direction | Un client vers un serveur |
| Timing | Asynchrone avec feedback en flux |
| Annulable | Oui — le client peut annuler à tout moment |
| Idéal pour | Navigation, toute tâche multi-étapes avec progression visible |

### Inspecter les actions depuis le terminal

```bash
ros2 action list                            # tous les serveurs d'action actifs
ros2 action info /tbot<N>/dock              # types du goal, feedback et result
ros2 action send_goal \
    /tbot<N>/dock \
    irobot_create_msgs/action/Dock "{}"     # envoyer un goal et attendre le résultat
```

Pour afficher également les messages de feedback pendant l'exécution :

```bash
ros2 action send_goal --feedback \
    /tbot<N>/dock \
    irobot_create_msgs/action/Dock "{}"
```

### Exemples TurtleBot4

| Action | Goal | Feedback | Result |
|--------|------|----------|--------|
| `/tbot<N>/dock` | (aucun) | `is_docked` | `is_docked` |
| `/tbot<N>/undock` | (aucun) | (aucun) | `is_docked` |
| `/tbot<N>/wall_follow` | `follow_side`, `max_runtime` | `pose` | `runtime_elapsed` |
| `/tbot<N>/navigate_to_pose` | `pose` cible | `current_pose`, `distance_remaining` | `result` |

---

## 4. Choisir le bon patron

| Situation | Utiliser |
|-----------|---------|
| Flux de données continu (capteur, estimation, image) | Topic |
| Activer ou désactiver une fonctionnalité | Service |
| Interroger une valeur et agir sur la réponse | Service |
| Se déplacer vers une position | Action |
| Toute tâche qui dure plus de ~100 ms | Action |
| Toute tâche que l'utilisateur pourrait vouloir annuler | Action |

Une erreur courante est d'encapsuler une tâche de longue durée dans un service. Le processus client se fige pendant toute la durée et ne peut réagir à rien d'autre. Si la tâche prend plus d'une fraction de seconde, la réponse est toujours une action.

---

## Dépannage

| Symptôme | Cause probable |
|----------|---------------|
| Le subscriber ne reçoit rien malgré un publisher actif | Incompatibilité QoS ; vérifiez les paramètres de fiabilité et de durabilité des deux côtés |
| L'appel de service se bloque indéfiniment | Le nœud serveur n'est pas lancé, ou il est bloqué sur un calcul long |
| Le goal d'une action est rejeté immédiatement | Validation du goal échouée ; vérifiez les noms de champs avec `ros2 interface show` |
| `ros2 action list` ne montre rien | Le serveur d'action n'est pas encore démarré ; le nœud est peut-être encore en cours d'initialisation |
| `ros2 service call` renvoie une erreur de type inconnu | Package non installé ou ROS2 non sourcé |
