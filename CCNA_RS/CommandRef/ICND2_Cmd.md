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

The cost for some of the most common interfaces are:
```
Port Speed                  STP Port Cost
=========================   =============
Ethernet        [ 10Mbps]   100
FastEthernet    [100Mbps]   19
GigabitEthernet [  1Gbps]   4
TenGigE         [ 10Gbps]   2
```

## Root Bridge
In any Spanning Tree topology, there can be only **one root bridge** (or switch) and the bridge with the lowest **Bridge ID (_BID_)** is elected to be the root bridge. The Bridge ID is a combination of a bridge priority, a value we can set and the MAC address. The bridge priority is a value between 0 and 61440, with a default bridge priority of 32768. If we lower the bridge priority, we influence that particular switch to become the root. If we don't change the bridge priority, however, the bridge with the lowest MAC address gets to be the root. In the topology below, switch B gets to be the root bridge since `000 < 001` (first 3 digits of each MAC address). To determine which ports will be blocking and which ports will be forwarding, we need to understand the different port states for a spanning tree.

**Root Port** - A root port is a port on a _non-root bridge_ that's closest to the root bridge with resect to cost. In the topology, switch A will have the root port since the bridge it self isn't the root bridge. Both ports are FastEthernet ports, but Fa 1/0/1 has been configured to run at 100 Mbps while the port Fa 1/0/2 has been configured to run at 10 Mbps. If we consult the table below, we'll see that the cost associated to a port speed of 10 Mbps is `100` while that associated with 100 Mbps is `19`. Thus, it costs less for the traffic to be flowing out of Fa 1/0/1 in this case, and it's marked as the root port. Every non-root bridge has its own root port. Since you can't get closer to the bridge than being on the bridge, every port on the bridge is a designated port.

**Designated Port** - There's a designated port on every network segment. It is the port on the network segment that is closest to the root bridge in terms of the cost. Thus, both **sw1 Gi0/0** and **sw2 Gi0/1** are designated ports. Designated ports forward BPDUs originating from the root bridge towards the rest of the LAN segment, to which it's the only connecting node.

**Non-Designated Port** - Such a port is also called a **blocking port**. Any remaining port that's not a root port/designated port/Disabled port become blocking ports. Thus **Fa 1/0/2** is a non-designated port. Now, we have a loop-free topology. Thus, we're not going to have a layer 2 topological loop since no data will flow in/out of **sw1 Fa1/0/2**.

**Disabled Port** - A port that is administratively shut down. STP won't bring it back up.

## Port priority
Each port has a priority assigned to it, a default value of **128** and a value that's generally equal to 2+interface number, that together form the **port ID**. In case of clashes for the root port, the one with the lower port ID wins. Thus, if **Gi0/0** will have a port priority of 128, and it's port ID will be 128.(0+2) = 128.2. Thus, if we want to prefer one port over another, we need only assign it a lower value for the port priority for it to be given preference.

Consider the topology below, where two switches are connected by two different links. If two links/network segment have the exact same cost, we have to look at their **port identifier on the sender's side** (i.e., _the end closer to the root bridge_) to determine which one is going to be connected to a root port.

In the topology below, Switch A is the root bridge, and thus, one of the two ports on Switch B has to be the root port for Switch B. So, there's a tie between the two links connecting to switch B since both links are GigabitEthernet links, and each have a cost of _4_. So, we have to view the interface on the sender's side, i.e., Switch A. The top link has a interface ID of **Gi1/0/3** and the other one **Gi1/0/4**. So, now we have to look at port IDs to break the tie. Given both ports have default priorities of _128_, Gi1/0/3 has a port priority of 128.(3+2) = 128.5 and Gi1/0/4 has a port ID of 128.(4+2) = 128.6. Hence, **Gi1/0/3** gets to be the root port.

Since both ports on root bridge A are designated ports, the only port left is the blocking port.

# STP Practice Exercise
Consider the topology below. Switches A and B have the lowest bridge priority and thus one of them get to be the root bridge. The MAC address of switch A is lower (`000d < 0018`) and so, it's the root bridge. Now, we calculate the root ports.
* For switch B, it's **Sw-B Te1/0/1** since it only has a cost of 2 due to the 10Gig interface.
* For switch D, it's **Sw-D Gi1/0/1** since Gi1/0/2 has a total cost of 4+2 = 6.
* Switch C has two options: **Sw-C Gi1/0/10** or **Sw-C Gi1/0/11**. So, we look at the far end since they're closer to the Bridge Switch. The two ports are **Sw-A Gi1/0/3** and **Sw-A Gi1/0/4**, with port IDs _128.(3+2)=128.5_ and _128.(4+2)=128.6_. Thus the lower port ID wins and **Sw-C Gi1/0/10** is the root port for Switch C.

