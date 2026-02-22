# Modification de l'heure d'une automatisation Philips Hue en fonction de la première heure de cours

## Le besoin initial

J’utilise une automatisation du pont Hue pour allumer la lumière des chambres des enfants en simulant le lever du jour (fonctionnalité fournie par le pont Hue).  
J’ai essayer de faire l’équivalent avec HA, il est facile de créer une action qui allume progressivement la lumière mais cela ne donne pas du tout le même résultat. J’ai regardé l’utilisation des scènes ou essayer de faire une suite d’actions pour essayer de faire l’équivalent mais il me parait compliqué d’arriver à quelque chose de proche de ce qui est faite par le pont (début avec une lumière bleu puis qui passe à l’orange avant d’augmenter en intensité).

Donc j’en suis arrivé à la conclusion qu’il serait plus facile de modifier l’heure de démarrage de l’automatisation du pont Hue à l’aide des API.

## Installation
Le script est à copier dans le répertoire /config/scripts de HomeAssistant (le rendre exécutable).  
Si l'emplacement du fichier de configuration des intégrations n'est pas /config/.storage/core.config_entries, adapater la ligne d'initialisation de la variable FIC_CONFIG.  
Pour le reste, il ne devrait rien avoir d'autre à modifier dans ce script (l'heure par défaut est gérée dans l'automatisation, il n'est donc pas utile de la modifier dans le script).

Ajouter lignes suivantes dans le fichier configuration.yaml
```yaml
shell_command:
  hue_set_wakeup: >
    /config/scripts/hue_set_wakeup.sh
    "{{ automation_name }}"
    {{ hour }}
    {{ minute }}
    {{ state }}
```

### Paramétrage de l'automatisation HA
Créer une nouvelle automatisation et coller le contenu du fichier automatisation.yaml.  
Il faut modifier les lignes :
 - 10 (for_each) pour mettre les prénoms des enfants
 - 15 et 48 (sensor.pronote_) pour mettre le nom de famille
 - 21 pour adapter l'heure de révail par défaut
 - 57 (notify.mobile) pour l'envoi de notification sur le tél (si la récupération du paramètre next_alarm de Pronote échoue, il y a une notification sur le tél)

 ### Configuration de l'automatisation Hue
 Il faut créer sur le pont Hue des automatisations portant le nom "Réveil Prénom_enfant école" avec le scénario et la durée voulu.  
 Pour l'écart entre la première heure de court et l'allumage des lumières, utiliser le paramètre "Calcul de l'heure du réveil (en minutes, avant le premier cours du jour)" dans la configuration de chaque intégration Pronote.
