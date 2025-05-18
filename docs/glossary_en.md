# Glossary

## A

- **AFNIC (*Association française pour le nommage Internet en coopération*)**: Manages France's TLDs (`.fr`, `.re`, `.tf`, `.yt`, `.pm`, `.wf`).
- **ARP (Address Resolution Protocol)**: Protocol that maps IP addresses to MAC addresses. It operates at the interface between layers 2 and 3 of the OSI model.
- **AS (Autonomous System)**: The Internet is a network of networks, and ASes are the largest networks it consists of. An AS has a consistent routing policy. Every computer or device connected to the Internet is linked to an AS. (Source: [CloudFlare](https://www.cloudflare.com/fr-fr/learning/network-layer/what-is-an-autonomous-system/))
- **ASN (Autonomous System Number)**: 16-bit number (32 since 2007 per RFC 4893) used to identify an AS.

## B

- **BGP (Border Gateway Protocol)**: Main protocol supporting the internet, synchronizes routing info between network devices. Uses TCP as transport. It belongs to OSI layer 7 as an application protocol (exchanges structured messages to establish sessions, negotiate routes, share updates). It doesn't handle IP routing or transport itself (TCP does that), and it has its own business logic (policy, route selection, filtering, etc.). In short, BGP is a control protocol that manages routing logic.
- **Broadcast (address)**: This IP address is used to send packets to all devices in a network. It's obtained by setting all bits of the HOST ID to 1. For example, in a `10.0.0.0/24` network, a packet sent to `10.0.0.255` is received by all machines in the network.
- **BUM (Broadcast, Unknown Unicast, Multicast)**: Acronym for three traffic types.
    - **Broadcast**: Traffic sent to all nodes in a network (ARP, DHCP).
    - **Unknown Unicast**: Traffic sent to a specific node whose MAC is not yet in the switch's MAC table.
    - **Multicast**: Traffic sent to a group of nodes.

## C

- **(Network) Convergence**: Process of integrating different communication services, removing the need for separate networks for each service type, reducing costs and operations.

## D

- **DBD (Data Base Description)**: OSPF packet summarizing all the links a router knows. If a router doesn't recognize a neighbor, it sends an LSR.
- **DNS (Domain Name System)**

## E

- **EBGP (Exterior Border Gateway Protocol)**
- **EIGRP (Enhanced Interior Gateway Routing Protocol)**: Cisco proprietary IGP. Hybrid IP routing protocol (features from link-state and distance-vector protocols).
- **EVPN (Ethernet Virtual Private Network)**: Control plane (VXLAN being the [data plane](https://www.cloudflare.com/fr-fr/learning/network-layer/what-is-the-control-plane/)), responsible for propagating IP/MAC mappings and locations, enabling more scalable and agile networks, better segmentation and connectivity via tunnels. Operates at OSI layer 2.

## F

- **FRRouting or FRR (Free Range Routing)**: Routing software suite, Quagga fork, implementing BGP, OSPF, RIP, IS-IS, PIM, LDP, BFD, Babel, PBR, OpenFabric, and VRRP protocols for Unix platforms.
- **Full Mesh**: Network topology where every router is connected to every other router.

## I

- **IANA (Internet Assigned Numbers Authority)**: U.S. nonprofit overseeing global allocation of IP addresses, ASNs, and DNS root zone management.
- **IBGP (Interior Border Gateway Protocol)**
- **ICANN (Internet Corporation for Assigned Names and Numbers)**: U.S. nonprofit regulating the Internet. Coordinates and administers digital resources (IP addressing, TLDs) and technical actors.
- **ICMP (Internet Control Message Protocol)**: Protocol for error reporting since IP can't do it (e.g., `ping`). Located in OSI layer 3.
- **IETF (Internet Engineering Task Force)**: Volunteer body creating and promoting internet standards by drafting specification documents called RFCs.
- **IGP (Interior Gateway Protocol)**: Routing protocol for routers within the same AS to establish iBGP sessions. Examples: RIP, OSPF, IS-IS, EIGRP.
- **IP (Internet Protocol)**
- **IS-IS (Intermediate system to intermediate system)**: Link-state routing protocol for routers within the same AS, used in large networks. Uses NET IDs instead of IP addresses. Operates at OSI layer 2.
- **ISP (Internet Service Provider)**

## L

- **Leaf**: Router at the bottom of a data center architecture, directly connected to hosts, servers, or VMs. Sends traffic to *spine* routers without communicating with other *leafs*.
- **LIR (Local Internet Registry)**: A regional RIR (e.g., an ISP).
- **Loopback**: Virtual interface allowing a device to send data to itself without reaching the physical network. Default loopback IP is `127.0.0.1` (IPv4) or `::1` (IPv6). The reserved domain name `localhost` resolves to loopback IP without external DNS query.
- **Routable loopback**: Not `127.0.0.1`, but a loopback interface with a routable (often private) IP address. Always available if the device is running, making it more reliable than physical interfaces. Routable via IGP (IS-IS, OSPF, RIP, EIGRP) to establish iBGP sessions between routers.
- **LSA (Link-State Advertisement)**: OSPF packet used to advertise info about one or more OSPF router links.
- **LSR (Link-State Request)**: OSPF packet to request info about an unknown neighbor. The reply is an LSA packet.
- **LSU (Link-State Update)**: OSPF packet containing multiple LSAs.

## M

- **MAC (Media Access Control)**
- **MAC - LAA (Locally Administered Addresses)**: Also called local/private MAC address. Allows assigning specific addresses within a network or in simulators like GNS3.
- **MAC - UAA (Universally Administered Addresses)**: Unique MAC address assigned by the device manufacturer.
- **MPLS (Multiprotocol Label Switching)**: Routing technique using labels for optimized packet forwarding.

## O

- **OSI (Open Systems Interconnection)**
- **OSPF (Open Shortest Path First)**: Link-state routing protocol. Located in OSI layer 3.
- **OUI (Organizationally Unique Identifier)**: 24-bit number identifying a manufacturer, e.g., in MAC addresses.

## Q

- **Quagga**: Open-source routing software based on Zebra. Supports standard routing protocols like RIP, OSPF, and BGP.

## R

- **RFC (Request For Comments)**: Documents by IETF describing Internet technical specs.
- **RIP (Routing Information Protocol)**: Distance-vector IP routing protocol.
- **RIR (Regional Internet Registry)**: Organizations allocating IP address blocks. There are 5: **RIPE NCC** (Europe, Middle East, Central Asia), **ARIN** (North America), **LACNIC** (Latin America and Caribbean), **AFRINIC** (Africa), **APNIC** (Asia-Pacific).
- **Route reflector**: BGP router used to reduce iBGP connection count in an AS. It receives iBGP routes and "reflects" them to iBGP clients. Avoids a *full mesh* topology.
- **Router**: Network device that routes packets by determining the best path. Located in OSI layer 3.

## S

- **Source Address Learning**: Mechanism where a switch (physical or virtual) learns MAC addresses by observing Ethernet frame sources. When a packet arrives, the switch reads the MAC source and maps it to the incoming port in its MAC table.
- **Spine**: Router at the top of the *Leaf-Spine* architecture. Connected only to *leaf* routers, ensuring their interconnection.
- **Switch**: Network device connecting other devices using their MAC addresses. Operates at OSI layer 2. Builds and uses a table linking MAC addresses to ports. On receiving a frame, it sends it via the port matching the MAC in the frame.

## T

- **TCP (Transmission Control Protocol)**
- **TLS (Transport Layer Security)**

## U

- **UDP (User Datagram Protocol)**: Transmission protocol that doesn't guarantee delivery, order, or uniqueness. Located in OSI layer 4.

## V

- **VNI (VXLAN Network Identifier)**: 24-bit identifier of the virtual network a packet belongs to, inserted in the VXLAN header.
- **VTEP (VXLAN Tunnel End Point)**: Endpoints of VXLAN tunnels that encapsulate/decapsulate Ethernet frames.
- **vtysh (Virtual TeletYpe SHell)**: CLI shell from FRRouting. Allows unified interaction with FRR daemons like `bgpd`, `ospfd`, `zebra`. It uses UNIX sockets (VTY sockets) to communicate. When a command is entered, it's sent to the relevant daemon via the socket, executed, and the result is returned to `vtysh`.
- **VXLAN (Virtual Extensible LAN)**: Network virtualization tech allowing a physical network to be shared by multiple organizations without traffic visibility between them (Source: [Juniper Networks](https://www.juniper.net/fr/fr/research-topics/what-is-vxlan.html)). It encapsulates layer 2 Ethernet frames in layer 4 UDP datagrams.

## Z

- **Zebra**: Routing manager created in the 90s, discontinued in 2003. Quagga is a fork of it. Note: FRRouting's zebra is not a continuation of this project.
- **zebra**: The FRRouting daemon managing IP routing ([FRR documentation](https://docs.frrouting.org/en/latest/zebra.html)). Not the original Zebra.