Now we calculate the Designated ports:
* All ports on Switch A are designated ports since it's the root bridge. Now we only have two more network segments left to consider.
* For the link between Switch B and C, Switch B's port has a cost of 2 to reach bridge and Switch C's port has a cost of 4 to reach the bridge. Hence, **Sw-B Gi1/0/7** is the designated port.
* For the link between switch B and D, **Sw-B Gi1/0/5** is the designated port since it's closer to the bridge.
* _All remaining ports are non-designated/blocking ports_.

# STP Convergence Time
Convergence in routing is achieved in a network when all the routers in the network reach a _steady-state_ by having the same topological information. Thus, they have to gather information from their neighbours about the metrics to reach other routers and _agree on what the network really looks like_. So, when a link or router goes down, or any other change occurs on the network (such as a new link is added), convergence is lost and the time taken by the network to recover from the link failure, i.e., by spreading the information about the lost link throughout the network is the convergence time.

Similarly, in case of switches using STP, when a link connecting a designated/root port goes down, the time taken by the network to transition a blocking port into a designated port so that the network can reach steady-state (i.e., activate the _previously redundant_ link through the blocking port) is called the convergence time. STP convergence is only complete once the following have been completed:
* Root Bridge has been elected
* Root Ports have been elected
* Designated ports have been elected.

In case of traditional STP, the convergence time is 50 seconds. After the link failure, the switch has to wait to receive a **Bridge Protocol Data Unit (_BPDU_)**. A BPDU is a special type of packet exchanged in a STP topology that is used to determine which switch is the root bridge. In STP, only the root bridge can send out BPDUs and it acts like _hello_ messages to keep checking if the link to a switch is still up. When there's a change in the topology, e.g., a link failing, a **Topology Change Notification (_TCN_)** is sent from the switch with the failing port to the root bridge. The root bridge then does two things:
- Send a **Topology Change Acknowledgement (_TCA_)** back to the bridge that sent the TCN.
- Changes it's BPDUs by setting the Topology Change flag inside the BPDU to 1, and thus alerts all the other switches that a topology change has occurred.

In the topology below, once the top link is lost, Switch A has to wait for about 20 seconds (called the _max-age timer_) for a BPDU coming from the root Bridge, Switch B on port **Sw-A Fa1/0/1**, to tell it if the link connecting it to the root bridge is still active. At the end of the timer, when a BPDU does not arrive at Fa1/0/1, switch A realizes something is wrong and starts transitioning the blocking port **Sw-A Fa1/0/2** to a forwarding port.
* The first state in the transition is a **listening**, which last for 15 seconds (called the _forward delay timer_), with the intent of going back to a blocking state if a BPDU is found. During this, even though **Sw-A Fa1/0/2** won't forward packets, it listens to see if a BPDU is received on this port.
* The next state of transition is the **learning** state, which lasts for another 15 sec (_forward delay timer_ again), during which the bridge starts to populate the MAC address table for **Sw-A Fa1/0/2** with the MAC addresses seen on the interface.
* Finally, the switch transitions the port to a forwarding state and starts sending/receiving traffic.

If a new device is plugged into an empty port on the switch, however, and something like PortFast isn't enabled, it's not going to take 50 seconds to converge. Instead, since the port was never blocked, it can directly go the *listening* state and so on, thus bringing down the time to 30 seconds (2*_forward delay timer_). After 30 seconds of plugging in the device, the port on the switch is going to start forwarding frames.

# Spanning Tree Variants
The spanning tree protocol discussed so far is **IEEE 802.1D** or **Common Spanning Tree (_CST_)**, because it doesn't account for VLANs and assigns a single spanning tree for all VLANs, which may be sub-optimal for the individual VLANs. Redundant links that might have been a better path for a specific VLAN sit idly. An alternative is **Per-VLAN Spanning Tree (_PVST_)** where a separate root bridge is assigned for each VLAN. Thus, if Switch B can be the root bridge for VLAN 200 and 300 while Switch A can be the root for VLAN 100, and so on. Then, the redundant links don't have to block all traffic, but only traffic for specific VLANs (i.e., prune specific VLANs), thus reducing the load on other switches as well, thus performing load-balancing.

