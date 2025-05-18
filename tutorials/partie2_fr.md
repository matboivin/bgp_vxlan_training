## Partie 2

Cette section introduit **VXLAN**, une technologie clé pour les architectures modernes (virtualisées, distribuées, cloud-native). Les avantages de VXLAN :

Une scalabilité améliorée :

- VLAN : ID sur 12 bits -> **4 096 VLANs max**
- VXLAN : ID sur 24 bits -> **16 millions de réseaux possibles**.

Un overlay couche 3 et une meilleure isolation :

- **VLAN fonctionne en couche 2** (domaine de broadcast unique).
- **VXLAN encapsule les trames Ethernet dans UDP (couche 3)**, permettant ainsi de relier des VMs sur différents sites. Il y a un domaine de broadcast par VNI.

La [première partie](#3-unicast) montre comment créer un tunnel VXLAN manuel entre deux pairs. Cependant, cette manipulation peut être longue si on a plus d'un tunnel. La [seconde partie](#4-multicast) utilise un **groupe multicast** pour automatiser les connexions entre VTEPs et ainsi éviter de créer chaque paire à la main.

## Table des matières

- [Pré-requis](#pré-requis)
- [Conventions et bonnes pratiques](#conventions-et-bonnes-pratiques)
- [Tutoriel](#tutoriel)
    1. [Configurer GNS3](#1-configurer-gns3)
    2. [Créer le réseau](#2-créer-le-réseau)
    3. [Unicast](#3-unicast)
    4. [Multicast](#4-multicast)
    5. [Sauvegarder le projet](#5-sauvegarder-le-projet)
- [Soutenance](#soutenance)
- [Ressources](#ressources)

## 💡 Conventions et bonnes pratiques

Avant de commencer, voici quelques bonnes pratiques à suivre.

### Remplacer les commandes obsolètes

De nombreux exemples en ligne utilisent `brctl` de `bridge-utils`, mais cet outil est ancien et obsolète. Préférez `ip` et `bridge` du paquet `iproute2`.

### Port UDP VXLAN

> *Port de destination : IANA has assigned the value 4789 for the VXLAN UDP port, and this value SHOULD be used by default as the destination UDP port. [(source : RFC 7348)](https://datatracker.ietf.org/doc/html/rfc7348)*

### Choix des IDs

Il s'agit davantage d'une convention informelle pour faciliter le débug :

- **VLAN 10** : Utilisateurs (postes de travail)
- **VLAN 20** : Serveurs
- **VLAN 30** : Infrastructure (routeurs, commutateurs, management)
- **VLAN 40** : VoIP (téléphones)
- **VLAN 50** : Wi-Fi

Cette logique permet d'ajouter facilement d'autres VLANs plus tard si nécessaire (ex. : VLAN 11, 12... dans la plage utilisateurs).

Dans certaines architectures, un ID VLAN est mappé à un VXLAN (via un VNI), donc la nomenclature est conservée :

- VLAN `10` -> VXLAN `10` -> VNI `1010` -> `br10`
- VLAN `20` -> VXLAN `20` -> VNI `1020` -> `br20`

> ⚠️ Le sujet impose un bridge nommé `br0`.  
> Je pense qu'il devrait s'appeler `br10` pour montrer clairement son utilisation dans le VXLAN `10`. Comme montré dans [cet article](https://vincent.bernat.ch/en/blog/2017-vxlan-bgp-evpn), les VNI sont utilisés pour nommer les bridges.

### Conventions d'adressage IP

| **Plan de réseau**  | **Utilisation**                                  | **Exemples**                              |
| :------------------ | ------------------------------------------------ | ----------------------------------------- |
| **Underlay**        | Réseau IP de transport (entre les VTEPs)         | `192.0.2.0/24`, `10.100.0.0/16`           |
| **Overlay**         | Réseau logique VXLAN (entre VMs, conteneurs)     | `20.1.1.0/24`, `172.16.0.0/12`            |
| **Loopbacks**       | Identifiant logique pour VTEPs, router ID        | `10.0.0.0/32` – une IP unique par routeur |

> 💡 Une interface loopback sera configurée dans la partie 3.

## Pré-requis

Le projet se fait dans une machine virtuelle Linux dans laquelle il faut installer :

- GNS3
- Docker

Suivez ce guide : [GNS3 Linux Install](https://docs.gns3.com/docs/getting-started/installation/linux/).

## Tutoriel

### 1. Configurer GNS3

1. Démarrez GNS3.

2. Créez un nouveau projet nommé `P2` comme demandé dans le sujet.

### 2. Créer le réseau

1. Depuis la liste des équipements, glissez-déposez les deux routeurs, les deux hôtes et le switch ethernet pour correspondre au schéma fourni dans l'énoncé.

2. Pour relier les appareils, cliquez sur l'icône correspondante dans la barre d'outils à gauche :

   <img src="/tutorials/assets/p2/gns3_link_icon.png" alt="Liste des icônes pour créer un lien" height="400"/>

   Vous devez sélectionner les interfaces réseau comme spécifié dans le sujet. Ajustez le nombre d'adaptateurs réseau des hôtes pour correspondre au schéma.

   <img src="/tutorials/assets/p2/gns3_create_link.png" alt="Connexion des appareils" height="400"/>

   Pour plus de clarté, vous pouvez afficher les étiquettes des interfaces à partir de la barre d'outils en haut (l'icône avec "ABC").

3. Choisissez les adresses IP à utiliser :

   | **Appareil** | **Interface** | **Adresse IP**    |
   | :----------- | :------------ | :---------------- |
   | Routeur-1    | `eth0`        | 192.168.2.1/24    |
   | Routeur-2    | `eth0`        | 192.168.2.2/24    |
   | Hôte-1       | `eth1`        | 30.1.1.1/24       |
   | Hôte-2       | `eth1`        | 30.1.1.2/24       |

### 3. Unicast

Pour découvrir ce qu'est un VXLAN, créons-en un manuellement. Le sujet demande un VXLAN avec le VNI `10` et un bridge appelé `br10`. Les deux routeurs seront les deux extrémités du tunnel, appelées VTEPs.

1. **Configurer le premier routeur** :

   Configurer l'adresse IP sur `eth0` :

   ```sh
   /sbin/ip addr add 192.168.2.1/24 dev eth0
   ```

   Créer le tunnel VXLAN avec l'ID `10` :

   ```sh
   /sbin/ip link add name vxlan10 type vxlan id 10 dstport 4789 local 192.168.2.1 remote 192.168.2.2 dev eth0
   ```

   `remote <IP>` est l'adresse IP du routeur distant et `local <IP>` est l'adresse IP locale du routeur. `dev <interface>` spécifie l'interface à utiliser pour les paquets UDP. Le port destination UDP est toujours `4789` ([RFC 7348](https://datatracker.ietf.org/doc/html/rfc7348)).

   Activer le tunnel :

   ```sh
   /sbin/ip link set dev vxlan10 up
   ```

   Voici notre premier VTEP !

   Puisque le projet tourne dans une machine virtuelle Linux, un bridge est requis pour remplacer le VLAN. Il relie les interfaces `eth1` des hôtes et le tunnel VXLAN dans un réseau de niveau 2 comme un switch Ethernet.

   Créer et activer un bridge nommé `br10` :

   ```sh
   /sbin/ip link add br10 type bridge
   /sbin/ip link set dev br10 up
   ```

   Attacher les interfaces au bridge pour connecter les hôtes au tunnel VXLAN :

   ```sh
   /sbin/ip link set vxlan10 master br10
   /sbin/ip link set eth1 master br10
   ```

2. **Même chose pour le deuxième routeur :**

   Configurer l'adresse IP sur `eth0` :

   ```sh
   /sbin/ip addr add 192.168.2.2/24 dev eth0
   ```

   Créer et activer le tunnel VXLAN avec l'ID `10` pour avoir le second VTEP :

   ```sh
   /sbin/ip link add name vxlan10 type vxlan id 10 dstport 4789 local 192.168.2.2 remote 192.168.2.1 dev eth0
   /sbin/ip link set dev vxlan10 up
   ```

   Créer et activer un bridge nommé `br10` :

   ```sh
   /sbin/ip link add br10 type bridge
   /sbin/ip link set dev br10 up
   ```

   Attacher les interfaces au bridge :

   ```sh
   /sbin/ip link set vxlan10 master br10
   /sbin/ip link set eth1 master br10
   ```

3. **Configurer le premier hôte :**

   ```sh
   /sbin/ip addr add 30.1.1.1/24 dev eth1
   ```

4. **Configurer le second hôte :**

   ```sh
   /sbin/ip addr add 30.1.1.2/24 dev eth1
   ```

5. Les hôtes devraient pouvoir échanger un ping.

💡 **Remarques**

Même si cette [vidéo tutorielle](https://www.youtube.com/watch?v=u1ka-S6F9UI) montre qu'il faut configurer une adresse IP sur le tunnel VXLAN, ce n'est pas nécessaire car il est attaché au bridge et fonctionne en couche 2 (il transporte des trames Ethernet, pas des paquets). Considérez-le comme un câble Ethernet virtuel entre deux switches.

Le bridge n'a pas non plus besoin d'adresse IP puisqu'il opère en couche 2.

### 4. Multicast

Dans cette topologie, il n'y a qu'un seul tunnel. Et s'il y en avait plusieurs ? Configurer manuellement chaque pair distant pour chaque VTEP serait très chronophage ! C'est pourquoi il est temps de découvrir le **multicast**. Un **groupe multicast IP** est associé à un VNI pour relier les VTEPs.

Lors de la création du tunnel VXLAN, au lieu de spécifier l'adresse IP du pair distant (`remote <IP>`), on définit un groupe avec une adresse IP (`group <IP>`). Lorsqu'une trame doit être transmise aux membres du VNI, les VTEPs l'envoient à l'adresse du groupe. Tous les VTEPs abonnés à ce groupe recevront la trame. Plus besoin de configurer chaque tunnel entre pairs.

L'adresse multicast IP peut être nommée avec le VNI comme dernier octet pour plus de clarté : VNI `10` -> `239.1.1.10`

Même si certaines commandes doivent être mises à jour (préférez les utilitaires `iproute2`), cet [article](https://vincent.bernat.ch/en/blog/2017-vxlan-linux) détaille la procédure avec d'excellentes explications.

1. **Configurer le premier routeur** :

   Configurer l'adresse IP sur `eth0` :

   ```sh
   /sbin/ip addr add 192.168.2.1/24 dev eth0
   ```

   Créer et activer le tunnel VXLAN. La seule chose qui change ici est l'adresse **du groupe multicast** qui remplace l'adresse distante.

   ```sh
   /sbin/ip link add name vxlan10 type vxlan id 10 dstport 4789 local 192.168.2.1 group 239.1.1.10 dev eth0
   /sbin/ip link set dev vxlan10 up
   ```

   Comme dans la partie unicast, créer et activer le bridge nommé `br10`. Y attacher les interfaces.

   ```sh
   /sbin/ip link add br10 type bridge
   /sbin/ip link set dev br10 up
   /sbin/ip link set vxlan10 master br10
   /sbin/ip link set eth1 master br10
   ```

2. **Même chose pour le deuxième routeur** :

   Configurer l'adresse IP sur `eth0` :

   ```sh
   /sbin/ip addr add 192.168.2.2/24 dev eth0
   ```

   Ensuite, tout est identique au premier routeur (à l'exception de l'adresse IP locale bien sûr) :

   ```sh
   /sbin/ip link add name vxlan10 type vxlan id 10 dstport 4789 local 192.168.2.2 group 239.1.1.10 dev eth0
   /sbin/ip link set dev vxlan10 up
   /sbin/ip link add br10 type bridge
   /sbin/ip link set dev br10 up
   /sbin/ip link set vxlan10 master br10
   /sbin/ip link set eth1 master br10
   ```

3. **Configurer le premier hôte** :

   ```sh
   /sbin/ip addr add 30.1.1.1/24 dev eth1
   ```

4. **Configurer le second hôte** :

   ```sh
   /sbin/ip addr add 30.1.1.2/24 dev eth1
   ```

5. Les hôtes devraient pouvoir échanger un ping.

### 5. Sauvegarder le projet

Les modifications ne sont pas persistantes. Créez des scripts Shell pour configurer les routeurs.

Le projet doit être exporté en archive ZIP. Dans la barre de menu, cliquez sur `File` > `Export portable project`. Incluez les images de base comme demandé.

## Soutenance

Le [répertoire `docker`](/docker/) contient un Dockerfile pour le routeur avec des scripts de configuration reprenant les commandes utilisées plus haut.

Depuis la racine du projet :

```sh
$ docker build -t router_mboivin docker
```

## Ressources

- [🇫🇷 VXLAN : des VLANs dynamiques et routables pour les clouds](https://blog.bluetrusty.com/2020/09/25/vxlan-des-vlans-dynamiques-et-routables-pour-les-clouds/)
- [VXLAN Bridge](https://docs.opnsense.org/manual/how-tos/vxlan_bridge.html)
- [VXLAN & Linux](https://vincent.bernat.ch/en/blog/2017-vxlan-linux)
- [VXLAN Flood and Learn Multicast Data Plane](https://networklessons.com/vxlan/vxlan-flood-and-learn-multicast-data-plane)
- Tutoriel pas-à-pas mais je ne suis pas d'accord avec tout : [🎥 GNS3: FRRouting Using Docker Platform - VXLANs](https://www.youtube.com/watch?v=u1ka-S6F9UI)
- Pas le logiciel qui nous intéresse mais explications claires : [🇫🇷 Création d'un pont réseau avec un VXLAN attaché](https://docs.redhat.com/fr/documentation/red_hat_enterprise_linux/9/html/configuring_and_managing_networking/proc_creating-a-network-bridge-with-a-vxlan-attached_assembly_using-a-vxlan-to-create-a-virtual-layer-2-domain-for-vms#proc_creating-a-network-bridge-with-a-vxlan-attached_assembly_using-a-vxlan-to-create-a-virtual-layer-2-domain-for-vms)
