# ICND2
# LAN Switching
# VLAN Trunking Protocol (_VTP_)
If we have a lot of switches in a network, we will have to create identical VLANs on each and every one of them to allow the devices to communicate and the identicality will ensure the ease of management. If this were to be done manually on each and every switch, then there's be a lot of administrative overhead and manual effort. Instead, Cisco has a protocol called the **VLAN Trunking Protocol (_VTP_)** that allows us to create the VLANs on all the switches by creating them just once.

Thus, we can create/modify/delete VLAN on one switch and using VTP these changes will spread all throughout the network. The information about VLANs is actually sent in the form of advertisements between devices. These advertisements only pass through trunks and hence, the name is VLAN _trunking_ protocol.

# VTP Theory
Let us consider that we have the 5 switches interconnected as shown in the diagram with **IEEE 802.1q trunks** (_although VTP would still work with ISL trunks_). Let us consider that all 5 switches reside in the same building. Then, if we create a _VLAN 300_ on switch 3, and VTP is configured, then the VLAN 300 would be advertised to all the neighbours it has discovered. So, switches sw2 and sw4 would see this new VLAN and also copy the VLAN in their own configuration. Finally, they'd pass new advertisements for the VLAN 300 along trunks to switches 1 and 5, which would also do the same till all the switches have the VLAN 300 present on them. Thus, we need only change a single switch and the changes would be propagated throughout the network.

However, we may want to set a select number of switches that should be able to change the configuration while all the rest are able to update their VLAN databases. These switches will only update their own VLAN database when they receive the advertisements and then pass the advertisements out of its other trunk ports. However, we won't be able to create/modify/delete VLANs by connecting to the switch administratively. Thus, the only way to change VLANs on them would be via advertisements. These switches are called **Client** mode switches.

**Server** mode switches, contrastingly can create/modify/delete VLANs in its local database and the changes are propagated throughout the network via trunk links. If it receives VTP advertisements from other servers, it'll just forward it on via the other trunk ports. Finally, there's a third type of switches: **transparent** mode switches. These can create/modify/delete VLANs in their local database, but these changes aren't advertised via trunk links and thus stay local only to that switch. Further, they don't update their VTP database in response to VTP advertisements. However, they still do send out the advertisements out their other ports just like a server mode or client mode switch would do, so that the advertisements can be received by its neighbours. Thus, the switch is merely _transparent_ to VTP, and changes to its VLANs can only be made to its local database.

## Server Mode VTP switch
* Can modify the global/network's VLAN database.
* Updates its own VLAN database based on received advertisements.
* Forwards VTP advertisements
* Can be the origin for new VTP advertisements

When we make a change on a VTP server mode switch, the changes are advertised out to other switches. These then take a look at the contents of the advertisement and their own VTP database to determine which is the latest version. Every time we make a change on a VLAN on a server mode switch, it gets stored in its VLAN database along with a value called the **Configuration Revision Number (_CRN_)**. The CRN increases everytime a change is made to the database and this number acts as the version number marker for the VLAN database, and is sent out via trunk ports with advertisements. The other switches use it to judge which is the latest copy of the VLAN database and then the version with the higher CRN is stored and believed and the other is discarded.

## Client Mode VTP switch
* Cannot modify the global/network's VLAN database.
* Updates its own VLAN database based on received advertisements.
* Forwards VTP advertisements
* Can be the origin for new VTP advertisements

A client mode switch can originate new VTP advertisements. By its nature, client mode switches aren't allowed to make changes to their existing VLAN database unless the changes are advertised via VTP by another switch. However, let us consider a scenario where a switch previously being used as a server mode switch is repurposed as a client mode switch in our network. If the CRN for the old VLAN database config on the foreign switch is greater than the CRN of the VLAN DB on our network, it'll overwrite our configuration with the *wrong* config from the old network. Thus, a client mode switch *can* originate new VTP advertisements.

