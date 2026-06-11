# Messages personnalisés — TurtleBot4

*Juan Daniel S. G. — [juandanielsg.eu](https://juandanielsg.eu)*

**Ce que cette session couvre :** définir ses propres types de messages ROS2, les compiler et les utiliser dans une paire publisher/subscriber.

---

## 1. Pourquoi des messages personnalisés

ROS2 fournit des packages de messages standard qui couvrent la grande majorité des types de données courants :

| Package | Contenu typique |
|---------|----------------|
| `std_msgs` | Primitives : `Bool`, `Int32`, `Float64`, `String`, … |
| `geometry_msgs` | Poses, vitesses, transformations, points |
| `sensor_msgs` | Scans LIDAR, images, IMU, état de la batterie |
| `nav_msgs` | Odométrie, grilles d'occupation, chemins |

Quand aucun de ces types ne correspond exactement à vos données, vous définissez votre propre fichier `.msg`. Le système de build génère automatiquement le code Python et C++ correspondant.

---

## 2. Syntaxe de définition de message

Un fichier `.msg` est une liste de champs typés en texte brut, un par ligne :

```
string  label
float64 value
bool    is_valid
```

Types primitifs disponibles : `bool`, `byte`, `char`, `float32`, `float64`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`, `string`.

Vous pouvez également imbriquer des types de messages existants comme champs :

```
std_msgs/Header header
geometry_msgs/Point position
float32         confidence
```

Et déclarer des tableaux de taille fixe ou variable :

```
float32[3]  rgb           # tableau fixe de 3 éléments
string[]    labels        # tableau de taille variable
```

---

## 3. Structure du package

Les définitions de messages personnalisés doivent se trouver dans un **package dédié** qui ne contient que des fichiers d'interface — pas de code Python ou C++. Cela dissocie l'interface de toute implémentation et permet aux autres packages d'en dépendre proprement.

```
my_msgs/
├── msg/
│   └── MyMessage.msg     ← un fichier par type de message
├── CMakeLists.txt
└── package.xml
```

Les noms de fichiers de messages utilisent le **UpperCamelCase**. La classe Python générée porte le même nom.

---

## Dépannage

| Symptôme | Cause probable |
|----------|---------------|
| `ModuleNotFoundError` à l'import du message | Package non compilé, ou `install/local_setup.bash` non sourcé |
| `Unknown message type` dans `ros2 topic echo` | Idem — sourcez l'overlay du workspace |
| Le build échoue avec une erreur `rosidl` | `CMakeLists.txt` ou `package.xml` manque l'appel à `rosidl_generate_interfaces` |
| Collision de nom de champ | Les noms de champs doivent être en `snake_case` ; les noms en CamelCase sont rejetés par le parseur |
