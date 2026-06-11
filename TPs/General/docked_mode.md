# Mode amarré — TurtleBot4

*Juan Daniel S. G. — [juandanielsg.eu](https://juandanielsg.eu)*

Le TurtleBot4 se comporte différemment selon qu'il est posé sur sa station d'accueil ou non. Comprendre ces différences permet d'éviter une source fréquente de confusion lors des séances pratiques.

---

## Ce qui change lorsque le robot est amarré

| Fonctionnalité | Amarré | Désamarré |
|----------------|--------|-----------|
| Batterie | En charge | En décharge |
| Caméra (OAK-D) | **Désactivée** | Active |
| Anneau de LEDs | Contrôlé par le système (animation de charge) | Entièrement contrôlable |
| Réflexes moteurs | Supprimés | Actifs |
| Comportement général | Mode économie d'énergie | Fonctionnement complet |

> La caméra est inactive tant que le robot est sur sa base. Si vous ne voyez aucun topic d'image dans RViz, vérifiez d'abord si le robot est amarré.

---

## Vérifier l'état d'amarrage

Le topic `dock_status` indique l'état d'amarrage actuel :

```bash
ros2 topic echo /tbot<N>/dock_status
```

Le champ pertinent est `is_docked` : `true` lorsque le robot est sur la base, `false` sinon.

---

## Amarrer et désamarrer via ROS2

Le TurtleBot4 expose des actions ROS2 pour s'amarrer et se désamarrer de façon autonome. Le robot utilise ses capteurs infrarouges pour localiser et rejoindre la base.

**Désamarrer :**
```bash
ros2 action send_goal /tbot<N>/undock irobot_create_msgs/action/Undock {}
```

**Amarrer :**
```bash
ros2 action send_goal /tbot<N>/dock irobot_create_msgs/action/DockServo {}
```

Le robot naviguera automatiquement vers la base. Assurez-vous que la base est visible et dégagée avant d'envoyer la commande.

---

## Allumer et éteindre le robot

**Allumer :** placez le robot sur sa base ; il démarre automatiquement.

**Éteindre :** déplacez-le hors de la base, puis maintenez le bouton central (grand bouton circulaire) enfoncé pendant 10 secondes jusqu'à ce que le robot émette une courte mélodie et s'éteigne.

---

## Notes pratiques

- **Éteignez toujours le LIDAR lorsque le robot est amarré et non utilisé.** Le LIDAR consomme une puissance significative et déchargera la batterie même en charge s'il reste actif.
- **Ne lancez pas de nœuds de navigation ou de contrôle lorsque le robot est amarré.** Les commandes moteur sont supprimées ; le robot ne répondra pas et l'odométrie ne se mettra pas à jour correctement.
- **Redémarrez vos nœuds après le désamarrage.** Certains topics (notamment la caméra) ne deviennent actifs qu'une fois le robot sorti de la base ; les nœuds démarrés pendant l'amarrage peuvent ne pas recevoir de données avant d'être redémarrés.