Cisco's proprietary PVST is used over ISL trunks while **PVST+ is used over 802.1Q trunks**, and is thus more common. While these two approaches do use the optimal paths for each VLAN and perform Load Balancing, it still forces each VLAN to have its own spanning tree. This means if there are two or more VLANs having the same optimal path in the network, they still each get their own spanning tree, which is a load on the switch's resources. Instead, we could use **Multiple Instance Spanning Tree Protocol (MISTP_)** or **Multiple Spanning Tree (_MST_)** [_802.1s_]. MISTP is an older name for MST protocol. In this, there are multiple instances of spanning trees and each VLAN that would benefit from that spanning tree is assigned to that instance.

Another variant of STP is **Rapid Spanning Tree Protocol (RSTP)** [_802.1w_]. While a normal Spanning Tree has a convergence time of about 50 seconds after link failure, RSTP has a _typical_ convergence time of 2-3 seconds, although it's not always true. Cisco has it's own proprietary variant of it called **RPVST+ (_Rapid Per-VLAN Spanning Tree Protocol +_)**. When a port transitions to forwarding from previously being in a blocking state, it can send out **TCN (_Topology Change Notification_) BPDUs** that lets its adjacent switches know that they should _flush_ their MAC address tables in order to accommodate the new path. This can propagate throughout the network to deliver faster convergence times. The difference between RSTP and RPVST+ is that RPVST+ runs a separate instance of RSTP for each VLAN on the network.

# PVST+ Calculation
By default Cisco switches run PVST+ as their default Spanning Tree Protocol (STP). Let us consider the topology below. We see the bridge priority is the same for all, a default of `32,768`. Thus, the MAC addresses of the bridges decide the root bridge. The STP calculations are:
* Here, Switch sw2 is the root bridge (`0011 < 0014 < fcfb`).
* Root Ports: **sw1 Gi0/0** and **sw3 Gi0/1**
* Designated Ports: **sw2 Gi0/0**, **sw2 Gi0/1**, **sw2 Gi0/2** and **sw3 Gi0/0**.
* Blocking Ports: **sw1 Gi0/1** and **sw3 Gi0/2**.

## STP Calculations
### Root port calculation
Since **sw1 Gi0/0** is connected directly to the root, on sw1, the root port is Gi0/0. However, sw3 has two ports with the same cost (2) connected to the root: Gi0/1 and Gi0/2. Only one can be the root port. Hence, **sw2 Gi0/1** is the root port on the basis of port ID (`128.3 < 128.4`).

### Designated Port Calculation
All ports on the root bridge are designated ports: **sw2 Gi0/0**, **sw2 Gi0/1**, **sw2 Gi0/2**. Because each network segment may have only 1 designated port, we only have 1 more network segment to consider: _sw1 Gi0/1_ to _sw3 Gi0/0_. Both ports on either ends of this network segment have a cost of _2_ to reach the root. As a tie-breaker, we see which end of the link is connected to a bridge with a lower Bridge ID, which in this case is **sw3 Gi0/0**. The remainder are the blocking ports.

We can also change the port ID on **sw2 Gi0/1** to a larger number, by changing the port priority from _128 to 192_, which would make **sw3 Gi0/2** the root port on sw3, and _sw3 Gi0/1_ a blocking port.

# PVST Configuration
## STP configuration
### Switch 1
The command to see the spanning tree configuration for any VLAN is `show spanning-tree vlan <vlan#>`. Thus, we can see the spanning tree for VLAN 100:

```
sw1#sh spanning-tree vlan 100

VLAN0100
  Spanning tree enabled protocol ieee
  Root ID    Priority    32868
             Address     0011.bbda.ea00
             Cost        4
             Port        1 (GigabitEthernet0/0)
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec

  Bridge ID  Priority    32868  (priority 32768 sys-id-ext 100)
             Address     fcfb.fb97.a980
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec
             Aging Time  300 sec

Interface           Role Sts Cost      Prio.Nbr Type
------------------- ---- --- --------- -------- --------------------------------
Gi0/0               Root FWD 4         128.1    P2p
Gi0/1               Altn BLK 4         128.2    P2p
```

Here, we can see that the root bridge has the MAC address of `0011.bbda.ea00` while sw1 has a MAC address of `fcfb.fb97.a980`, i.e., sw1 is _not_ the root bridge. We can also see the priority is `32868` instead of the expected, `32768`. This is because we're running PVST+ where each VLAN gets its own spanning tree, and thus, each bridge needs an unique Bridge ID. This wouldn't be possible since the in each VLAN, the default priority won't change and neither will the MAC address. So, we split the Bridge ID field into two: one to contain the priority, and the rest to contain the VLAN it belongs to, thus including the VLAN ID in the Bridge ID. Hence, the VLAN number (called the **Extended System ID**) is added to the default priority to get the priority of the bridge.