## Transparent Mode VTP switch
* Cannot modify the global/network's VLAN database.
* Ignores VTP advertisements and doesn't update VTP database on basis of ads.
* Forwards VTP advertisements to neighbours via trunks
* Cannot be the origin for new VTP advertisements

A VTP Transparent switch simply doesn't participate in VTP at all, but still forwards the VTP advertisements that it receives on one trunk port out all the other trunk ports.

## VTP Off Mode
Some Cisco switches also feature a special _VTP Off_ mode where the switch acts exactly like a VTP transparent mode switch, but also doesn't forward the advertisements it receives.

## VTP Change Propagation
Let us consider that the 5 switches are arranged in the topology shown, and they're all running at a CRN of 10. Now, if we were to add a VLAN 300 on sw3, the CRN will be changed to 11 in its database and the new VLAN DB will be advertised throughout the network, to both sw2 and sw4 via the trunks. Switch sw2 is also a server mode switch, so when it receives the advertisement, it'll compare the CRN of the new DB (=11) with the CRN of its present DB (=10) and update it's database. Then it'll advertise out the new DB to sw1, which being a transparent mode switch will ignore it. On the other side, the switch sw4, being a transparent mode switch will leave it's own VLAN DB alone and unchanged and forward it to sw5 via the trunk. Client mode switch sw5 will see that the CRN of the new DB is higher and thus update it's database to CRN 11's data. At this point, all the switches in this switched topology have a VLAN DB with a CRN of 11 and we say that _synchronization is complete_ and this steady state will be maintained till another change occurs in the topology.

Whenever a change is made in the VTP DB, advertisements are sent out or _triggered_ immediately. There is no timer for which it has to wait. However, by default, VTP advertisements are also sent out every 5 minutes, but the information contained in this is not the entire VTP DB info, but a much lightweight version containing info like VTP domain name and the current CRN.

## VTP Requirements
* In order for switches to share information via VTP, they need have the **same VTP domain name**, which is a _case-sensitive_ name.
* The switches must be connected via **trunk links**.
* Passwords, although optional, can be shared between switches in the _VTP domain_ to ensure that no one intentionally/accidentally introduces a switch with a higher CRN and erases the current VLAN DB on the network.

## VTP Versions
### VTPv1
In version 1, VTP transparent switches used to take a peek at the data in the VTP advertisements and ensure that the version and the VTP domain name matched before forwarding the advertisements. This was not deemed as the ideal behaviour for a transparent switch.

### VTPv2
In this version, the version and domain name checks were removed and the transparent switches forward all VTP advertisements on all other trunk ports. It also added support for token ring VLANs and token ring based LAN switching. Also, if the VTP domain name is unconfigured when a VTP advertisement is received on one of the trunk ports, the VTPv2 switch would automatically join the VTP domain by setting its domain name and updating its local copy of the VTP DB with the one received in the advertisement. This was somewhat of a security issue.

### VTPv3
VTPv3 extended the VLAN number allowed to be advertised over VTP, specifically between _1017 - 4094_. In VTPv3, each switch must be manually configured to join the VTP domain. It also does a better job at securing the VTP domain password for the switches. Unlike the previous versions, even though there can be multiple VTP servers, there can be **only one primary VTP server** in a VTP domain and only that server has the authorization to perform updates on other devices. VTPv3 also supports **MST (_Multiple Spanning Tree_) [802.1s]**. It allows us to maintain different instances of spanning trees and allows us to assign VLANs to distribute the VLANs among the different instances of spanning trees.

If VTP pruning is enabled for a trunk, then VTP can dynamically prune off unneeded VLANs - for example, where a switch doesn't have any devices connected to a particular VLAN, it doesn't need the advertisements for it, and the unneeded VLAN need not be maintained on it.

# VTP configuration
In the topology below, let us consider that we want sw1 and sw2 to be in server mode while sw3 is in client mode. We put them in the correct mode using the `vtp mode` command:

