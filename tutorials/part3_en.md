# Part 3

This part is about discovering BGP EVPN's application to VXLAN. Our case is a small data center.

**VXLAN** is the [data plane](https://www.cloudflare.com/learning/network-layer/what-is-the-control-plane/) or also forwarding plane.

**BGP EVPN** is the [control plane](https://www.ibm.com/think/topics/control-plane) that defines and controls how data is forwarded in the network.

If we wanted all routes to be known by every router in our data center, we would need to set up a full mesh. However, this solution is not scalable. A more flexible approach is to configure a **route reflector** responsible for distributing the learned routes to its iBGP peers.

> 💡 We are not interested in eBGP, but only in iBGP, which is used within an AS to connect internal routers. However, we could use eBGP by simulating two ASes using private AS numbers (range 64512–65534) without making any announcements to the Internet.

## Table of Content

- [Conventions and Best Practices](#-conventions-and-best-practices)
- [Requirements](#requirements)
- [Walkthrough](#walkthrough)
    1. [Set up GNS3](#1-set-up-gns3)
    2. [Create the network](#2-create-the-network)
    3. [Configuration](#3-configuration)
    4. [Save the project](#4-save-the-project)
- [Defense](#defense)
- [Resources](#resources)

## 💡 Conventions and Best Practices

### More about loopback interfaces

Creating a **loopback interface with a routable IP for a VTEP** is considered a good practice:

- Loopback interfaces **are always up** as long as the device is running, unlike physical interfaces that may go down. This means they are not tied to a specific physical port, so they remain reachable regardless of link/interface state changes.
- It ensures a stable VTEP identifier for protocols such as BGP (they use the source IP as identifier).
- Same for the OSPF router ID which is the loopback IP address too.

Why `/32` for loopbacks? Because:

- The loopback only communicates with itself—no need for neighbors in the same subnet.
- Protocols like OSPF, BGP, and IS-IS prefer routing to a unique IP.

Always plan a dedicated subnet from a private range for loopback addresses. These are used as Router IDs (RID) by OSPF, reducing the risk of duplication.

## Requirements

The project run inside a Linux virtual machine that must have installed:

- GNS3
- Docker

Follow this guide: [GNS3 Linux Install](https://docs.gns3.com/docs/getting-started/installation/linux/).

## Walkthrough

### 1. Set up GNS3

1. Start GNS3.

2. Create a new project named `P3` as required by the assignment.

### 2. Create the network

1. From the device list, drag and drop the four routers and the three hosts to match the assignment schema.

   The first router will be used as **Route Reflector**. There is usually one BGP router acting as the Route Reflector in data centers, placed at the top of the hierarchy. It will be connected to every other routers but no host. This router is the *spine*. The three others, connected to hosts but not with other routers except for the *spine*, are the *leaves*.

   **Why a Route Reflector?** Without it, a **full mesh** topology would be necessary. In this kind of network, every device is directly connected to every other one. This is not scalable if the number of routers grow. The Route Reflector allows sharing iBGP routes between iBGP peers. It receives routes from clients and reflects them to every other clients.

2. Link the devices.

   <img src="/tutorials/assets/p3/gns3_topology.png" alt="Topology" height="400"/>

   As you can see, I changed the way network interfaces are connected to each other. I find it more simple. Leaves are linked to the spine with `eth0` and to the hosts with `eth1`.

3. Choose the IP addresses to use:

   | **Device**            | **Interface** | **IP address**  |
   | :-------------------- | :------------ | :-------------- |
   | Router-1 (RR / Spine) | `eth0`        | 192.168.1.1/24  |
   | Router-1 (RR / Spine) | `eth1`        | 192.168.1.2/24  |
   | Router-1 (RR / Spine) | `eth3`        | 192.168.1.3/24  |
   | Router-1 (RR / Spine) | `lo`          | 10.1.1.1/32     |
   | Router-2 (Leaf-1)     | `eth0`        | 192.168.1.10/24 |
   | Router-2 (Leaf-1)     | `lo`          | 10.1.1.2/32     |
   | Router-3 (Leaf-2)     | `eth0`        | 192.168.1.20/24 |
   | Router-3 (Leaf-2)     | `lo`          | 10.1.1.3/32     |
   | Router-4 (Leaf-3)     | `eth0`        | 192.168.1.30/24 |
   | Router-4 (Leaf-3)     | `lo`          | 10.1.1.4/32     |
   | Host-1                | `eth1`        | 30.1.1.1/24     |
   | Host-2                | `eth0`        | 30.1.1.2/24     |
   | Host-3                | `eth0`        | 30.1.1.3/24     |

### 3. Configuration

1. For each router, configure the **network interfaces** as required by the assignment. That means this is time to create **loopback interfaces with a routable IP address**! For this task, using [vtysh](https://docs.frrouting.org/projects/dev-guide/en/latest/vtysh.html) is recommended.

   Open `vtysh` configuration terminal:

   ```vtysh
   / # vtysh
   spine_mboivin# configure terminal
   ```

   Disable IPv6 forwarding. We don't need it.

   ```vtysh
   no ipv6 forwarding
   !
   ```

   **Spine router:**

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

   We can see the inferfaces by running:

   ```vtysh
   spine_mboivin# show int br
   Interface       Status  VRF             Addresses
   ---------       ------  ---             ---------
   eth0            up      default         192.168.1.1/24
   eth1            up      default         192.168.1.2/24
   eth2            up      default         192.168.1.3/24
   lo              up      default         10.1.1.1/32
   ```

   **Leaf routers:**

   Configure the network interfaces for each leaf. Below is an example for the first leaf:

   ```vtysh
   interface eth0
     ip address 192.168.1.10/24
   !
   interface lo
     ip address 10.1.1.2/32
   !
   ```

   A **bridge** and **VXLAN tunnels** are required again. For the three leaves, run the following in the auxiliary console (don't forget to replace the local IP address):

   ```sh
   /sbin/ip link add name vxlan10 type vxlan id 10 dstport 4789 local <loopback_IP_address>
   /sbin/ip link set dev vxlan10 up

   /sbin/ip link add br10 type bridge
   /sbin/ip link set dev br10 up

   /sbin/ip link set vxlan10 master br10
   /sbin/ip link set eth1 master br10
   ```

2. For each router, configure the **OSPF router**.

   **Spine router:**

   The IP address of the loopback interface is used as router ID. The `network` command is preferred over configuring OSPF by interface (`ip ospf area <0>` in `interface`).

   ```vtysh
   router ospf
     ospf router-id 10.1.1.1
     network 10.1.1.1/32 area 0
     network 192.168.1.0/24 area 0
   !
   ```

   **Leaf routers:**

   Specify the area `0` which is the backbone and is then mandatory. The network is small, we don't need more. Below is an example for the first leaf:

   ```vtysh
   router ospf
     ospf router-id 10.1.1.2
     network 10.1.1.2/32 area 0
     network 192.168.1.0/24 area 0
   !
   ```

   You can check the OSPF neighbors with the following command:

   ```vtysh
   spine_mboivin# show ip ospf neighbor
   ```

   The spine should have three neighbors.

   Check the routes:

   ```vtysh
   leaf_mboivin-1# show ip route
   ```

   Each router should be able to ping the three others. If necessary, use the `-I` option:

   ```sh
   $ ping <remote_loopback_IP> -I <loopback_IP>
   ```

3. Configure the **BGP router**.

   **Spine router:**

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

   - `10.1.1.2/31` covers `10.1.1.2` and `10.1.1.3`
   - `10.1.1.4/32` covers only `10.1.1.4`

   This is very restrictive but this covers only our leaves's loopbacks. We could have used a larger mask such as `/29`.

   **Leaf routers:**

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

   To check the neighbors number:

   ```vtysh
   leaf_mboivin-3# do show bgp summary
   ```

   To check the routes:

   ```vtysh
   leaf_mboivin-3# do show bgp l2vpn evpn
   ```

4. Write configuration files:

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

5. Start one host without configuring an IP address. Running `do show bgp l2vpn evpn` on every router should show a new route of type 2 with the host's MAC address.

6. Configure IP addresses on hosts and check if they can ping each other.

   **First host:**

   ```sh
   /sbin/ip addr add 30.1.1.1/24 dev eth1
   ```

   **Second host:**

   ```sh
   /sbin/ip addr add 30.1.1.2/24 dev eth1
   ```

   **Third host:**

   ```sh
   /sbin/ip addr add 30.1.1.3/24 dev eth1
   ```

### 4. Save the project

Since the changes won't persist after the devices stop, create Shell scripts for configuring routers.

The project must be saved as a ZIP archive. In the menu bar, click `File` > `Export portable project`. Don't forget to include the base images to match the requirements.

## Defense

The [`docker` directory](/docker/) contains a Dockerfile for the routers with configuration scripts to run the commands seen in the walkthrough.

If you didn't already build the router's Docker image, assuming you are at the directory's root:

```sh
$ docker build -t router_mboivin docker
```

## Resources

- [VXLAN: BGP EVPN with FRR](https://vincent.bernat.ch/en/blog/2017-vxlan-bgp-evpn)
- [🎥 Bgp evpn with Linux and FRR | Hands on experience of networking | EVPN hands on with Linux and FRR](https://www.youtube.com/watch?v=_DO_SEm73pQ)
- [🎥 GNS3: FRRouting Using Docker Platform - EVPN](https://www.youtube.com/watch?v=Ek7kFDwUJBM)