In CST, the bridge ID is a 64-bit value consisting of a 16-bit bridge priority followed by a 48-bit MAC address of the bridge. In this case, we allocate 12 of the 16-bits of the bridge ID for the VLAN number, and the rest 4-bits for the actual bridge priority. Hence, the actual bridge priority will always be a multiple of 2^12 = 4096 [`0000 xxxx.xxxx.xxxx`, where x = part of VLAN ID].

Just as predicted in the last section, _sw1_ is not the root for VLAN 200 or 300 either:
```
sw1#sh span v 200 | i Address           
             Address     0011.bbda.ea00
             Address     fcfb.fb97.a980
sw1#sh span v 300 | i Address
             Address     0011.bbda.ea00
             Address     fcfb.fb97.a980
```
The `0011.bbda.ea00` MAC address is for sw2, and `fcfb.fb97.a980` for sw1. We can also see that Gi0/1 on sw1 is a blocking port : `Gi0/1 ... BLK`.

### Switch 2
On switch 2, which should be the root bridge for all VLANs for STP, we see all ports are designated ports and there are no root port or blocking port.

```
sw2#sh span v 100

VLAN0100
  Spanning tree enabled protocol ieee
  Root ID    Priority    32868
             Address     0011.bbda.ea00
             This bridge is the root
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec

  Bridge ID  Priority    32868  (priority 32768 sys-id-ext 100)
             Address     0011.bbda.ea00
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec
             Aging Time  300 sec

Interface           Role Sts Cost      Prio.Nbr Type
------------------- ---- --- --------- -------- --------------------------------
Gi0/0               Desg FWD 4         128.1    P2p
Gi0/1               Desg FWD 4         128.2    P2p
Gi0/2               Desg FWD 4         128.3    P2p
```
This is the same for all VLANs.

### Switch 3
On Switch 3, **Gi0/0** should be a root port and **Gi0/1** should be blocking (for all VLANs) which we can verify using:

```
sw3#sh span v 100

VLAN0100
  Spanning tree enabled protocol ieee
  Root ID    Priority    32868
             Address     0011.bbda.ea00
             Cost        4
             Port        2 (GigabitEthernet0/1)
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec

  Bridge ID  Priority    32868  (priority 32768 sys-id-ext 100)
             Address     0014.69ac.2000
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec
             Aging Time  300 sec

Interface           Role Sts Cost      Prio.Nbr Type
------------------- ---- --- --------- -------- --------------------------------
Gi0/0               Desg FWD 4         128.1    P2p
Gi0/1               Root FWD 4         128.2    P2p
Gi0/2               Altn BLK 4         128.3    P2p
```

We can get more details for each VLAN using:
```
sw1#sh span vlan 100 detail

 VLAN0100 is executing the ieee compatible Spanning Tree protocol
  Bridge Identifier has priority 32768, sysid 100, address fcfb.fb97.a980
  Configured hello time 2, max age 20, forward delay 15
  Current root has priority 32868, address 0011.bbda.ea00
  Root port is 1 (GigabitEthernet0/0), cost of root path is 4
  Topology change flag not set, detected flag not set
  Number of topology changes 0 last change occurred 01:18:42 ago
  Times:  hold 1, topology change 35, notification 2
          hello 2, max age 20, forward delay 15
  Timers: hello 0, topology change 0, notification 0, aging 300

 Port 1 (GigabitEthernet0/0) of VLAN0100 is root forwarding
   Port path cost 4, Port priority 128, Port Identifier 128.1.
   Designated root has priority 32868, address 0011.bbda.ea00
   Designated bridge has priority 32868, address 0011.bbda.ea00
   Designated port id is 128.1, designated path cost 0
   Timers: message age 1, forward delay 0, hold 0
   Number of transitions to forwarding state: 1
   Link type is point-to-point by default
   BPDU: sent 1, received 2357

 Port 2 (GigabitEthernet0/1) of VLAN0100 is alternate blocking
   Port path cost 4, Port priority 128, Port Identifier 128.2.
   Designated root has priority 32868, address 0011.bbda.ea00
   Designated bridge has priority 32868, address 0014.69ac.2000
   Designated port id is 128.1, designated path cost 4
   Timers: message age 2, forward delay 0, hold 0
   Number of transitions to forwarding state: 0
   Link type is point-to-point by default
   BPDU: sent 2, received 2359
```

