# Plusieurs nœuds dans un même package

*Juan Daniel S. G. — [juandanielsg.eu](https://juandanielsg.eu)*

**Ce que vous allez apprendre :** comment ajouter plusieurs nœuds ROS2 à un même package Python afin de pouvoir tous les lancer avec `ros2 run`, sans créer un package séparé pour chacun.

---

## Prérequis

- Un package ROS2 Python fonctionnel (voir Session 2)
- Familiarité avec le fichier `setup.py` généré par `ros2 pkg create`

---

## 1. Fonctionnement

Lorsque `ros2 pkg create` génère un package, il enregistre un nœud comme point d'entrée dans `setup.py` :

```python
entry_points={
    'console_scripts': [
        'turtlebot4_first_python_node = turtlebot4_python_tutorials.turtlebot4_first_python_node:main',
    ],
},
```

Chaque ligne de `console_scripts` associe un nom de commande à une paire `module:fonction`. Ajouter un nouveau nœud revient simplement à :

1. Créer un nouveau fichier `.py` dans le répertoire du package.
2. Ajouter une nouvelle ligne dans `console_scripts`.
3. Recompiler.

---

## 2. Structure des fichiers

Placez chaque fichier de nœud dans le répertoire du package interne (celui qui contient `__init__.py`) :

```
turtlebot4_python_tutorials/
├── package.xml
├── setup.py
├── setup.cfg
└── turtlebot4_python_tutorials/
    ├── __init__.py
    ├── turtlebot4_first_python_node.py   ← nœud existant
    ├── odom_reader.py                    ← nouveau nœud
    └── battery_monitor.py               ← autre nouveau nœud
```

Chaque fichier doit définir une fonction `main()`, qui est le point d'entrée que ROS2 appellera.

---

## 3. Enregistrer les nouveaux nœuds

Ouvrez `setup.py` et ajoutez une ligne par nouveau nœud dans `console_scripts` :

```python
entry_points={
    'console_scripts': [
        'turtlebot4_first_python_node = turtlebot4_python_tutorials.turtlebot4_first_python_node:main',
        'odom_reader        = turtlebot4_python_tutorials.odom_reader:main',
        'battery_monitor    = turtlebot4_python_tutorials.battery_monitor:main',
    ],
},
```

Le format de chaque entrée est :

```
'<nom_commande> = <nom_package>.<nom_module>:<nom_fonction>'
```

- `nom_commande` : ce que vous tapez après `ros2 run <package>`
- `nom_package` : le package Python (même nom que le répertoire contenant `__init__.py`)
- `nom_module` : le nom du fichier sans `.py`
- `nom_fonction` : généralement `main`

---

## 4. Compiler et lancer

Recompilez le package pour enregistrer les nouveaux points d'entrée :

```bash
cd ~/turtlebot4_ws
colcon build --symlink-install --packages-select turtlebot4_python_tutorials
source install/local_setup.bash
```

> Même avec `--symlink-install`, vous devez recompiler à chaque modification de `setup.py`. Les modifications des fichiers `.py` de nœuds ne nécessitent pas de recompilation.

Lancez ensuite n'importe quel nœud par son nom de commande :

```bash
ros2 run turtlebot4_python_tutorials odom_reader --ros-args -r __ns:=/tbot<N>
ros2 run turtlebot4_python_tutorials battery_monitor --ros-args -r __ns:=/tbot<N>
```

---

## 5. Partager du code entre les nœuds

Si plusieurs nœuds utilisent le même helper (par exemple la fonction `quaternion_to_yaw` de la Session 4), extrayez-le dans un fichier séparé plutôt que de le copier :

```
turtlebot4_python_tutorials/
└── turtlebot4_python_tutorials/
    ├── __init__.py
    ├── utils.py                  ← fonctions utilitaires partagées
    ├── odom_reader.py
    └── battery_monitor.py
```

Importez-le comme n'importe quel module Python classique :

```python
from turtlebot4_python_tutorials.utils import quaternion_to_yaw
```

N'ajoutez **pas** `utils.py` dans `console_scripts` ; c'est un fichier bibliothèque, pas un nœud.

---

## Dépannage

| Symptôme | Cause probable |
|----------|----------------|
| `ros2 run` signale que l'exécutable est introuvable | Nouvelle entrée absente de `console_scripts`, ou package non recompilé après modification de `setup.py` |
| `ModuleNotFoundError` à l'exécution | Le fichier n'est pas dans le répertoire du package interne, ou `install/local_setup.bash` n'a pas été sourcé après la recompilation |
| Les modifications du code du nœud n'ont aucun effet | Avec `--symlink-install` cela ne devrait pas arriver ; si c'est le cas, vérifiez que le lien symbolique pointe vers le bon fichier avec `ls -la install/` |