```
sw1(config)#vtp mode server
Device mode already VTP Server for VLANS.

sw2(config)#vtp mode server
Device mode already VTP Server for VLANS.

sw3(config)#vtp mode client
Setting device to VTP Client mode for VLANS.
```

We can now set the VTP domain name on sw1:

```
sw1(config)#vtp domain VTPDEMO
Changing VTP domain name from NULL to VTPDEMO
*Dec 16 11:51:28.876: %SW_VLAN-6-VTP_DOMAIN_NAME_CHG: VTP domain name changed to VTPDEMO.
```

Now we can also set the VTP domain password, turn on VTP pruning and hardcode the version:

```
sw1(config)#vtp password S3cret
Setting device VTP password to S3cret
sw1(config)#vtp pruning
Pruning switched on
sw1(config)#vtp version 2
```

To see the status of VTP, we use:

```
sw1#sh vtp status
VTP Version capable             : 1 to 3
VTP version running             : 2
VTP Domain Name                 : VTPDEMO
VTP Pruning Mode                : Enabled
VTP Traps Generation            : Disabled
Device ID                       : 0c79.bbbb.8000
Configuration last modified by 0.0.0.0 at 12-16-18 11:58:11
Local updater ID is 0.0.0.0 (no valid interface found)

Feature VLAN:
--------------
VTP Operating Mode                : Server
Maximum VLANs supported locally   : 1005
Number of existing VLANs          : 5
Configuration Revision            : 2
MD5 digest                        : 0xCF 0x9A 0x90 0x1B 0xD2 0x0F 0xBE 0x80
                                    0xE0 0x70 0xA8 0x03 0x4C 0x9C 0x24 0x3E
```

We now have to create an identical VTP configuration on every VTP server switch. Finally, we set the VTP client switches with the same VTP domain name and password. Now, if we try to create a new VLAN on a client mode switch, we get:

```
sw3(config)#vlan 500
VTP VLAN configuration not allowed when device is in CLIENT mode.
```

Now, let's create a new VLAN 999 on a VTP server, sw1:
```
sw1(config)#vlan 999
sw1(config-vlan)#name VLAN_NULL
```

Now, when we check, the VLAN will be created on all 3 switches:

```
sw1#sh vlan br

VLAN Name                             Status    Ports
---- -------------------------------- --------- -------------------------------
1    default                          active    Gi0/2, Gi0/3
999  VLAN_NULL                        active    
1002 fddi-default                     act/unsup
1003 trcrf-default                    act/unsup
1004 fddinet-default                  act/unsup
1005 trbrf-default                    act/unsup

sw2#sh vlan br | i NULL
999  VLAN_NULL                        active    

sw3#sh vlan br | i NULL
999  VLAN_NULL                        active    
```

We'll now be able to see that the current configuration revision number has increased.
```
sw1#sh vtp status
VTP Version capable             : 1 to 3
VTP version running             : 2
VTP Domain Name                 : VTPDEMO
VTP Pruning Mode                : Enabled
VTP Traps Generation            : Disabled
Device ID                       : 0c79.bbbb.8000
Configuration last modified by 0.0.0.0 at 12-16-18 12:13:46
Local updater ID is 0.0.0.0 (no valid interface found)

Feature VLAN:
--------------
VTP Operating Mode                : Server
Maximum VLANs supported locally   : 1005
Number of existing VLANs          : 6
Configuration Revision            : 3
MD5 digest                        : 0x12 0x62 0x13 0x7C 0x4D 0x3B 0x2E 0xB0
                                    0x98 0xC9 0x99 0xD1 0xA3 0x10 0xC9 0xE7
```

## Resetting the VTP CRN to 0
Let us assume that for some reason, sw2 gets disconnected. Now, we log on to it, and perform a bunch of changes to the VLANs. Now, it'll have a substantially higher CRN than sw1 and sw3. If we were to connect the switch directly back to the network, since the VTP domain name and VTP password is the same, it'll override the present VTP database as the CRN is higher! To prevent this from happening we have to reset the CRN. We do this by setting the VTP mode to _transparent_ first and then switching back to server.