## Changing the Port priority
If we wanted to make a particular port the preferred (root/designated) port, we could change its port ID by changing the port priority. Currently on sw3, Gi0/1 is the root port while Gi0/2 is blocking:

```
sw3#sh span v 200        

VLAN0200
  Spanning tree enabled protocol ieee
  Root ID    Priority    32968
             Address     0011.bbda.ea00
             Cost        4
             Port        2 (GigabitEthernet0/1)
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec

  Bridge ID  Priority    32968  (priority 32768 sys-id-ext 200)
             Address     0014.69ac.2000
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec
             Aging Time  300 sec

Interface           Role Sts Cost      Prio.Nbr Type
------------------- ---- --- --------- -------- --------------------------------
Gi0/0               Desg FWD 4         128.1    P2p
Gi0/1               Root FWD 4         128.2    P2p
Gi0/2               Altn BLK 4         128.3    P2p
```

We can convert Gi0/2 to the root port and Gi0/1 to blocking by changing the port priority of the far-end port, i.e., _sw2_ with:
```
sw2(config)#int g0/1
sw2(config-if)#spanning-tree port-priority ?
  <0-224>  port priority in increments of 32

sw2(config-if)#spanning-tree port-priority 192
```
This immediately starts a **re-convergence of STP** on sw3, and after about 50 seconds, the new STP for all the VLANs will be:

```
sw3#sh span v 200         

VLAN0200
  Spanning tree enabled protocol ieee
  Root ID    Priority    32968
             Address     0011.bbda.ea00
             Cost        4
             Port        3 (GigabitEthernet0/2)
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec

  Bridge ID  Priority    32968  (priority 32768 sys-id-ext 200)
             Address     0014.69ac.2000
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec
             Aging Time  300 sec

Interface           Role Sts Cost      Prio.Nbr Type
------------------- ---- --- --------- -------- --------------------------------
Gi0/0               Desg FWD 4         128.1    P2p
Gi0/1               Altn BLK 4         128.2    P2p
Gi0/2               Root FWD 4         128.3    P2p
```
We can see that Gi0/1 and Gi0/2 have swapped roles.

## Changing the cost
We can also manipulate the STP by artificially changing the cost, because the STP judges links on the basis of costs for redundant links between two bridges and only considers port numbers when the costs are the same:
```
sw3(config)#int g0/1
sw3(config-if)#spanning-tree cost 3
sw3#sh sp v 100

VLAN0100
  Spanning tree enabled protocol ieee
  Root ID    Priority    32868
             Address     0011.bbda.ea00
             Cost        3
             Port        2 (GigabitEthernet0/1)
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec

  Bridge ID  Priority    32868  (priority 32768 sys-id-ext 100)
             Address     0014.69ac.2000
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec
             Aging Time  15  sec

Interface           Role Sts Cost      Prio.Nbr Type
------------------- ---- --- --------- -------- --------------------------------
Gi0/0               Desg FWD 4         128.1    P2p
Gi0/1               Root LIS 3         128.2    P2p
Gi0/2               Altn BLK 4         128.3    P2p
```

We can see that it goes through the listening, learning and ultimately forwarding phase:
```
sw3#sh sp v 100 | i Gi0/1
Gi0/1               Root LIS 3         128.2    P2p
sw3#sh sp v 100 | i Gi0/1
Gi0/1               Root LRN 3         128.2    P2p
sw3#sh sp v 100 | i Gi0/1
Gi0/1               Root FWD 3         128.2    P2p
```

## Changing Bridge Priority
We can change a bridge to the root by changing the bridge priority:

```
sw1(config)#spanning-tree vlan 100 ?
  forward-time  Set the forward delay for the spanning tree
  hello-time    Set the hello interval for the spanning tree
  max-age       Set the max age interval for the spanning tree
  priority      Set the bridge priority for the spanning tree
  root          Configure switch as root
  <cr>

sw1(config)#spanning-tree vlan 100 priority ?
  <0-61440>  bridge priority in increments of 4096
```
If a value of less than 32768 is entered, the switch becomes the root. We can also directly force it to be root as well. Further, we can configure primary and secondary roots for PVST+.

