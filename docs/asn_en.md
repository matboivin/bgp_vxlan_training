# Autonomous Systems

## What is an Autonomous System (AS)?

An AS is a group of IP networks managed by one or more entities (such as an ISP or a large company) with a common routing policy, uniquely identified by a number called an **ASN** (*Autonomous System Number*).

## Who creates autonomous systems?

ASes are created by organizations that want to manage their own inter-domain routing, usually because they want independent Internet presence (e.g., multi-homing or IP transit with multiple ISPs).

- Internet Service Providers (ISPs). *Examples: Orange, Free, Deutsche Telekom (T-Systems).*
- Large companies with complex networking needs. *Examples: Microsoft, Amazon, Google, OVHcloud.*
- Universities, public organizations. *Examples: RENATER (French academic network), MIT (Massachusetts Institute of Technology), University of Cambridge.*
- Content providers. *Examples: Netflix, Cloudflare.*

In 2019, 91,000 ASNs had been allocated (not all in use), and of those, 64,000 were active.

## How to obtain an ASN?

ASNs are allocated by **RIRs** (Regional Internet Registries). There are five RIRs worldwide:

| Region                              | RIR                                 |
| :---------------------------------- | :---------------------------------- |
| Europe, Middle East, Central Asia   | [RIPE NCC](https://www.ripe.net/)   |
| North America                       | [ARIN](https://www.arin.net/)       |
| Latin America and the Caribbean     | [LACNIC](https://www.lacnic.net/)   |
| Africa                              | [AFRINIC](https://www.afrinic.net/) |
| Asia-Pacific                        | [APNIC](https://www.apnic.net/)     |

To obtain an ASN, you typically need to:

- Be a member of an RIR (or go through a Local Internet Registry like an ISP).
- Justify a legitimate need (e.g., having at least two IP transit providers).
- Submit an official request to the appropriate RIR.
- Pay allocation and membership fees.

## Who regulates them?

- ASNs and IP ranges are globally managed by **IANA** (*Internet Assigned Numbers Authority*), which delegates to RIRs.
- Each RIR has its own policies, decided in a bottom-up community-driven process, usually transparent and publicly available.

## Who can apply?

Any legitimate organization with a clear technical need can apply, under certain conditions:

- Possess IP blocks (often also allocated by the RIR)
- Justify the need (multi-homing, interconnection routing, etc.)
- Have the technical and human resources to maintain the AS (network engineers, BGP infrastructure, etc.)

## Exploring BGP connections

To examine the BGP connections of a specific AS, you can use tools such as:

- [RIPEstat ASN Neighbours](https://stat.ripe.net/widget/asn-neighbours): Provides info on an ASN's BGP neighbors, including direct links and routing paths.​
- [PeeringDB](https://www.peeringdb.com/): A collaborative database offering details on peering points, policies, and network contact info.​
- [IPinfo.io](https://ipinfo.io/): Provides ASN info including peers, advertised prefixes, and network connections.