```
sw1(config)#do sh vtp status
VTP Version capable             : 1 to 3
VTP version running             : 2
VTP Domain Name                 : VTPDEMO
VTP Pruning Mode                : Enabled
VTP Traps Generation            : Disabled
Device ID                       : 0c79.bbbb.8000
Configuration last modified by 0.0.0.0 at 12-16-18 12:26:57
Local updater ID is 0.0.0.0 (no valid interface found)

Feature VLAN:
--------------
VTP Operating Mode                : Server
Maximum VLANs supported locally   : 1005
Number of existing VLANs          : 7
Configuration Revision            : 4
MD5 digest                        : 0xC8 0xCF 0x24 0x62 0x9D 0xAB 0xBC 0xA4
                                    0x69 0xCD 0x64 0xD6 0xA8 0x23 0x26 0xDB
sw1(config)#vtp mode transparent
Setting device to VTP Transparent mode for VLANS.
sw1(config)#vtp mode server
Setting device to VTP Server mode for VLANS.
sw1(config)#do sh vtp status
VTP Version capable             : 1 to 3
VTP version running             : 2
VTP Domain Name                 : VTPDEMO
VTP Pruning Mode                : Enabled
VTP Traps Generation            : Disabled
Device ID                       : 0c79.bbbb.8000
Configuration last modified by 0.0.0.0 at 12-16-18 12:26:57
Local updater ID is 0.0.0.0 (no valid interface found)

Feature VLAN:
--------------
VTP Operating Mode                : Server
Maximum VLANs supported locally   : 1005
Number of existing VLANs          : 7
Configuration Revision            : 0
MD5 digest                        : 0xC8 0xCF 0x24 0x62 0x9D 0xAB 0xBC 0xA4
                                    0x69 0xCD 0x64 0xD6 0xA8 0x23 0x26 0xDB
```
Some people like to be extra-certain that their production VLAN database won't be corrupted/wiped and hence like to delete their `vlan.dat` file from the flash, although this isn't necessary since the CRN is set to 0 on sw2. Now when we connect the switch back to the network, the CRN=2 version of the file that sw1 and sw3 follow will be re-written on the switch.

# Spanning Tree Protocol
We like to have redundancy in our networks and it's good to have multiple links between devices. However, in a switched network, this may become dangerous. This possibility is mitigated using the **Spanning Tree Protocol (_STP_)**.

Earlier there used to be Ethernet Bridges, devices like switches that made layer-2 forwarding decisions in software rather than hardware like switches. They didn't have **ASICs (_Application Specific Integrated Circuits_)**, dedicated circuits for packet switching based on MAC address that switches have and thus were slower than switches. However, their functionality is the same as switches - where incoming frames are analysed to get their destination MAC address and switched accordingly.

If we consider bridges/switches in the following topology, we see that all 3 bridges are interconnected with every other bridge and thus have redundancy such that even if any 1 of the 3 links failed, they'd still all have connectivity. However, this is called a **layer 2 topological loop**. These loops can cause some issues if Spanning Tree Protocol isn't running in the network.

## Layer 3 loop vs Layer 2 loop
A point should be noted that while layer 3 loops are fine, layer 2 loops can be disastrous. This is because packets that are routed at layer 3 have TTL (Time to Live) values that decrease by 1 every time a packet crosses a router. So even if a packet keeps going in a loop as shown in the digram below, eventually the TTL would reach 0 and the next router it encounters will drop the packet. This, however, isn't possible with layer 2 because the frames don't have a TTL value. Hence, it's possible for a packet to endlessly and uselessly keep going in a loop.