## PVST Manipulations
Since we have a STP for every VLAN, we'd can set up PVST+ such that Sw1 acts as the primary root for VLANs 100 and 300 and as the secondary root for VLAN 200. A **secondary root** is a switch/bridge that takes over the responsibility of the root if the primary root goes down. Similarly, we can also set up sw3 to act as the primary root for VLAN 200 and secondary root for VLANs 100 and 300. For this we use:

```
sw1(config)#spanning-tree vlan 100 root primary
sw1(config)#spanning-tree vlan 300 root primary
sw1(config)#spanning-tree vlan 200 root secondary

sw3(config)#span v 200 root pri
sw3(config)#span v 100,300 root sec
```

Now on sw1, we can see that it's the root for VLANs 100 and 300:
```
sw1#sh sp v 100

VLAN0100
  Spanning tree enabled protocol ieee
  Root ID    Priority    24676
             Address     fcfb.fb97.a980
             This bridge is the root
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec

  Bridge ID  Priority    24676  (priority 24576 sys-id-ext 100)
             Address     fcfb.fb97.a980
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec
             Aging Time  300 sec

Interface           Role Sts Cost      Prio.Nbr Type
------------------- ---- --- --------- -------- --------------------------------
Gi0/0               Desg FWD 4         128.1    P2p
Gi0/1               Desg FWD 4         128.2    P2p

sw1#sh sp v 300 | i root
             This bridge is the root
```
The method used to make this switch the primary is by lowering the priority to `24676` from `32868`. Similarly, for a secondary root:
```
sw1#sh sp v 200

VLAN0200
  Spanning tree enabled protocol ieee
  Root ID    Priority    24776
             Address     0014.69ac.2000
             Cost        4
             Port        2 (GigabitEthernet0/1)
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec

  Bridge ID  Priority    28872  (priority 28672 sys-id-ext 200)
             Address     fcfb.fb97.a980
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec
             Aging Time  300 sec

Interface           Role Sts Cost      Prio.Nbr Type
------------------- ---- --- --------- -------- --------------------------------
Gi0/0               Desg FWD 4         128.1    P2p
Gi0/1               Root FWD 4         128.2    P2p
```
VLAN 200 has a Bridge Priority of `28872`, which is more than the root's priority of `24776` by `4096`, but it's still lesser than the default priority of `32868`, thus making it the obvious secondary choice in case Bridge 1 goes down.

# RPVST+ Theory
Cisco's implementation of the Rapid Spanning Tree Protocol is through its own variant, the RPVST+ protocol, which assigns a Rapid Spanning Tree for each VLAN. Just like in normal STP, a root bridge has to be elected and all ports on that root bridge are deemed _Designated Ports_. We also have root ports and disabled ports (administratively shut down). What we referred to as _blocking ports_ become **alternate ports**, i.e., ports that are capable of becoming an alternate to the root port. It is a port that is currently discarding all data frames, but can provide an alternate path for the traffic to reach the root bridge.

If we look at the topology above we see that two links from sw3 lead to the hub, which means they're on the same shared ethernet segment. Typically in STP we can only have 1 port on a shared ethernet segment, which in this case, is the designated port. The other port is called a **backup port**. A backup port is an alternate port that acts as a redundant link to a shared segment. This means a backup port is a port that's capable of providing an alternate path to the root bridge if needed, is currently discarding data frames and lies on a shared ethernet segment. This means *the only time we may encounter a backup port is when we're connected to an ethernet hub*.

## RPVST Port States
**Discarding** - Data isn't being forwarded on this port - may be an _alternate, backup or disabled_ port.
**Learning** - The switch is learning MAC addresses from packets on the port. Port is _transitioning to forwarding_.
**Forwarding** - Data is being forwarded on the port (i.e., _root port or designated port_).

## RPVST Link Types
**Point to Point Link** - A link running in full-duplex mode, typically connecting one switch to another.
**Shared Link** - A link running in half-duplex mode, typically connecting a switch to a hub.
**Edge port** - Connects to an end-user device/station, i.e., a network endpoint. While calculating RSTP never considers edge ports as ports that can lead back to the root bridge. If we forget after setting a port as an edge port, and we later connect a switch to it, when that port receives a BPDU, it's going to transition out from being an edge port.

## RSTP Topology change
RSTP only considers a non-edge port transitioning to a forwarding state as a topology change. Let us consider a downstream switch is connected to a port on our switch that goes down. If the port that went down was only connected to our network via that switchport, then there's nothing we can do about it. There's no alternative way of connecting that network back to our root switch. Hence, there's no point in telling the network about the link going down. However, if there is another path back to the root for it, i.e., there's an alternate port, it'll soon transition to a forwarding state, which will then trigger a topology change notification.

