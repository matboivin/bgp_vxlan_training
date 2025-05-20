# Partie 3

Cette dernière partie est une démonstration de comment **BGP EVPN** est utilisé avec **VXLAN** dans un petit data center.

**VXLAN** est le [plan de données](https://www.cloudflare.com/learning/network-layer/what-is-the-control-plane/) — responsable du transfert des paquets.

**BGP EVPN** est le [plan de contrôle](https://www.ibm.com/think/topics/control-plane) — il définit et gère comment le trafic doit être transféré à travers le réseau.

Si on voulait que toutes les routes soient connues par l'ensemble des routeurs de notre data center, il faudrait faire un *full mesh*. Or, cette solution n'est pas scalable. Une solution plus souple est de configurer un ***route reflector*** chargé de distribuer les routes apprises à ses pairs iBGP.

> 💡 Nous ne nous intéressons pas à eBGP mais seulement à iBGP utilisé à l'intérieur d'un AS pour relier les routeurs internes. Cependant, on pourrait utiliser eBGP en simulant deux AS en utilisant des numéros d'AS privés (plage 64512-65534) sans faire d'annonces vers Internet.

## Table des matières

- [Conventions et bonnes pratiques](#conventions-et-bonnes-pratiques)
- [Pré-requis](#pré-requis)
- [Tutoriel](#tutoriel)
    1. [Configurer GNS3](#1-configurer-gns3)
    2. [Créer le réseau](#2-créer-le-réseau)
    3. [Configuration](#3-configuration)
    4. [Sauvegarder le projet](#4-sauvegarder-le-projet)
- [Soutenance](#soutenance)
- [Ressources](#ressources)

## 💡 Conventions et bonnes pratiques

### À propos des interfaces loopback

Créer une **interface loopback avec une IP routable pour un VTEP** est une bonne pratique :

- Les interfaces loopback **sont toujours actives** tant que l'équipement fonctionne, contrairement aux interfaces physiques qui peuvent tomber. Elles ne dépendent donc pas d'un port physique, ce qui les rend accessibles malgré les changements d'état des liens/interfaces.
- Cela garantit un identifiant VTEP stable pour les protocoles comme BGP (ils utilisent l'IP source comme identifiant).
- Même chose pour l'identifiant OSPF du routeur, qui est aussi l'adresse IP de la loopback.

Pourquoi `/32` pour les loopback ? Parce que :

- La loopback ne communique qu'avec elle-même — pas besoin de voisins dans le même sous-réseau.
- Des protocoles comme OSPF, BGP et IS-IS préfèrent router vers une IP unique.

Toujours prévoir un sous-réseau dédié issu d'une plage privée pour les adresses loopback. Elles sont utilisées comme Router ID (RID) par OSPF, ce qui limite les risques de duplication.

## Pré-requis

Le projet se fait dans une machine virtuelle Linux dans laquelle il faut installer :

- GNS3
- Docker

Suivez ce guide : [GNS3 Linux Install](https://docs.gns3.com/docs/getting-started/installation/linux/).

## Tutoriel

### 1. Configurer GNS3

1. Démarrez GNS3.

2. Créez un nouveau projet nommé `P3` comme demandé dans le sujet.

### 2. Créer le réseau

### 2. Créer le réseau

1. Depuis la liste des équipements, glissez-déposez les quatre routeurs et les trois hôtes pour correspondre au schéma de l'énoncé.

   Le premier routeur sera utilisé comme **Route Reflector**. Il y a généralement un seul routeur BGP jouant le rôle de Route Reflector dans les data centers, placé au sommet de la hiérarchie. Il sera connecté à tous les autres routeurs mais à aucun hôte. Ce routeur est le *spine*. Les trois autres, connectés aux hôtes mais non connectés aux autres routeurs sauf au *spine*, sont les *leaves*.

**Pourquoi un Route Reflector ?** Sans lui, une **topologie full mesh** serait nécessaire. Dans ce genre de réseau, chaque équipement est directement connecté à tous les autres. Ce n'est pas scalable si le nombre de routeurs augmente. Le Route Reflector permet de partager les routes iBGP entre pairs iBGP. Il reçoit les routes de ses clients et les reflète à tous les autres clients.

2. Reliez les équipements.

   <img src="/tutorials/assets/p3/gns3_topology.png" alt="Topologie réseau" height="400"/>

   Comme vous pouvez le voir, j'ai changé la manière dont sont reliés les équipements par rapport au sujet. Je trouve cela plus clair que tous les routeurs *leaf* soient connectés au *spine* par `eth0` et aux hôtes par `eth1`.

3. Choisissez les adresses IP à utiliser :

   | **Équipement**         | **Interface** | **Adresse IP**   |
   | :--------------------- | :------------ | :--------------- |
   | Routeur-1 (RR / Spine) | `eth0`        | 192.168.1.1/24   |
   | Routeur-1 (RR / Spine) | `eth1`        | 192.168.1.2/24   |
   | Routeur-1 (RR / Spine) | `eth3`        | 192.168.1.3/24   |
   | Routeur-1 (RR / Spine) | `lo`          | 10.1.1.1/32      |
   | Routeur-2 (Leaf-1)     | `eth0`        | 192.168.1.10/24  |
   | Routeur-2 (Leaf-1)     | `lo`          | 10.1.1.2/32      |
   | Routeur-3 (Leaf-2)     | `eth0`        | 192.168.1.20/24  |
   | Routeur-3 (Leaf-2)     | `lo`          | 10.1.1.3/32      |
   | Routeur-4 (Leaf-3)     | `eth0`        | 192.168.1.30/24  |
   | Routeur-4 (Leaf-3)     | `lo`          | 10.1.1.4/32      |
   | Hôte-1                 | `eth1`        | 30.1.1.1/24      |
   | Hôte-2                 | `eth0`        | 30.1.1.2/24      |
   | Hôte-3                 | `eth0`        | 30.1.1.3/24      |

### 3. Configuration

1. Pour chaque routeur, configurez les **interfaces réseau** comme requis dans l'énoncé. Cela signifie qu'il est temps de créer des **interfaces loopback avec une adresse IP routable** ! Pour cette tâche, il est recommandé d'utiliser [vtysh](https://docs.frrouting.org/projects/dev-guide/en/latest/vtysh.html).

   Ouvrir le terminal de configuration `vtysh` :

   ```vtysh
   / # vtysh
   spine_mboivin# configure terminal
   ```

   Désactivez l'IPv6 forwarding qui nous embête :

   ```vtysh
   no ipv6 forwarding
   !
   ```

   **Routeur Spine :**

   ```vtysh
   interface eth0
     ip address 192.168.1.1/24
   !
   interface eth1
     ip address 192.168.1.2/24
   !
   interface eth2
     ip address 192.168.1.3/24
   !
   interface lo
     ip address 10.1.1.1/32
   !
   ```

   On peut voir les interfaces en exécutant :

   ```vtysh
   spine_mboivin# show int br
   Interface       Status  VRF             Addresses
   ---------       ------  ---             ---------
   eth0            up      default         192.168.1.1/24
   eth1            up      default         192.168.1.2/24
   eth2            up      default         192.168.1.3/24
   lo              up      default         10.1.1.1/32
   ```

   **Routeurs Leaf :**

   Configurez les interfaces réseau pour chaque leaf. Voici un exemple pour le premier leaf :

   ```vtysh
   interface eth0
     ip address 192.168.1.10/24
   !
   interface lo
     ip address 10.1.1.2/32
   !
   ```

   Un **bridge** et des **tunnels VXLAN** sont à nouveau nécessaires. Pour les trois leaves, exécutez la commande suivante dans la console auxiliaire (n'oubliez pas de remplacer l'adresse IP locale) :

   ```sh
   /sbin/ip link add name vxlan10 type vxlan id 10 dstport 4789 local <loopback_IP_address>
   /sbin/ip link set dev vxlan10 up

   /sbin/ip link add br10 type bridge
   /sbin/ip link set dev br10 up

   /sbin/ip link set vxlan10 master br10
   /sbin/ip link set eth1 master br10
   ```

2. Pour chaque routeur, configurez le **routeur OSPF**.

   **Routeur Spine :**

   L'adresse IP de l'interface loopback est utilisée comme router ID. La commande `network` est préférée à la configuration OSPF par interface (`ip ospf area <0>` dans `interface`).

   ```vtysh
   router ospf
     ospf router-id 10.1.1.1
     network 10.1.1.1/32 area 0
     network 192.168.1.0/24 area 0
   !
   ```

   **Routeurs Leaf :**

   Spécifiez la zone `0` qui est la backbone et donc obligatoire. Le réseau est petit, nous n'avons pas besoin de plus. Voici un exemple pour le premier leaf :

   ```vtysh
   router ospf
     ospf router-id 10.1.1.2
     network 10.1.1.2/32 area 0
     network 192.168.1.0/24 area 0
   !
   ```

   Vous pouvez vérifier les voisins OSPF avec la commande suivante :

   ```vtysh
   spine_mboivin# show ip ospf neighbor
   ```

   Le spine doit avoir trois voisins.

   Vérifiez les routes :

   ```vtysh
   leaf_mboivin-1# show ip route
   ```

   Chaque routeur devrait pouvoir ping les trois autres. Si nécessaire, utilisez l'option `-I` :

   ```sh
   $ ping <remote_loopback_IP> -I <loopback_IP>
   ```

3. Configurez le **routeur BGP**.

   **Routeur Spine:**

   ```vtysh
   router bgp 1
     neighbor ibgp peer-group
     neighbor ibgp remote-as 1
     neighbor ibgp update-source lo
     bgp listen range 10.1.1.2/31 peer-group ibgp
     bgp listen range 10.1.1.4/32 peer-group ibgp
     !
     address-family l2vpn evpn
       neighbor ibgp activate
       neighbor ibgp route-reflector-client
     exit-address-family
   !
   ```

   - `10.1.1.2/31` couvre `10.1.1.2` et `10.1.1.3`
   - `10.1.1.4/32` couvre uniquement `10.1.1.4`

   C'est très restrictif mais cela couvre uniquement les loopbacks de nos leaves. On aurait pu utiliser un masque plus large comme `/29`.

   **Routeurs Leaf :**

   ```vtysh
   router bgp 1
     neighbor 10.1.1.1 remote-as 1
     neighbor 10.1.1.1 update-source lo
     !
     address-family l2vpn evpn
       neighbor 10.1.1.1 activate
       advertise-all-vni
     exit-address-family
   !
   ```

   Pour vérifier le nombre de voisins :

   ```vtysh
   leaf_mboivin-3# do show bgp summary
   ```

   Pour vérifier les routes :

   ```vtysh
   leaf_mboivin-3# do show bgp l2vpn evpn
   ```

4. Pour écrire les fichiers de configuration :

   ```vtysh
   leaf_spine# write
   Note: this version of vtysh never writes vtysh.conf
   Building Configuration...
   Configuration saved to /etc/frr/zebra.conf
   Configuration saved to /etc/frr/ospfd.conf
   Configuration saved to /etc/frr/bgpd.conf
   Configuration saved to /etc/frr/isisd.conf
   Configuration saved to /etc/frr/staticd.conf
   ```

5. Démarrez un hôte sans configurer d'adresse IP. En exécutant `do show bgp l2vpn evpn` sur chaque routeur, une nouvelle route de type 2 avec l'adresse MAC de l'hôte devrait apparaître.

6. Configurez les adresses IP sur les hôtes et vérifiez s'ils peuvent échanger des ping.

   **Premier hôte :**

   ```sh
   /sbin/ip addr add 30.1.1.1/24 dev eth1
   ```

   **Second hôte :**

   ```sh
   /sbin/ip addr add 30.1.1.2/24 dev eth1
   ```

   **Troisième hôte :**

   ```sh
   /sbin/ip addr add 30.1.1.3/24 dev eth1
   ```

### 4. Sauvegarder le projet

Les modifications ne sont pas persistantes. Créez des scripts Shell pour configurer les routeurs.

Le projet doit être exporté en archive ZIP. Dans la barre de menu, cliquez sur `File` > `Export portable project`. Incluez les images de base comme demandé.

## Soutenance

Le [répertoire `docker`](/docker/) contient un Dockerfile pour le routeur avec des scripts de configuration reprenant les commandes utilisées plus haut.

Depuis la racine du projet :

```sh
$ docker build -t router_mboivin docker
```

## Ressources

- [VXLAN: BGP EVPN with FRR](https://vincent.bernat.ch/en/blog/2017-vxlan-bgp-evpn)
- [🎥 Bgp evpn with Linux and FRR | Hands on experience of networking | EVPN hands on with Linux and FRR](https://www.youtube.com/watch?v=_DO_SEm73pQ)
- [🎥 GNS3: FRRouting Using Docker Platform - EVPN](https://www.youtube.com/watch?v=Ek7kFDwUJBM)