## Broadcast Storm
A scenario where this occurs is called a **broadcast storm** where a broadcast packet, destined for `FFFF.FFFF.FFFF` keeps going endlessly in a loop because there's no way to time it out. Devices in a network that's going through a broadcast storm can slow down terribly because their Network Interface Cards (NICs) have to take time to look at and discard the broadcast packets regenerated by the switches/bridges. The devices on the network would each have to dedicate significant resources to analyzing and discarding these useless, circulating packets.

## MAC address table corruption
In the topology below, if PC _A_ sends out a frame for PC B on the common network segment, they'll reach the interfaces of both Switch A and Switch B. Both will note that the MAC address `AAAA.AAAA.AAAA` is connected to their _Gi1/0/1_ interface. The problem occurs when both switches send out the packet on the shared common network segment leading to PC _B_. Each switch will see the incoming packet from the other switch and think there's a device on the bottom common segment that has the `AAAA.AAAA.AAAA` MAC address. They'll think PC A has been re-arranged in the network, deleted their original (correct) entry mapping PC A to their Gi1/0/1 ports and instead map the MAC address to Gi1/0/2 incorrectly. The two MAC address tables for both the routers are now corrupted since they contain incorrect data. This is why we need STP to protect us from situations like these.

A possible solution to to above problems is to physically break the loop by removing one of the redundant links. However, another alternative is to logically break the loop by using STP.

# STP Port States
A Spanning Tree is a **logical loop free topology**. This is done by making one of the ports on the switches block traffic from flowing in/out, thus preventing loop creation, even though a physical loop exists. Thus we get the redundancy without having loops. A spanning tree has a root bridge/switch from which it originates and from it, the spanning tree radiates throughout the subnet. We have administrative control over which switch becomes the root switch. When multiple switches are connected in a loop, if STP is active, it automatically elects a root switch, but it might not be the optimal switch (depending on the traffic patterns in the network). For example, we may have a link between two GigabitEthernet ports and another through FastEthernet interfaces, and STP may elect the device with the FastEthernet ports as the root bridge while the GigabitEthernet ports lay dormant.

## Root Bridge
In any Spanning Tree topology, there can be only **one root bridge** (or switch) and the bridge with the lowest **Bridge ID (_BID_)** is elected to be the root bridge. The Bridge ID is a combination of a bridge priority, a value we can set and the MAC address. The bridge priority is a value between 0 and 61440, with a default bridge priority of 32768. If we lower the bridge priority, we influence that particular switch to become the root. If we don't change the bridge priority, however, the bridge with the lowest MAC address gets to be the root. In the topology below, switch B gets to be the root bridge since `000 < 001` (first 3 digits of each MAC address). To determine which ports will be blocking and which ports will be forwarding, we need to understand the different port states for a spanning tree.

**Root Port** - A root port is a port on a _non-root bridge_ that's closest to the root bridge with resect to cost. In the topology, switch A will have the root port since the bridge it self isn't the root bridge. Both ports are FastEthernet ports, but Fa 1/0/1 has been configured to run at 100 Mbps while the port Fa 1/0/2 has been configured to run at 10 Mbps. If we consult the table below, we'll see that the cost associated to a port speed of 10 Mbps is `100` while that associated with 100 Mbps is `19`. Thus, it costs less for the traffic to be flowing out of Fa 1/0/1 in this case, and it's marked as the root port.

**Designated Port** - There's a designated port on every network segment. It is the port on the network segment that is closest to the root bridge in terms of the cost. Thus, both **sw1 Gi0/0** and **sw2 Gi0/1** are designated ports.

**Non-Designated Port** - Such a port is also called a **blocking port**.
**Disabled Port** - A port that is administratively shut down.

Any remaining port that's not a root port/designated port/Disabled port become blocking ports. Thus **Fa 1/0/2** is a non-designated port. Now, we have a loop-free topology. Thus, we're not going to have a layer 2 topological loop since no data will flow in/out of **sw1 Fa1/0/2**. 