The major difference between STP and RSTP is that when a topology change is detected, STP sends the TCN after waiting for the _max-age_ timer to expire. Then it transitions to the listening state and waits for the _forward delay timer_ to expire, by which time it receives a hello BPDU from the root bridge on some port which becomes the new root port. Now, it spends the same amount of time in the learning state. Finally, it then transitions to the forwarding state. In the meantime, once the TCN reaches the root bridge, the root bridge has to send a TCA (Topology Change Acknowledgement) to the switch reporting the change and then set the TC (Topology Change) bit to 1 in it's BPDUs. When these BPDUs reach the other switches, they realize that a topology change has occurred.

However, in RSTP, first of all the _max-age timer_ has been reduced to _6_ seconds and the _forward-delay timer_ has been eliminated all together. Upon link failure, the switch which has had to change its port from _alternate_ to _root port_ will send out it's own BPDUs with the TC flag set to 1 to notify it's neighbours about the change.

When a neighbour receives a topology change, it'll start the _synchronization process_  and block all the other ports other than the new port and the edge ports (to prevent loops from happening). The neighbours will then start the _negotiation phase_ where they'll evaluate the new path to see if the cost is lowered by putting the ports on either side of the link in a listening state, and then once the ideal paths have been determined, they unblock the ports and pass on the new BPDUs to their neighbours and so on.

# RPVST+ configuration
To see which mode (PVST+/RPVST+) mode the switch is currently in, we use the `show spanning-tree summary` command.
```
sw1#sh span sum
Switch is in pvst mode
Root bridge for: VLAN0100, VLAN0300
Extended system ID                      is enabled
Portfast Default                        is disabled
Portfast Edge BPDU Guard Default        is disabled
Portfast Edge BPDU Filter Default       is disabled
Loopguard Default                       is disabled
PVST Simulation Default                 is enabled but inactive in pvst mode
Bridge Assurance                        is enabled but inactive in pvst mode
EtherChannel misconfig guard            is enabled
Configured Pathcost method used is short
UplinkFast                              is disabled
BackboneFast                            is disabled

Name                   Blocking Listening Learning Forwarding STP Active
---------------------- -------- --------- -------- ---------- ----------
VLAN0001                     1         0        0          3          4
VLAN0100                     0         0        0          2          2
VLAN0200                     0         0        0          2          2
VLAN0300                     0         0        0          2          2
---------------------- -------- --------- -------- ---------- ----------
4 vlans                      1         0        0          9         10
```

To enable RPVST+, we have to use the same command on all the switches - `spanning-tree mode rapid-pvst`
```
sw1(config)#span mode rapid-pvst
```

Now we can confirm that we're running RPVST+ by:
```
sw1#sh span sum
Switch is in rapid-pvst mode
Root bridge for: VLAN0100, VLAN0300
Extended system ID                      is enabled
Portfast Default                        is disabled
Portfast Edge BPDU Guard Default        is disabled
Portfast Edge BPDU Filter Default       is disabled
Loopguard Default                       is disabled
PVST Simulation Default                 is enabled but inactive in rapid-pvst mode
Bridge Assurance                        is enabled
EtherChannel misconfig guard            is enabled
Configured Pathcost method used is short
UplinkFast                              is disabled
BackboneFast                            is disabled

Name                   Blocking Listening Learning Forwarding STP Active
---------------------- -------- --------- -------- ---------- ----------
VLAN0001                     1         0        0          3          4
VLAN0100                     0         0        0          2          2
VLAN0200                     0         0        0          2          2
VLAN0300                     0         0        0          2          2
---------------------- -------- --------- -------- ---------- ----------

Name                   Blocking Listening Learning Forwarding STP Active
---------------------- -------- --------- -------- ---------- ----------
4 vlans                      1         0        0          9         10
```
Although the output states that we're running in _rapid-pvst_ mode, since we're using *dot1q* trunks instead of *ISL* trunks, we're actually using RPVST+ protocol.

## Changing Link Type
We can see from the following output that on sw1, the port Gi0/1 is set to be a Point-to-Point (P2p) Interface. We can change the interface type by either hard-coding it or changing the duplex settings.
```
sw1(config)#int g0/1
sw1(config-if)#span link-type ?
  point-to-point  Consider the interface as point-to-point
  shared          Consider the interface as shared
```
We can see that there are only two options: P2p and shared, but not _edge port_. That is done in another way. If we change the duplex, the interface-type will also change:
```
sw1(config-if)#duplex half
sw1(config-if)#do sh sp v 300

VLAN0300
  Spanning tree enabled protocol rstp
  Root ID    Priority    24876
             Address     fcfb.fb97.a980
             This bridge is the root
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec

  Bridge ID  Priority    24876  (priority 24576 sys-id-ext 300)
             Address     fcfb.fb97.a980
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec
             Aging Time  300 sec

Interface           Role Sts Cost      Prio.Nbr Type
------------------- ---- --- --------- -------- --------------------------------
Gi0/0               Desg FWD 4         128.1    P2p
Gi0/1               Desg FWD 4         128.2    Shr
Gi0/2               Desg FWD 4         128.3    P2p
```
We can see that on changing the duplex the link type immediately changes. This is because the link-type is determined on the basis of the current duplex mode.

### Converting port to Edge port using PortFast
The method to convert a port to an edge port is by turning on PortFast on it. By this act, we're telling the switch that the device we're connecting is a end-user device and hence won't send BPDUs, and thus the port should skip the listening and learning phase. We turn on PortFast using `spanning-tree portfast` in interface configuration mode for the edge port.
```
sw1(config)#int g0/2
sw1(config-if)#span portf
%Warning: portfast should only be enabled on ports connected to a single
 host. Connecting hubs, concentrators, switches, bridges, etc... to this
 interface  when portfast is enabled, can cause temporary bridging loops.
 Use with CAUTION

%Portfast has been configured on GigabitEthernet0/2 but will only
 have effect when the interface is in a non-trunking mode.
sw1(config-if)#do sh sp v 300 | b Interface
Interface           Role Sts Cost      Prio.Nbr Type
------------------- ---- --- --------- -------- --------------------------------
Gi0/0               Desg FWD 4         128.1    P2p
Gi0/1               Desg FWD 4         128.2    P2p
Gi0/2               Desg FWD 4         128.3    P2p Edge
```

# PortFast
Normally, due to STP, there is about a 30sec delay when an end-user device is connected to a port on a switch, because the switch has no way of knowing intuitively if the device on the far end of the link is an edge port or another switch. Thus, it spends 15 sec listening for BPDUs and another 15 learning IP addresses of that port. This is of course unnecessary on an edge port since it's a network end-point an offers no path to the root through it, and thus the port can be made to connect and start forwarding packets almost instantly using PortFast. It can either be enabled on every port individually or globally.

To enable portfast on a single or range of interfaces, we can use:
```
sw4(config)#int g0/1 - 3
sw4(config-if-ran)#spanning-tree portfast
```

To enable it globally and not have to set it up for each individual interface, we go to the global config mode and use `spanning-tree portfast default`:
```
sw4(config)#spanning-tree portfast default
```
Even though we're turning it on globally, since trunk ports don't connect to edge ports, the portfast feature is only going to be turned on for _non-trunking ports_. To see if portfast is turned on for a particular interface, we use:

```
sw1#sh spanning-tree int g0/2 portfast
VLAN0300            enabled
```

# BPDUGuard
After portfast has been enabled on a port, and after we're done using it, we may forget to turn it off. If after this, we were to use the _now free port_ on which portfast is still configured to connect a bridge, depending on the wiring, there's a chance of _Layer-2 Topological Loop_ formation. However, portfast has a feature built in that lets it _eventually_ transition from an edge port to a forwarding port on detecting a BPDU. The problem lies in the fact that this isn't immediate and hence, for a time, there might be issues on the network, such as a broadcast storm. Fortunately, there is a feature that puts the port in an _error disabled_ state as soon as the first BPDU arrives on the port. This feature is called **BPDUGuard** and like PortFast, it can be enabled globally or on an interface to interface basis.

To turn it on for a single interface, we use:
```
sw1(config-if)#spanning-tree bpduguard enable
```

To turn it on globally on all ports that have PortFast turned on, we use:
```
sw1(config)#spanning-tree portfast edge bpduguard default
```

Then to check if a port has BPDUGuard turned on, we use:
```
sw1#sh span sum
Switch is in rapid-pvst mode
Root bridge for: VLAN0100, VLAN0300
Extended system ID                      is enabled
Portfast Default                        is disabled
Portfast Edge BPDU Guard Default        is enabled
...
```

After a port has entered a _error-disabled_ state, to bring it back up to normal status, we first want to ensure that we resolve whatever caused it to go error disabled, i.e., in this case, unplug the switch which sent an BPDU into an BPDUGuarded port, we can just bounce the state to make it operational. 
