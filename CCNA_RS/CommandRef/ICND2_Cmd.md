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

# EtherChannel
Let us consider a switch that has a lot of high-bandwidth connections coming it that it needs to communicate with another switch. Here, since all the data is being passed from a single interface, that interface itself can become a bottle-neck. Even if we connected the two switches using multiple interfaces, STP would just turn one of the links into a _blocked port_ and let traffic flow through one of the ports while the other one is as good as unplugged! This can be a terrible wastage of an interface's bandwidth. **EtherChannel** is a technology that allows us to combine the bandwidth of the ports by combining multiple physical ports into a single logical port. The advantages of EtherChannel are:
* It allows higher bandwidth between switches
* Provides load-balancing between the switches
* Maintains redundancy and is still useful after one of the links fail.

From the perspective of STP/RSTP, the EtherChannel bundle thus created appears as a single (logical) interface with the combined bandwidth of the two ports used, called a _port-channel interface_. The IEEE 802.3AD standard was created _after_ Cisco came up with this, but Cisco still supports both, so we're safe in a multi-vendor environment.

The individual physical links in an EtherChannel aren't used in a round-robin fashion but instead, the link to use is determined by some load-balancing algorithm. One such possible algorithm can be based on the destination IP address. Consider the topology below. We have 4 links between the switches. So, we could divide frames based on the last `log2(2) = 2` bits of an IP address. So, if the last 2 bits are `00`, it goes through the first link, for `01` the seconds, and so on.

However, if we have a high powered server that uses a _GigE_ link and we have four _FastEthernet_ links, all traffic going to the IP of the server will be utilizing only 1 link. The same is true if we segregate the packets based on their destination MAC address, or source IP/MAC addresses. Thus, we could consider both the source and destination IP or MAC addresses while choosing the link between switches. We could take the last two bits of both, _XOR_ them and then choose the path that matches the result. This is the calculation of 4 channels. If there were 8 links in the EtherChannel, then we'd be looking at the last `log2(8)  = 3` bits.

# EtherChannel Port Options
EtherChannels have a couple of link aggregation protocols used to actually convert the bundle of physical links into a single logical link. They are Cisco's proprietary **Port Aggregation Protocol(_PAgP_)** and another, that's an industry standard [_802.AD_], called the **Link Aggregation Control Protocol (_LACP_)**. Both can be used to negotiate an EtherChannel between two Cisco switches. The ports at either end of any link in the EtherChannel need to be set up identically, having the same:
* Speed
* Duplex
* VLAN Assignments

## Port Aggregation Protocol (_PAgP_)
We can put our ports in one of 3 possible *PAgP Channel modes*:
* **On** - Tells the port to be an EtherChannel without any negotiation. We don't send/receive PAgP frames. Only forms an EtherChannel with another _On_ port.
* **Auto** - Forms an EtherChannel if it sees PAgP frames coming from the other end of the link, but won't send PAgP frames to initiate EtherChannel formation. Only forms an EtherChannel with _Desirable_ ports.
* **Desirable** - Sends PAgP frames to start the negotiation of an EtherChannel. Can form an EtherChannel with either an _auto_ or another _desirable_ port.

The combination of the above modes lead to:
```
PAgP Channel mode   On      Auto    Desirable
=================   ======  ======  =========
On                  Yes     No      No
Auto                No      No      Yes
Desirable           No      Yes     Yes
```
If one side is set to _on_ an other to _desirable_, they still won't form an EtherChannel since they both want to form an EtherChannel but one side is willing to negotiate via PAgP frames while the other side just ignores it. Similarly, if both sides are set to _auto_, both sides want to negotiate but neither will start the negotiation by sending PAgP frames.

## Link Aggregation Control Protocol (_LACP_)
LACP has identical prot control modes to _PAgP_, with just the _auto_ mode being called **Passive** mode here and the _desirable_ mode being called **Active** mode. Thus, the possible port combinations for EtherChannel formation are:
```
LACP Channel mode   On      Passive     Active
=================   ======  =======     =========
On                  Yes     No          No
Passive             No      No          Yes
Active              No      Yes         Yes
```

# Layer 2 EtherChannel Configuration
A **Layer 2 EtherChannel port** is a virtual port that's been configured as a layer 2 interface, i.e., a _switchport_. With it, we can do things like making it a trunk port just like any other port on a switch. In the topology below, sw2 and sw3 have a couple of ports (**Gi0/1** and **Gi0/2**) on each switch that form a redundant link that we want to convert to an EtherChannel. First, we have to ensure that they both have the same speed, duplex and VLAN assignments. Also, since we're connecting swtiches, i.e., _like devices_, we need to use a **cross-over cable**. If we have straight-through cable, we need to make sure that MDI-X is turned on for both switches, which **require auto speed and duplex** on the ports.

We can use interface configuration mode to configure multiple interfaces at the same time. If we have auto-negotiation turned on, we don't need to manually set the port and duplex to _auto_ (and we can't). If not, we use:
```
sw2(config)#int ran g0/1-2
sw2(config-if-range)#speed auto
sw2(config-if-range)#duplex auto
sw2(config-if-range)#mdix auto
```

Let's say we want to use **PAgP** here instead of LACP, and we want to set the ports to desirable on sw2 and auto on sw3. The EtherChannel will be called `channel-group` and since this is the first EtherChannel on the switch, we use the number `1`:
```
sw2(config-if-range)#channel-group 1 mode desirable
Creating a port-channel interface Port-channel 1

*Dec 18 10:31:59.344: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/1, changed state to down
*Dec 18 10:31:59.365: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/2, changed state to down
*Dec 18 10:32:07.920: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/1, changed state to up
*Dec 18 10:32:08.915: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/2, changed state to up
```
We can see that both ports were bounced to form the `port-channel`, i.e., EtherChannel.

Depending on the protocol, the possible options for the virtual port modes were:
```
sw2(config-if-range)#channel-group 1 mode ?
  active     Enable LACP unconditionally
  auto       Enable PAgP only if a PAgP device is detected
  desirable  Enable PAgP unconditionally
  on         Enable Etherchannel only
  passive    Enable LACP only if a LACP device is detected
```

We now have a new virtual port called EtherChannel called `Port-channel1`:
```
sw2(config)#do sh ip int br
Interface              IP-Address      OK? Method Status                Protocol
GigabitEthernet0/0     unassigned      YES unset  up                    up      
GigabitEthernet0/1     unassigned      YES unset  up                    up      
GigabitEthernet0/2     unassigned      YES unset  up                    up      
GigabitEthernet0/3     unassigned      YES unset  up                    up      
Port-channel1          unassigned      YES unset  down                  down    
sw2(config)#do sh int status

Port      Name               Status       Vlan       Duplex  Speed Type
Gi0/0                        connected    1          a-full   auto RJ45
Gi0/1                        connected    1          a-full   auto RJ45
Gi0/2                        connected    1          a-full   auto RJ45
Gi0/3                        connected    1          a-full   auto RJ45
Po1                          notconnect   unassigned   auto   auto
```

We can convert it into a dot1q trunk just like any other layer-2 port:
```
sw2(config)#int po1
sw2(config-if)#switchport trunk encap dot1q
*Dec 18 10:37:15.857: %EC-5-CANNOT_BUNDLE2: Gi0/1 is not compatible with Gi0/2 and will be suspended (trunk encap of Gi0/1 is dot1q, Gi0/2 is auto)
*Dec 18 10:37:15.866: %EC-5-COMPATIBLE: Gi0/1 is compatible with port-channel members
sw2(config-if)#sw mode trunk
sw2(config-if)#do sh int trunk

Port        Mode             Encapsulation  Status        Native vlan
Gi0/1       on               802.1q         trunking      1
Gi0/2       on               802.1q         trunking      1

Port        Vlans allowed on trunk
Gi0/1       none
Gi0/2       none

Port        Vlans allowed and active in management domain
Gi0/1       none
Gi0/2       none

Port        Vlans in spanning tree forwarding state and not pruned
Gi0/1       none
Gi0/2       none
sw2(config-if)#no shut
```

We now want to create an identical configuration on sw3, but with the EtherChannel port mode to _auto_ instead of _desirable_:
```
sw3(config)#int ran g0/1-2
sw3(config-if-range)#neg auto
sw3(config-if-range)#channel-group 1 mode auto
Creating a port-channel interface Port-channel 1
*Dec 18 10:47:53.301: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/1, changed state to down
*Dec 18 10:47:53.342: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/2, changed state to down
*Dec 18 10:48:02.197: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/2, changed state to up
*Dec 18 10:48:02.448: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/1, changed state to up
sw3(config-if-range)#int po1
*Dec 18 10:48:16.672: %LINK-3-UPDOWN: Interface Port-channel1, changed state to up
*Dec 18 10:48:17.672: %LINEPROTO-5-UPDOWN: Line protocol on Interface Port-channel1, changed state to up
sw3(config-if)#sw tr encap dot
sw3(config-if)#sw mode tr
```

Now, the `show interface trunk` command won't show us two separate trunks for _Gi0/1_ and _Gi0/2_ but a single trunk for **Port-channel1**:
```
sw2#sh int tr    

Port        Mode             Encapsulation  Status        Native vlan
Po1         on               802.1q         trunking      1

Port        Vlans allowed on trunk
Po1         1-4094

Port        Vlans allowed and active in management domain
Po1         1

Port        Vlans in spanning tree forwarding state and not pruned
Po1         1
sw2#sh int status    

Port      Name               Status       Vlan       Duplex  Speed Type
Gi0/0                        connected    1          a-full   auto RJ45
Gi0/1                        connected    trunk      a-full   auto RJ45
Gi0/2                        connected    trunk      a-full   auto RJ45
Gi0/3                        connected    1          a-full   auto RJ45
Po1                          connected    trunk      a-full   auto
sw2#sh ip int br Po1
Interface              IP-Address      OK? Method Status                Protocol
Port-channel1          unassigned      YES unset  up                    up      
```

The logical interface, made of two individual 1Gbps interfaces will now show up with a bandwidth of 2Gbps:
```
sw2#sh int po1 | i BW
  MTU 1500 bytes, BW 2000000 Kbit/sec, DLY 10 usec,
```

# Layer 3 EtherChannel Configuration
Layer 2 VLANs are perfectly adequate if we have end-to-end VLANs throughout the enterprise, i.e., in all the buildings we have the same VLANs with the same configuration, connected via trunks, in which case Port-channel provides a high-bandwidth trunk. However, if each building has its own VLAN, i.e., _local VLAN deployment_, that needs to be routed to another building with another set/configuration of VLANs, and instead of sending traffic over a trunk, we route between buildings, then we need a Layer 3 EtherChannel. In such a case we need to leave a building over a **routed port**.  

 A **routed port** is a port on a Cisco switch that acts like a port on a router. For example, it can be assigned an IP address. Thus, we can form a **Layer 3 EtherChannel** that is then configured to act as a routed interface. we can convert switch-ports to routed ports using the `no switchport` command on switches. Since we're using EtherChannels, we need to convert both the individual switchports as well as the aggregated Port-Channel to routed ports. For obvious reasons of L3 operation, this needs an L3 switch.

 First, we prepare the two ports each on both switches for the port channel and then turn them into routed ports. Then we create the port channel, convert it into a routed port as well and then bring up the port-channel:
 ```
sw2(config)#int ran g0/1-2
sw2(config-if-range)#neg auto
sw2(config-if-range)#no switchport
*Dec 18 11:40:33.823: %LINK-5-CHANGED: Interface GigabitEthernet0/1, changed state to administratively down
*Dec 18 11:40:33.896: %LINK-5-CHANGED: Interface GigabitEthernet0/2, changed state to administratively down
*Dec 18 11:40:34.825: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/1, changed state to down
*Dec 18 11:40:34.896: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/2, changed state to down
sw2(config-if-range)#channel-group 1 mode on
Creating a port-channel interface Port-channel 1
sw2(config-if-range)#no shut
*Dec 18 11:42:00.747: %LINK-3-UPDOWN: Interface GigabitEthernet0/1, changed state to up
*Dec 18 11:42:00.969: %LINK-3-UPDOWN: Interface Port-channel1, changed state to up
*Dec 18 11:42:01.033: %LINK-3-UPDOWN: Interface GigabitEthernet0/2, changed state to up
*Dec 18 11:42:01.747: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/1, changed state to up
*Dec 18 11:42:01.971: %LINEPROTO-5-UPDOWN: Line protocol on Interface Port-channel1, changed state to up
*Dec 18 11:42:02.039: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/2, changed state to up
sw2(config-if-range)#int po1
sw2(config-if)#no switchport

sw3(config)#int ran g0/1-2
sw3(config-if-range)#neg auto
sw3(config-if-range)#no switchport
*Dec 18 11:43:35.548: %LINK-5-CHANGED: Interface GigabitEthernet0/1, changed state to administratively down
*Dec 18 11:43:35.626: %LINK-5-CHANGED: Interface GigabitEthernet0/2, changed state to administratively down
*Dec 18 11:43:36.550: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/1, changed state to down
*Dec 18 11:43:36.626: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/2, changed state to down
sw3(config-if-range)#channel-gr 1 mode on
Creating a port-channel interface Port-channel 1
sw3(config-if-range)#no shut
*Dec 18 11:44:02.875: %LINK-3-UPDOWN: Interface GigabitEthernet0/1, changed state to up
*Dec 18 11:44:03.056: %LINK-3-UPDOWN: Interface Port-channel1, changed state to up
*Dec 18 11:44:03.113: %LINK-3-UPDOWN: Interface GigabitEthernet0/2, changed state to up
*Dec 18 11:44:03.878: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/1, changed state to up
*Dec 18 11:44:04.057: %LINEPROTO-5-UPDOWN: Line protocol on Interface Port-channel1, changed state to up
*Dec 18 11:44:04.175: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/2, changed state to up
sw3(config-if-range)#int po1
sw3(config-if)#no switchport
```

Let us assume we want to create the following topology where the two routed port-channels are connected via a link with the IP addresses `10.1.1.1/30` on sw1 and `10.1.1.2/30` on sw2. We use the `/30` subnet mask since we only need 2 IP addresses in the network (`10.1.1.0/30`). Now, we can set up loopback interfaces with the IP `1.1.1.1/32` on sw1 and `2.2.2.2/32` on sw2. Finally, we want to set up RIPv2 on the routers to dynamically share routes.
```
sw2(config-if)#ip addr 10.1.1.1 255.255.255.252
sw2(config-if)#int lo1
*Dec 18 11:54:44.344: %LINEPROTO-5-UPDOWN: Line protocol on Interface Loopback1, changed state to up
sw2(config-if)#ip addr 1.1.1.1 255.255.255.255
sw2(config-if)#router rip
sw2(config-router)#version 2
sw2(config-router)#network 1.0.0.0
sw2(config-router)#network 10.0.0.0
sw2(config-router)#no auto-summary

sw3(config-if)#ip addr 10.1.1.2 255.255.255.252
sw3(config-if)#int lo1
*Dec 18 11:55:03.687: %LINEPROTO-5-UPDOWN: Line protocol on Interface Loopback1, changed state to up
sw3(config-if)#ip addr 2.2.2.2 255.255.255.255
sw3(config-if)#router rip
sw3(config-router)#ver 2
sw3(config-router)#net 10.0.0.0
sw3(config-router)#net 2.0.0.0
sw3(config-router)#no auto-sum
```

Now we have a Layer 3 EtherChannel between the two switches. We can confirm this by:

```
sw2#sh ip int br | b Loop
Loopback1              1.1.1.1         YES manual up                    up      
Port-channel1          10.1.1.1        YES manual up                    up      
sw2#sh ip route | i R
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
R        2.2.2.2 [120/1] via 10.1.1.2, 00:00:10, Port-channel1

sw3#sh ip int br | b Loop
Loopback1              2.2.2.2         YES manual up                    up      
Port-channel1          10.1.1.2        YES manual up                    up      
sw3#sh ip route | i R
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
R        1.1.1.1 [120/1] via 10.1.1.1, 00:00:21, Port-channel1
```
In the above output, we can see that sw2 learnt about `2.2.2.2` over Port-channel1 and sw3 learnt about `1.1.1.1` over Port-channel1. So, the routes were learn over the EtherChannel.

We can also confirm that we have connectivity between the switches with:
```
sw2#ping 2.2.2.2         
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 2.2.2.2, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 7/15/26 ms
sw2#traceroute 2.2.2.2
Type escape sequence to abort.
Tracing the route to 2.2.2.2
VRF info: (vrf in name/id, vrf out name/id)
  1 10.1.1.2 23 msec *  6 msec
```

# EtherChannel Troubleshooting
We can see which ports were bundled to form EtherChannels with the `show etherchannel summary` command:
```
sw2#sh etherch sum
Flags:  D - down        P - bundled in port-channel
        I - stand-alone s - suspended
        H - Hot-standby (LACP only)
        R - Layer3      S - Layer2
        U - in use      N - not in use, no aggregation
        f - failed to allocate aggregator

        M - not in use, minimum links not met
        m - not in use, port not aggregated due to minimum links not met
        u - unsuitable for bundling
        w - waiting to be aggregated
        d - default port

        A - formed by Auto LAG


Number of channel-groups in use: 1
Number of aggregators:           1

Group  Port-channel  Protocol    Ports
------+-------------+-----------+-----------------------------------------------
1      Po1(RU)          -        Gi0/1(P)    Gi0/2(P)    
```

The protocol is set to `-` since the mode was set to `on`. In case we specified _PAgP_ or _LACP_, we would see:
```
sw2#sh etherch sum
Flags:  D - down        P - bundled in port-channel
        I - stand-alone s - suspended
        H - Hot-standby (LACP only)
        R - Layer3      S - Layer2
        U - in use      N - not in use, no aggregation
        f - failed to allocate aggregator

        M - not in use, minimum links not met
        m - not in use, port not aggregated due to minimum links not met
        u - unsuitable for bundling
        w - waiting to be aggregated
        d - default port

        A - formed by Auto LAG


Number of channel-groups in use: 1
Number of aggregators:           1

Group  Port-channel  Protocol    Ports
------+-------------+-----------+-----------------------------------------------
1      Po1(SU)         PAgP      Gi0/1(P)    Gi0/2(P)    
```

To see more details like the mode of the ports, we have to use the `show etherchannel port-channel` command:
```
sw2#sh etherch port-ch
                Channel-group listing:
                ----------------------

Group: 1
----------
                Port-channels in the group:
                ---------------------------

Port-channel: Po1
------------

Age of the Port-channel   = 0d:00h:03m:58s
Logical slot/port   = 16/0          Number of ports = 2
GC                  = 0x00010001      HotStandBy port = null
Port state          = Port-channel Ag-Inuse
Protocol            =   PAgP
Port security       = Disabled

Ports in the Port-channel:

Index   Load   Port     EC state        No of bits
------+------+------+------------------+-----------
  0     00     Gi0/1    Desirable-Sl       0
  0     00     Gi0/2    Desirable-Sl       0

Time since last port bundled:    0d:00h:03m:39s    Gi0/2
```

## EtherChanel Guard
The **EtherChannel Guard** feature monitors the port-channels on both sides of the EtherChannel link and if it detects mismatched parameters it immediately generates an error and puts the port in an _error-disabled_ state. It's enabled by default, but we can confirm with the `show spanning-tree summary` command:
```
sw2#sh span sum | i Ether
EtherChannel misconfig guard            is enabled
```

In case it's disabled for some reason, we can turn it back on using `spanning-tree etherchannel guard misconfig` command:
```
sw2(config)#sp eth guard misconf
```

## Load-Balancing
In case we get poor performance from the EtherChannel, one reason may be improper load-balancing which we might resolve by changing the load-balancing algorithm. We can see the current algorithm using the `show etherchannel load-balancing` command:
```

sw2#sh etherch load
EtherChannel Load-Balancing Configuration:
        src-dst-ip

EtherChannel Load-Balancing Addresses Used Per-Protocol:
Non-IP: Source XOR Destination MAC address
  IPv4: Source XOR Destination IP address
  IPv6: Source XOR Destination IP address
```
We can see it's currently set to load balance on the basis of both the source and destination IP addresses. Since we have two channels, only the last `log2(2) = 1` bit will determine which link in the aggregate is chosen to send the packet. So, if the XOR of the last digits of both IP is 0, **Gi0/0** is chosen and if not, **Gi0/1**.

We can see and set the different load-balancing options using the `port-channel load-balancing` command in global config:
```
sw2(config)#port-channel load-balance ?
  dst-ip       Dst IP Addr
  dst-mac      Dst Mac Addr
  src-dst-ip   Src XOR Dst IP Addr
  src-dst-mac  Src XOR Dst Mac Addr
  src-ip       Src IP Addr
  src-mac      Src Mac Addr
```

# IP Routing
# Router-on-a-stick concept
Let us consider we have a L2 (_Layer 2_) switch that can't route packets. If we have multiple VLANs, and we want hosts on those VLANs to communicate, we need some sort of a router to connect to to translate addresses between the subnets of the VLANs. For example, if VLAN100 has a network address of `192.168.1.0/24` and VLAN200 has a network address of `192.168.2.0/24`, we need a router to translate the route the packets between the two VLANs.

In the actual switch itself, containing both VLANs, we could wire up two different ports in the switch to the router - one from VLAN100 to the router and the other from VLAN200 to the router. This is not very scalable however, since we can have, for example, 10 different VLANs and we don't want to use up 10 ports on the router! A much more efficient method is to connect the L2 switch to the router with a trunk port which carries data for all the VLANs.

So, data from VLAN100 will flow up the trunk to the router, be routed to the VLAN300 and then flow down the trunk and back into the switch and then reach the destination host, and vice-versa.

# Configuring a Router-on-a-Stick
In the current status, let's assume we set up the topology below such that there's a trunk leading to the router, and two other ports on the switch each lead to a PC. The interface status should be:
```
sw#sh int status

Port      Name               Status       Vlan       Duplex  Speed Type
Gi0/0                        connected    trunk      a-full   auto RJ45
Gi0/1                        connected    10         a-full   auto RJ45
Gi0/2                        connected    20         a-full   auto RJ45
Gi0/3                        connected    1          a-full   auto RJ45
```

Currently, without the router set up, the PCs won't be able to ping each other:
```
PC-1> ping 172.16.1.2
host (192.168.1.1) not reachable
```

## Sub interfaces
Given that a trunk port is connected to the router on **Gi0/0**, we can carve up the single interface into multiple local interfaces, one for each VLAN. This is required since this is how router ports handle trunks. We assign a protocol for trunking and a VLAN to each logical interface. We want to assign _sub-interface 1 (**Gi0/0.1**)_ to VLAN 10 and _sub-interface 2(**Gi0/0.2**)_ to VLAN 20, and then assign their IPs. The command to assign the encapsulation and VLAN is `encapsulation <encapName> <VLAN-ID>`:
```
ROAS(config)#int g0/0.1
ROAS(config-subif)#encapsulation dot1q 10
ROAS(config-subif)#ip addr 192.168.1.1 255.255.255.0
ROAS(config-subif)#int g0/0.2
ROAS(config-subif)#encap dot 20
ROAS(config-subif)#ip addr 172.16.1.1 255.255.255.0
ROAS(config-subif)#int g0/0
ROAS(config-if)#no shut
*Dec 18 13:49:46.567: %LINK-3-UPDOWN: Interface GigabitEthernet0/0, changed state to up
*Dec 18 13:49:47.567: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/0, changed state to up
```

Now we can see the sub-interfaces:
```
ROAS#sh ip int br
Interface                  IP-Address      OK? Method Status                Protocol
GigabitEthernet0/0         unassigned      YES unset  up                    up      
GigabitEthernet0/0.1       192.168.1.1     YES manual up                    up      
GigabitEthernet0/0.2       172.16.1.1      YES manual up                    up      
...
```

Now the two PCs can reach each other:
```
PC-1> sh ip
NAME        : PC-1[1]
IP/MASK     : 192.168.1.2/24
GATEWAY     : 192.168.1.1
PC-1> ping 172.16.1.2
84 bytes from 172.16.1.2 icmp_seq=1 ttl=63 time=26.702 ms
84 bytes from 172.16.1.2 icmp_seq=2 ttl=63 time=11.904 ms
84 bytes from 172.16.1.2 icmp_seq=3 ttl=63 time=11.088 ms
84 bytes from 172.16.1.2 icmp_seq=4 ttl=63 time=15.978 ms
84 bytes from 172.16.1.2 icmp_seq=5 ttl=63 time=12.178 ms
```

We can also see the VLANs known by the router using:
```
ROAS#show vlans

Virtual LAN ID:  1 (IEEE 802.1Q Encapsulation)

   vLAN Trunk Interface:   GigabitEthernet0/0

 This is configured as native Vlan for the following interface(s) :
GigabitEthernet0/0    Native-vlan Tx-type: Untagged

   Protocols Configured:   Address:              Received:        Transmitted:

GigabitEthernet0/0 (1)
        Other                                           0                  95

   71 packets, 10016 bytes input
   95 packets, 9535 bytes output

Virtual LAN ID:  10 (IEEE 802.1Q Encapsulation)

   vLAN Trunk Interface:   GigabitEthernet0/0.1

   Protocols Configured:   Address:              Received:        Transmitted:

GigabitEthernet0/0.1 (10)
           IP              192.168.1.1                 11                  10
        Other                                           0                   2

   11 packets, 1088 bytes input
   12 packets, 1112 bytes output

Virtual LAN ID:  20 (IEEE 802.1Q Encapsulation)

   vLAN Trunk Interface:   GigabitEthernet0/0.2

   Protocols Configured:   Address:              Received:        Transmitted:

GigabitEthernet0/0.2 (20)
           IP              172.16.1.1                   6                   5
        Other                                           0                   2

   6 packets, 574 bytes input
   7 packets, 602 bytes output
```

# SVI and Routed Port Concepts
L3 switches are capable of doing routing themselves and don't require a separate router. Consider the topology below. We have two devices connected to the multi-layer switch, the first belongs to VLAN10 and the second to VLAN20. We want to route between them. We can create **Switch Virtual Interfaces (_SVI_)** that'll represent all the ports on a VLAN and then assign IP addresses to these SVIs and configure routing between them. This is one of the prime differences between multi-layer switches and routers - on a router typically each port is on its own subnet/VLAN but a multi-layer switch lets us have several devices belonging to a subnet connect via different ports, which we then allow to route through SVIs.

## Routed Port
Let us consider the above example where we have a bunch of ports assigned to VLAN10 and another bunch to VLAN20, and have SVIs assigned for each, which lets us route between them. However, if we wanted to communicate with an external router now, we have to configure another port to be a routed port and we assign it an IP address, which we then connect to a router. Now, we'll be able to route internally between all the VLANs on the switch, and if we need to communicate with devices outside the network, we can simply use the router as a next hop.

# SVI and Routed Port Configuration
The IP address for SVIs that represent each VLAN will be the IP address for the gateway in the devices connected to that VLAN. Thus, the IP address for the SVI in VLAN10, `192.168.1.1` will be the gateway for PC-1 and VLAN20 has an SVI with the IP `172.16.1.1` that will be the gateway for PC-2. Our fist goal is to create the SVIs and allow routing between the two VLANs. The current VLAN assignment is:
```
VLAN Name                             Status    Ports
---- -------------------------------- --------- -------------------------------
1    default                          active    Gi0/0, Gi0/3
10   VLAN0010                         active    Gi0/1
20   VLAN0020                         active    Gi0/2
1002 fddi-default                     act/unsup
1003 token-ring-default               act/unsup
1004 fddinet-default                  act/unsup
1005 trnet-default                    act/unsup
```
We'll now **create the SVIs by creating an interface for the VLAN**, and then assign IP addresses to them:
```
sw1(config)#int vlan 10
*Dec 19 09:25:29.093: %LINEPROTO-5-UPDOWN: Line protocol on Interface Vlan10, changed state to down
sw1(config-if)#ip addr 192.168.1.1 255.255.255.0
sw1(config-if)#no shut
*Dec 19 09:28:14.240: %LINK-3-UPDOWN: Interface Vlan10, changed state to up
*Dec 19 09:28:15.241: %LINEPROTO-5-UPDOWN: Line protocol on Interface Vlan10, changed state to up
sw1(config-if)#int vlan 20
*Dec 19 09:26:14.591: %LINEPROTO-5-UPDOWN: Line protocol on Interface Vlan20, changed state to down
sw1(config-if)#ip addr 172.16.1.1 255.255.255.0
sw1(config-if)#no shut
*Dec 19 09:26:44.653: %LINK-3-UPDOWN: Interface Vlan20, changed state to up
*Dec 19 09:26:45.653: %LINEPROTO-5-UPDOWN: Line protocol on Interface Vlan20, changed state to up
sw1(config-if)#exit
sw1(config)#ip routing
```
The last command, `ip routing` needs to be enabled since this is a L3 switch that can also act as an L2 switch when the layer 3 functionality is off. We turn on L3 (routing) features with the command.

We should now be able to ping PC2 from PC1 and vice versa:
```
PC-1> ping 172.16.1.2
172.16.1.2 icmp_seq=1 timeout
172.16.1.2 icmp_seq=2 timeout
84 bytes from 172.16.1.2 icmp_seq=3 ttl=63 time=4.545 ms
84 bytes from 172.16.1.2 icmp_seq=4 ttl=63 time=11.222 ms
84 bytes from 172.16.1.2 icmp_seq=5 ttl=63 time=8.289 ms
```

Now, to connect the switch to a router, we need to convert the switch port to a routed port. We could create another SVI, assign an IP to it, in the same subnet as the link on the far end on the router, but that's unneccesary overhead, since we won't need other devices belonging to the router's VLAN. Hence, we can directly assign an IP address to the router's port by converting it to a routed port. We do this by using the `no switchport` command in interface config mode:
```
sw1(config)#int g0/0
sw1(config-if)#no switchport
*Dec 19 09:40:45.359: %LINK-3-UPDOWN: Interface GigabitEthernet0/0, changed state to up
*Dec 19 09:40:46.360: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/0, changed state to up
sw1(config-if)#ip addr 10.1.1.1 255.255.255.252
```

Now the interfaces look like:
```
sw1#sh ip int br | e unassigned
Interface              IP-Address      OK? Method Status                Protocol
GigabitEthernet0/0     10.1.1.1        YES manual up                    up      
Vlan10                 192.168.1.1     YES manual up                    up      
Vlan20                 172.16.1.1      YES manual up                    up      
```

We can now also ping the router:
```
sw1#ping 10.1.1.1
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.1.1.1, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 1/2/4 ms
```

## Routing between sw1 and R1
Now, so that the end-devices can reach the subnet of R1, we have to configure a routing protocol or set up static routes on both sw1 and R1. We choose RIPv2 as the routing protocol:
```
sw1(config)#router rip
sw1(config-router)#version 2
sw1(config-router)#network 192.168.1.0
sw1(config-router)#network 172.16.1.0
sw1(config-router)#network 10.0.0.0  
sw1(config-router)#no auto-sum
```

Similarly, R1 needs a config:
```
R1(config)#router rip
R1(config-router)#ver 2  
R1(config-router)#net 10.0.0.0
R1(config-router)#no auto-sum
```

We can now confirm _sw1_ is advertising the networks on its VLANs and _R1_ can see them:
```
sw1#sh ip proto | b rip
Routing Protocol is "rip"
  Outgoing update filter list for all interfaces is not set
  Incoming update filter list for all interfaces is not set
  Sending updates every 30 seconds, next due in 14 seconds
  Invalid after 180 seconds, hold down 180, flushed after 240
  Redistributing: rip
  Default version control: send version 2, receive version 2
    Interface             Send  Recv  Triggered RIP  Key-chain
    GigabitEthernet0/0    2     2                                    
    Vlan10                2     2                                    
    Vlan20                2     2                                    
  Automatic network summarization is not in effect
  Maximum path: 4
  Routing for Networks:
    10.0.0.0
    172.16.0.0
    192.168.1.0
  Routing Information Sources:
    Gateway         Distance      Last Update
  Distance: (default is 120)

R1#sh ip route | i R
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
     D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
     o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
     + - replicated route, % - next hop override, p - overrides from PfR
R        172.16.1.0 [120/1] via 10.1.1.1, 00:00:07, GigabitEthernet0/0
R     192.168.1.0/24 [120/1] via 10.1.1.1, 00:00:07, GigabitEthernet0/0
```

The end-devices will now be able to ping the router's IP:
```
PC-2> ping 10.1.1.2
84 bytes from 10.1.1.2 icmp_seq=1 ttl=254 time=7.706 ms
84 bytes from 10.1.1.2 icmp_seq=2 ttl=254 time=10.238 ms
84 bytes from 10.1.1.2 icmp_seq=3 ttl=254 time=12.132 ms
84 bytes from 10.1.1.2 icmp_seq=4 ttl=254 time=8.959 ms
84 bytes from 10.1.1.2 icmp_seq=5 ttl=254 time=7.636 ms
```

# OSPF
# Dijkstra's Algorithm
The **Open Shortest Path First (_OSPF_)** routing protocol is a _link-state_, open standard routing protocol that's much more flexible and scalable than RIP, and consequently it's used as an _Interior Gateway Protocol (IGP)_ in many enterprises. we're primarily concerned with two different versions: OSPFv2 which can only route for IPv4 networks, and OSPFv3, which can also route for IPv6 networks. Both of them work on **Dijkstra's Algorithm**, which _processes_ a topology to calculate the shortest distance between each node, i.e., it finds the shortest path between each device on the network.

## Explanation of Dijkstra's Algorithm
Dijkstra's algorithm isn't limited to calculating the best route between networking devices. It's used by many navigation platforms such as Google maps to calculate the best path to a destination while driving. Generally speaking, Dijkstra's algorithm calculates the shortest possible distance between two nodes in a _weighted graph_. A **node** or a _vertex_ is a location in Dijkstra's algorithm and **edges** are the paths from one node to another, which have _weights_ or _cost_ associated to them. The algorithm can be used to find the shortest path between two nodes, but can also be extended to find the best paths from a source node to every other node in the graph to form a **shortest path tree**.

In the case of routers, OSPF does this calculation for all routers in an **area**. An area is like a _map_ where all routers share a common database that tells the routers how to get to each network as well the cost involved to get to that network. OSPF will run on all of the routers in an area and they'll all calculate an identical map. In case of routers outside the area, we'll consider the best path to a router that can get us out of the area and to the destination area.

Let us consider the topology below, with the weights indicating the link speeds. We'll be looking from the perspective of R1. R1 will try to calculate the best path to get to any of the networks in the topology. So, in this _graph_, both the routers as well as the Routers are _nodes/vertices_ and the links are the _edges_. However, since we're not really trying to get to another router, each router will ignore the other routers and only consider the cost to the different networks. Hence, R1 will only see the different networks as _nodes_.

### Pass 1
Initially, the cost to every network is assumed to be infinity. Then, R1 will find the networks that it's *directly* connected to and assign them costs based on the link speed. So, we get the following distances:
```
From node   10.1.1.0        10.2.2.0        10.3.3.0        10.4.4.0        10.5.5.0
=========   =============   =============   =============   =============   =============
R1          1 (via R1)      10 (R1)         infinity        inf             inf         
```

Consequently, we've found the network that's least costly to reach. After each pass, we get the lowest cost to one of the networks, which in this case is the `10.1.1.0` network. We're _done_ finding the best path to it, and it won't change. We don't need to calculate that value again anymore.

### Pass 2
Now, we'll consider the 10.1.1.0 network and consider the best path to the other networks from that node.
- To get to `10.2.2.0` from `10.1.1.0`, we'd need to go through R1, and hence the total cost will be _10+1=11_, but the currently known least cost is _10_. Hence, we ignore it.
- To get to `10.2.2.0` from `10.1.1.0`, we have a cost of _1+1=2_. However, we also have to consider the cost to get to R1, which is 1, and thus the total cost is _1+2=3_. Since 3 is less than the previously known least cost, i.e., infinity, it becomes the new shortest path, and we mark
`10.1.1.0` as the node that gets us there.
- We don't have connections from `10.1.1.0`, i.e., current node to the other two networks, i.e., `10.4.4.0` and `10.5.5.0`, so we copy their old shortest known path, i.e, infinity.

The new values of the shortest paths will be in the table will be:
```
From node   10.1.1.0        10.2.2.0        10.3.3.0        10.4.4.0        10.5.5.0
=========   =============   =============   =============   =============   =============
R1          1 (R1)*         10 (R1)         inf             inf             inf         
---------   -------------   -------------   -------------   -------------   -------------
10.1.1.0    1 (R1)*         10 (R1)         3 (10.1.1.0)*   inf             inf
```
In this pass, we've obtained the shortest path to a new node, i.e., `10.3.3.0` via `10.1.1.0` and that won't change, so we won't calculate it anymore.

### Pass 3
Now we'll try reaching the all the networks (to which we don't know the shortest path yet) from the perspective of the `10.3.3.0`:
- We already know the best paths to `10.1.1.0` and `10.3.3.0` networks, so we won't consider them any further.
- First we try to see if `10.2.2.0` is reachable from `10.3.3.0` than directly from R1 - but since it's not connected, we'll just copy down the old shortest known path.
- `10.4.4.0` is reachable at a cost of 11 + cost to get to `10.3.3.0`, which makes the total cost _3+11=14_. Since `14` which is less than infinity. So, we set that as the new shortest known path.
- `10.5.5.0` is reachable at a cost of 2 + cost to get to `10.3.3.0`, which makes the total cost _3+2=5_. Since `5` is less than infinity, making it the new shortest known path.

The shortest paths now are:
```
From node   10.1.1.0        10.2.2.0        10.3.3.0        10.4.4.0        10.5.5.0
=========   =============   =============   =============   =============   =============
R1          1 (R1)*         10 (R1)         inf             inf             inf         
---------   -------------   -------------   -------------   -------------   -------------
10.1.1.0    1 (R1)*         10 (R1)         3 (10.1.1.0)*   inf             inf
---------   -------------   -------------   -------------   -------------   -------------
10.3.3.0    1 (R1)*         10 (R1)         3 (10.1.1.0)*   14 (10.3.3.0)   5 (10.3.3.0)*
```
The permanent shortest path obtained in this pass is `10.5.5.0` via `10.3.3.0`.

### Pass 4
We'll now find out the cost to get to the remaining networks via `10.5.5.0`.
- We already know shortest routes to `10.1.1.0`, `10.3.3.0` and `10.5.5.0` - we'll just copy them.
- Calculate cost of getting to `10.2.2.0` from `10.5.5.0` - since they're not connected it's infinity; We know a better path via R1, so we ignore this path.
- Calculate cost of getting to `10.4.4.0` from `10.5.5.0` = 11 + cost to get to `10.5.5.0` from R1 = _11+5 = 16_. This is more than the last known shortest path via `10.3.3.0` _of 14_, so we ignore it.  

The shortest paths now are:
```
From node   10.1.1.0        10.2.2.0        10.3.3.0        10.4.4.0        10.5.5.0
=========   =============   =============   =============   =============   =============
R1          1 (R1)*         10 (R1)         inf             inf             inf         
---------   -------------   -------------   -------------   -------------   -------------
10.1.1.0    1 (R1)*         10 (R1)         3 (10.1.1.0)*   inf             inf
---------   -------------   -------------   -------------   -------------   -------------
10.3.3.0    1 (R1)*         10 (R1)         3 (10.1.1.0)*   14 (10.3.3.0)   5 (10.3.3.0)*
---------   -------------   -------------   -------------   -------------   -------------
10.5.5.0    1 (R1)*         10 (R1)*        3 (10.1.1.0)*   14 (10.3.3.0)   5 (10.3.3.0)*
```

The permanent shortest path obtained in this pass is `10.2.2.0` via _R1_, since we know that the other nodes are too costly to get us there via them.

### Pass 5
In the final pass, we'll find out the cost to get to the _last_ remaining networks, `10.4.4.0` via `10.2.2.0` and see if that's better than the current lowest known cost, i.e., _14_.
- Copy the best routes we already know.
- Calculate cost of getting to `10.4.4.0` from `10.2.2.0` - it's _20_ + cost to get to `10.2.2.0` = _20+10 = 30_. Since `20>14`, we'll ignore this route.
- We now have the shortest paths from R1 to each node, as well as know which node to go through to get to them:

```
From node   10.1.1.0        10.2.2.0        10.3.3.0        10.4.4.0        10.5.5.0
=========   =============   =============   =============   =============   =============
R1          1 (R1)*         10 (R1)         inf             inf             inf         
---------   -------------   -------------   -------------   -------------   -------------
10.1.1.0    1 (R1)*         10 (R1)         3 (10.1.1.0)*   inf             inf
---------   -------------   -------------   -------------   -------------   -------------
10.3.3.0    1 (R1)*         10 (R1)         3 (10.1.1.0)*   14 (10.3.3.0)   5 (10.3.3.0)*
---------   -------------   -------------   -------------   -------------   -------------
10.5.5.0    1 (R1)*         10 (R1)*        3 (10.1.1.0)*   14 (10.3.3.0)   5 (10.3.3.0)*
---------   -------------   -------------   -------------   -------------   -------------
10.2.2.0    1 (R1)*         10 (R1)*        3 (10.1.1.0)*   14 (10.3.3.0)*  5 (10.3.3.0)*
```

So, the best routes are:
```
From node   10.1.1.0        10.2.2.0        10.3.3.0        10.4.4.0        10.5.5.0
=========   =============   =============   =============   =============   =============
R1          1 (R1)          10 (R1)         3 (10.1.1.0)    14 (10.3.3.0)   5 (10.3.3.0)
```

The shortest path tree becomes:

Each router in the given OSPF area will calculate this tree and route according to the best known path.

# OSPF Overview
Unlike _RIPv2_ or _EIGRP_, which are _distance-vector_ routing protocols, OSPF is a **link-state routing protocol** , which means it must be fed a _map_ of the area on which it'll run the **Dijsktra's Shortest Path First (SPF)** algorithm, or simply, the _SPF_ algorithm  to get the shortest path to each network in the area. It can form **adjacencies** with other routers which is different from **neighbourships**. OSPF only passes network condition updates to routers with which it's formed _adjacencies_.

We can take our entire OSPF network and sub-divide them into multiple *areas*. This can be done so that every route on the network doesn't have to know about every other router on the network, but just their part of the network, i.e., their _area_. Routers send **Link State Advertisements (_LSA_)** to every router in their area. There can be several different types of LSAs, some of which let us advertise network of one area in another area.   

Every router in an area will have an identical _view of the topology in the area_, i.e., a database about the connections in the area. A router running OSPF forms this **Link State Database** by collecting all the LSAs that comes to it. The SPF algorithm is run on each area and the only criterion for cost is the bandwidth. Thus, if a router sits at a boundary of an area, it needs to run SPF twice: once for each area. At the end of all the calculations, OSPF tries to inject the best route to a network into the router's IP routing table from it's own **Routing Information Base (_RIB_)**. Whether the route makes it to the routing table or not depends on the AD of the other routes in the routing table.

# OSPF Neighbour Formation
## Neighbours
Neighbours are routers that are in the same network and exchange _hello_ messages. In case of OSPFv2 the destination address for the hello messages is the IPv4 Unicast IP address `224.0.0.5`. In case of IPv6, OSPFv3 uses the `FF02::5` address. However, _no routing information_, i.e., **LSAs** are exchanged with neighbours. *Neighbouring routers don't necessarily share LSAs - but adjacent routers do!*

## Adjacent routers
The criteria for being an adjacent router is:
- Must be neighbours
- Must have exchanged **Link State Updates (_LSUs_)** and **Database Description (_DD_)** packets. Both of these are used to form the Link State Database of the routers in an area.
- **Only adjacent routers manufacture the link state database**.

## Forming an Adjacency
Let us consider the topology below. To start with, the interfaces on both routers are down, i.e., the state of the link, or **link state** is down. Now, when the interfaces come up:
* R1 goes to the _Init state_.
* R1 sends a _hello_ message to R2.
    - R2 goes through the _hello_ message from R1, and sees the list of neighbours known to R1, but doesn't find itself in it.
    - This changes the state of R2 to **Init**.
    - **Init** state means that R2 received a hello message from R1 that didn't contain it's **Router ID**.
* R2 now goes into _2-way state_.
* R2 replies with a _hello_ message.
    - R1 sees the list of neighbours in the hello message and **finds its router ID** (because R2 now knows R1 is a neighbour).
    - This changes R1's link state to the **2-way state**.
    - **2-Way** state means that R1 received a hello message from R2 that *contained R1's router ID* and thus, recognized R1 as a neighbour.
* When both routers know about each other as neighbours, i.e., when both are in a _2-way_ state, a **Designated Router (_DR_)** and a **Backup Designated Router (_BDR_)** may be elected. Some types of OSPF networks will elect them while some will not.
* Both routers will now transition to the **ExStart** state.
    - In this state, the primary and secondary routers for the formation of the Link State Database are elected.
* Both routers will now transition to the **Exchange** state.
    - The **Exchange** state is the state in which the actual _exchange of network information_ occurs to create the Link State Database.
    - The primary router elected in the _ExStart_ state sends **Database Description (_DD_)** packets to the secondary router.
    - If R1 is the primary, inside each DD packet there's a list of **Link State Advertisements (_LSAs_)** known to R1.
    - The secondary router replies with an acknowledgement.
    - The acknowledgement contains a list of **Link State Advertisements (_LSAs_)** known to R2. A point to be noted is that LSAs aren't a packet type.
* Both routers now proceed to the **loading** state.
    - Both routers check the received DD against the list of their own LSAs. If any LSA is missing, they request/query the neighbour to send a copy of the LSA using a **Link State Request (_LSR_)**.
    - The neighbour replies with a **Link State Update (_LSU_)** which the requestor uses to fill in the missing entry.
* Once both routers have an identical copy of the Link State Database, the state is called **full**, because the adjacency has fully formed.

# OSPF Areas
Every interface that's participating in OSPF must belong to an area. We use areas to carve up the network into different sections. When we run the Dijkstra's SPF algorithm on the link state topology in the link state database, it's run within the boundaries of the area and every router ends up with the same view of the area. We don't need to have multiple areas, but for scalability, we can divide a large network into several smaller areas. In such cases, we'd have different instances of SPF running for each area.

In a multi-area topology, we must have a **backbone area (Area 0)** or area _0.0.0.0_ to which all other areas would connect directly. In the topology shown below, there are 3 areas: area 0, 1 and 2. Every area, however, needs to be contiguous, i.e., they need to be directly connected to Area 0. Each of the areas have their own instance of SPF algo running, but the two routers that sit at the intersection of the areas, **R4** and **R7** are called **Area Border Routers (_ABR_s)**, since they have interfaces in more than one area. Since they're in multiple areas, they have more than one instance of the SPF running on them.

For example, R4 has an instance of SPF running for _area 1_ and another running for the backbone, _area 0_, and consequently, will have a section of its link state database that has the topology for area 1 and another section containing the topology of the backbone. A special LSA is used to send the routers in area 0 the routes available in area 1 since it doesn't need to know any details beyond that, like the actual topology of area 1.

Originally it was suggested that an area shouldn't have more than 50 routers, but that was based on the available processing power on a router. This is because the more the number of nodes, the more intensive calculation is required to run the SPF algorithm on that area. But given the increases in processing power of modern day enterprise-grade routers like the cisco ISR/ISR2, etc, that may no longer be a major concern. In practice, we could place non-Cisco routers in their own OSPF area given that they might behave unpredictably than our Cisco routers.

In case there's a non-contiguous area, i.e., an area not directly connected to area 0 on the network, but connected through another area, then we _can_ connect that area to area 0 with a virtual/logical link, although Cisco doesn't recommend it. Cisco prefers that we re-design the network to ensure all other areas are physically connected to area 0.

# OSPFv2 Configuration
## R1 config
We want to set up a multi-area OSPF topology as shown in the figure below. First we have to start up OSPF with a _locally significant process ID_, that _doesn't_ have to match up with the neighbours (unlike EIGRP). Next, we specify a _network statement_ to state explicitly which interfaces will be participating in OSPF, i.e., which interfaces (falling within this network) will receive and advertise routes via OSPF. We also need a wild-card mask to specify the host bits.

Given that our subnet mask length is /24, the last `32-24=8` bits are 1's in the wildcard mask, which becomes: `0.0.0.255`. Since we want the `192.168.1.1/24` interface to participate in OSPF, we use, `network 192.168.1.0 0.0.0.255`. We also specify the area in the network command, which in this case will be area 1. So, the complete command becomes `network 192.168.1.0 0.0.0.255 area 1`:
```
R1(config)#router ospf 1
R1(config-router)#network 192.168.1.0 0.0.0.255 area 1
R1(config-router)#network 1.1.1.1 0.0.0.0 area 1
R1(config-router)#network 10.0.0.1 0.0.0.0 area 1
```
With the last 2 commands, we also add the loopback interface and the interface leading to _sw1_ in OSPF area 1.

## R2 Config
R2 is _special_ since it's an **Area Border Router (_ABR_)**, i.e., a router that runs OSPF for 2 ore more different areas, one of which is area 0/backbone of OSPF. We know that the interface `Gi0/0` with IP `10.0.0.2/24` will be in area 1 while the rest of the two interfaces will be in area 0. The process ID for OSPF of course, doesn't have to match up to that running on R1, but we'll use PID 1 just for the sake of consistency. The loopback can be in either area 1 or 0, but we choose 1.

Let us first start the OSPF process, and setup the interfaces for the loopback, and area 0 to participate in OSPF. Given that all the interfaces in the area 0 interconnting R1, R2 and R3 have a `/30` subnet mask, their wildcard mask will be `255.255.255.255 - 255.255.255.252 = 0.0.0.3`. We include them in OSPF using:
```
R2(config)#router ospf 1
R2(config-router)#network 2.2.2.2 0.0.0.0 area 1
R2(config-router)#network 192.168.0.0 0.0.0.3 area 0
R2(config-router)#network 192.168.0.4 0.0.0.3 area 0  
```  

There's also an additional way to tell the router which interfaces to allow to participate in OSPF. Since all we're doing is telling the router which participating interfaces will be in which area of OSPF, we can directly do so from the interface configuration mode using the `ip ospf <pid> area <areaID>` command:
```
R2(config-if)#ip ospf 1 area 1
*Dec 20 12:28:45.309: %OSPF-5-ADJCHG: Process 1, Nbr 1.1.1.1 on GigabitEthernet0/0 from LOADING to FULL, Loading Done
```
We can see there's an immediate adjacency formation between R1 and R2. Further, the route for 1.1.1.1 was exchanged from R1 to R2 via an LSU. Finally, once this was done, the adjacency reached _full_ state.

## R3 and R4 Config
All the interfaces in R3 and R4 need to participate in OSPF and all are contained within area 0. So, instead of setting them up all individually, we _can_ set them up generically. We can ask the router to let all the interfaces participate in OSPF in area 0. The command is `network 0.0.0.0 255.255.255.255 area 0`:
```
R3(config)#router ospf 1
R3(config-router)#network 0.0.0.0 255.255.255.255 area 0
*Dec 20 12:35:46.062: %OSPF-5-ADJCHG: Process 1, Nbr 2.2.2.2 on GigabitEthernet0/1 from LOADING to FULL, Loading Done

R4(config)#router ospf 1
R4(config-router)#network 0.0.0.0 255.255.255.255 area 0
*Dec 20 12:37:42.615: %OSPF-5-ADJCHG: Process 1, Nbr 2.2.2.2 on GigabitEthernet0/1 from LOADING to FULL, Loading Done
*Dec 20 12:37:42.618: %OSPF-5-ADJCHG: Process 1, Nbr 3.3.3.3 on GigabitEthernet0/2 from LOADING to FULL, Loading Done
```
We can see that once OSPF on R4 was configured, it formed 2 adjacencies: one with R2 (`2.2.2.2/32`) and one with R3 (`3.3.3.3/32`).

Finally, we can now use the `ip route show` command to see all the routes learnt by the router R4 via OSPF:
```
R4#sh ip route | i O
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
O IA     1.1.1.1 [110/3] via 192.168.0.5, 00:01:39, GigabitEthernet0/1
O IA     2.2.2.2 [110/2] via 192.168.0.5, 00:01:39, GigabitEthernet0/1
O        3.3.3.3 [110/2] via 192.168.0.9, 00:01:39, GigabitEthernet0/2
O IA     10.0.0.0 [110/2] via 192.168.0.5, 00:01:39, GigabitEthernet0/1
O        172.16.1.0/24 [110/2] via 192.168.0.9, 00:01:39, GigabitEthernet0/2
O        192.168.0.0/30 [110/2] via 192.168.0.9, 00:01:39, GigabitEthernet0/2
O IA  192.168.1.0/24 [110/3] via 192.168.0.5, 00:01:39, GigabitEthernet0/1
```
We can see that some of the routes have an `IA` next to them, which indicate `IA - OSPF inter area`. This means the routes were learnt from OSPF running in another area.

From the full `ip route show` command, we also see:
```
O        192.168.0.0/30 [110/2] via 192.168.0.9, 00:17:45, GigabitEthernet0/2
                        [110/2] via 192.168.0.5, 00:17:45, GigabitEthernet0/1
```
Here we find that **R4** has 2 alternate paths to the 192.168.0.0/30 network, one via R2 and R3, and it can load balance using the links if need be.  The cost of both are the same, i.e., 2 as noted in `[110/2]`. The first number, `110` is the Administrative Distance (AD) of the OSPF protocol.

# OSPFv2 Verification
We'll start our verification on our ABR, *R2*. We can see which interfaces are participating in OSPF using the `show ip ospf interface brief` command:
```
R2#sh ip ospf int br
Interface    PID   Area            IP Address/Mask    Cost  State Nbrs F/C
Gi0/2        1     0               192.168.0.5/30     1     DR    1/1
Gi0/1        1     0               192.168.0.1/30     1     DR    1/1
Lo1          1     1               2.2.2.2/32         1     LOOP  0/0
Gi0/0        1     1               10.0.0.2/24        1     BDR   1/1
```
We can see which OSPF process the interfaces are linked to, the area where they operate, the IP address of the interfaces, the cost and the neighbours available through that interface. Of course, the loopback doesn't have any neighbour accessible through it.

We can get the routing details for OSPF using `show ip protocols` command:
```
R2#sh ip proto | b ospf
Routing Protocol is "ospf 1"
  Outgoing update filter list for all interfaces is not set
  Incoming update filter list for all interfaces is not set
  Router ID 2.2.2.2
  It is an area border router
  Number of areas in this router is 2. 2 normal 0 stub 0 nssa
  Maximum path: 4
  Routing for Networks:
    2.2.2.2 0.0.0.0 area 1
    192.168.0.0 0.0.0.3 area 0
    192.168.0.4 0.0.0.3 area 0
  Routing on Interfaces Configured Explicitly (Area 1):
    GigabitEthernet0/0
  Routing Information Sources:
    Gateway         Distance      Last Update
    4.4.4.4              110      00:51:29
    3.3.3.3              110      00:51:29
    1.1.1.1              110      00:59:57
  Distance: (default is 110)
```
We see that the router ID is obtained from the loopback interface, which in this case is `Router ID 2.2.2.2`. We also see that we can load-balance across 4 equal cost paths: `Maximum path: 4`. We can see which networks we're routing for and also which interface we explicitly configured. The Gi0/0 interface is in that list because we asked it to participate in OSPF in the interface configuration mode instead of setting up OSPF for its network. We also see the neighbours from which we're getting routing information:
```
Routing Information Sources:
  Gateway         Distance      Last Update
  4.4.4.4              110      00:51:29
  3.3.3.3              110      00:51:29
  1.1.1.1              110      00:59:57
```

We can also get more details about the neighbours using the `show ip ospf neighbor` command:
```
R2#sh ip o ne

Neighbor ID     Pri   State           Dead Time   Address         Interface
4.4.4.4           1   FULL/BDR        00:00:39    192.168.0.6     GigabitEthernet0/2
3.3.3.3           1   FULL/BDR        00:00:30    192.168.0.2     GigabitEthernet0/1
1.1.1.1           1   FULL/DR         00:00:39    10.0.0.1        GigabitEthernet0/0
```
We can also see which interface the neighbours are connected to.

Now, we can view the OSPF Link State Database using `sh ip ospf database` command:
```
R2#sh ip ospf datab

            OSPF Router with ID (2.2.2.2) (Process ID 1)

                Router Link States (Area 0)

Link ID         ADV Router      Age         Seq#       Checksum Link count
2.2.2.2         2.2.2.2         1597        0x80000006 0x00BE9C 2
3.3.3.3         3.3.3.3         1660        0x80000003 0x009BC6 4
4.4.4.4         4.4.4.4         1608        0x80000002 0x00DB71 4

                Net Link States (Area 0)

Link ID         ADV Router      Age         Seq#       Checksum
192.168.0.1     2.2.2.2         1850        0x80000002 0x006E47
192.168.0.5     2.2.2.2         1597        0x80000002 0x007835
192.168.0.9     3.3.3.3         1660        0x80000002 0x00544D

                Summary Net Link States (Area 0)

Link ID         ADV Router      Age         Seq#       Checksum
1.1.1.1         2.2.2.2         79          0x80000003 0x002FFD
2.2.2.2         2.2.2.2         338         0x80000003 0x00F633
10.0.0.0        2.2.2.2         79          0x80000003 0x00D057
192.168.1.0     2.2.2.2         79          0x80000003 0x00A026

                Router Link States (Area 1)

Link ID         ADV Router      Age         Seq#       Checksum Link count
1.1.1.1         1.1.1.1         123         0x80000006 0x005A25 3
2.2.2.2         2.2.2.2         79          0x80000004 0x0006E8 2

                Net Link States (Area 1)

Link ID         ADV Router      Age         Seq#       Checksum
10.0.0.1        1.1.1.1         123         0x80000003 0x0077A5

                Summary Net Link States (Area 1)

Link ID         ADV Router      Age         Seq#       Checksum
3.3.3.3         2.2.2.2         1850        0x80000002 0x00D451
4.4.4.4         2.2.2.2         1597        0x80000002 0x00A67B
172.16.1.0      2.2.2.2         1850        0x80000002 0x00CEA5
172.16.2.0      2.2.2.2         1597        0x80000002 0x00C3AF
192.168.0.0     2.2.2.2         338         0x80000003 0x008F3C
192.168.0.4     2.2.2.2         338         0x80000003 0x006760
192.168.0.8     2.2.2.2         1850        0x80000002 0x004B78
```
We can see that part of the database is for area 0 and part for area 1.

If we go to R4, we'll see the same area 0 database:
```
R4#sh ip ospf d  

            OSPF Router with ID (4.4.4.4) (Process ID 1)

                Router Link States (Area 0)

Link ID         ADV Router      Age         Seq#       Checksum Link count
2.2.2.2         2.2.2.2         1756        0x80000006 0x00BE9C 2
3.3.3.3         3.3.3.3         1819        0x80000003 0x009BC6 4
4.4.4.4         4.4.4.4         1765        0x80000002 0x00DB71 4

                Net Link States (Area 0)

Link ID         ADV Router      Age         Seq#       Checksum
192.168.0.1     2.2.2.2         2010        0x80000002 0x006E47
192.168.0.5     2.2.2.2         1756        0x80000002 0x007835
192.168.0.9     3.3.3.3         1819        0x80000002 0x00544D

                Summary Net Link States (Area 0)

Link ID         ADV Router      Age         Seq#       Checksum
1.1.1.1         2.2.2.2         232         0x80000003 0x002FFD
2.2.2.2         2.2.2.2         492         0x80000003 0x00F633
10.0.0.0        2.2.2.2         232         0x80000003 0x00D057
192.168.1.0     2.2.2.2         232         0x80000003 0x00A026
```

# OSPF Cost Calculation
The metric on the basis of which OSPF calculates the best route is bandwidth. There's a reference bandwidth of **100 Mbps** on the basis of which we judge the other bandwidths. Thus, the formula for cost is:

> Cost = Reference bandwidth/Interface bandwidth

In the topology below, the cost of going to R2 from R1 is:

> Cost = 100 Mbps/100 Mbps = 1

Similarly the cost of going from R2 to R3 is 1, and the cumulative cost of going from R1 to R3 becomes _1+1=2_. Thus, the total cost to get to PC2 is _1+1+1 = 3_ since we also have to add the cost of the exit interface on R3 to PC2 through the switch.

The cost of going from R1 to R3 directly through the 10Mbps link would be _100 Mbps/10 Mbps = 10_ and then to get to pc2, we have a cost of 1, making the cumulative cost _11_. Thus, the route through R2 is a better route.

## GigabitEthernet Links
Cost value has to be approximated to an integer, and so, if there's a 1Gbps = 1000Mbps link, the cost is:

> Cost = 100 Mbps/1 Gbps = 100/1000 = 0.1 ~= 1.

Since the value is a fraction, i.e., _0.1_, we have to round up to the next integer, i.e., 1. Now, if we adjust the values for the above topologies, and make the 100 Mbps links GigE links, and the 10 Mbps link into a 100 Mbps link, we see that the route via R2 now costs _3_ while the direct route from R1 to R3 and on to the PC costs _2_. This'll make OSPF think that the route directly to PC2 is the best one. We, of course know this isn't true since the GigE interfaces are much faster. The problem is we need a bigger reference bandwidth. We can set it using the `auto-cost reference-bandwidth <value>`, where _value is in Mbps_.

With a higher reference bandwidth of say, _100,000 Mbps (100Gbps)_, the new costs are:

> Cost of R1-R2-R3-Pc2  =   100+100+1000 = 1200
> Cost of R1-R3-Pc2     =   1000+1000 = 2000

Thus, the path through GigE connections shows up as the best path again, once the reference bandwidth has been adjusted. However, there is a problem with setting the reference bandwidth too high as well. The cost value is a _16-bit unsigned integer_ value, which means it has a range between _0_ and _65,535_. Thus, if divided by too small an actual bandwidth while the reference bandwidth is too high would mean an overflow, which would mean that the lower bandwidths would cost identical amounts. So, the cost has to be balanced.

# OSPF Cost Configuration
If we have a couple of routes to another network, one through a slower speed interface and another through a higher one, the one with the high speed interface will be chosen and the other ignored due to the cost. This also means no load balancing would be done. To prevent this, and to force load balancing, we can _intentionally_ provide the wrong information to OSPF by manually configuring the costs to be identical. Then OSPF will use both routes and load-balance.

For this, we go into an interface/sub-interface configuration mode and then use the command `ip ospf cost <value>`.

# Designated and Backup Designated Routers
Routers in an area need to form the same _view_ of the area, represented by a common link state database. For this, they need to form an adjacency within the area. The total number of possible adjacencies in a area is given by:

> Number of Total Possible Adjacencies = n * (n-1)/2

This is the equation for the total number of edges in a complete graph with `n` nodes. However, if all the routers in an area have an interface in the same subnet, instead of forming an adjacency with every router, a **Designated Router (_DR_)** and a **Backup Designated Router (_BDR_)**, used when the DR goes down, an be _elected_. This is needed because a full adjacency between a number of routers isn't very scalable. For example, if we have 6 routers, the total number of adjacencies will be _6*5*0.5 = 15_. For 10 routers, the number climbs to _45_! Instead we elect a DR and BDR and we only need to have adjacencies between every router on the subnet and the DR and the BDR. This makes the number of adjacencies to:

> Number of Adjacencies with DR & BDR = 2*(n-2)+1 = 2n - 3.

Thus, only a partial mesh is required instead of a full mesh of adjacencies. The order of a full mesh was _n^2_, but in the case of DR & BDRs, it becomes _n_. Thus, it scales linearly, instead of exponentially.

## OSPF Multicast Addresses
Given the lack of a full mesh of adjacencies, OSPF needs a couple of different multicast address. This is because it needs to selectively talk to all the routers participating in OSPF or just the DR and BDR. Some of the OSPF multicast IPv4 addresses are:
```
IPv4 Address    IPv6 Address    Use
============    ============    ======================================================
224.0.0.5       FF02::5         All OSPF Routers
224.0.0.6       FF02::6         All Designated and Backup Designated Routers (DR+BDRs)
```

## Designated Rourter election
The **hello protocol**, used to send _hello_ messages is used to elect both the DR and BDR. The router with the **highest OSPF priority value wins** the election. Every interface on a router has a _default OSPF priority value of 1_. The priority value can be anything between _0 and 255_. If the OSPF priority is _0_, it means the router won't even participate in the DR election. In the interface configuration mode, we can manually set the OSPF priority value with `ip ospf priority <value>`.

When we have a tie in the OSPF priority, the router with the highest **Router ID (RID)** wins. The Router ID can be configured manually in the _router configuration mode_ with the command `router-id <id>`. When not manually configured, the RID is auto-detected and set to the highest IP address of a (up/active) loopback interface. If a loopback interface (in up-state) is not found, it then uses the highest value non-loopback interface.

If there's an established OSPF adjacency between routers, if a new router is added to the network with a higher RID/Priority *after* the DR & BDR election, then it *does not* become the new DR. This is because there's no _pre-emption_ in OSPF. In case of Cisco routers, a **DR** is elected first and then a **BDR** is elected from the remaining candidates by the same criteria.

We can see the OSPF DR router using:
```
R1#sh ip ospf nei

Neighbor ID     Pri   State           Dead Time   Address         Interface
2.2.2.2           1   FULL/DR         00:00:31    10.0.0.2        GigabitEthernet0/1
```

We can also see the DR using the `show ip ospf interface <intID>`:
```
R1#sh ip ospf int g0/1
GigabitEthernet0/1 is up, line protocol is up
  Internet Address 10.0.0.1/24, Area 1, Attached via Network Statement
  Process ID 1, Router ID 1.1.1.1, Network Type BROADCAST, Cost: 1
  Topology-MTID    Cost    Disabled    Shutdown      Topology Name
        0           1         no          no            Base
  Transmit Delay is 1 sec, State BDR, Priority 1
  Designated Router (ID) 2.2.2.2, Interface address 10.0.0.2
  Backup Designated router (ID) 1.1.1.1, Interface address 10.0.0.1
  Timer intervals configured, Hello 10, Dead 40, Wait 40, Retransmit 5
    oob-resync timeout 40
    Hello due in 00:00:08
  Supports Link-local Signaling (LLS)
  Cisco NSF helper support enabled
  IETF NSF helper support enabled
  Index 1/2/2, flood queue length 0
  Next 0x0(0)/0x0(0)/0x0(0)
  Last flood scan length is 1, maximum is 1
  Last flood scan time is 1 msec, maximum is 2 msec
  Neighbor Count is 1, Adjacent neighbor count is 1
    Adjacent with neighbor 2.2.2.2  (Designated Router)
  Suppress hello for 0 neighbor(s)
```
This shows that R1 is the BDR due to the loopback IP `1.1.1.1` and R2 is the DR due to the _higher_ loopback IP `2.2.2.2`. Note that the only reason we can use these loopback interfaces outside the private-IP ranges is since we're using the `/32` mask, which makes it so that even if our network ever needs to reach the `2.0.0.0` network, it doesn't consider this the correct path. Further, we may also turn off the advertisement of the loopback interface networks and only assign the router id with it.

# OSPF Network Type
When we enable OSPF on an interface on a router, the interface will join one of several possible network types. We can take a look at the characteristics of these network types:

```
Network Type            DR/BDR Election     Default Hello Interval      Uses the neighbor command
====================    ===============     ======================      =========================
Broadcast               Yes                 10 sec                      No
Point-to-Point          No                  10 sec                      No
Non-Broadcast (NBMA)    Yes; DR only        30 sec                      Yes
Point-to-Multipoint     No                  30 sec                      No
```

## Broadcast Network
This is the case when multiple routers are connected to a single broadcast medium, for example, a L2 switch. In such scenarios, a DR and a BDR will be elected and there's no need to maintain a full-mesh of adjacencies. The default timer for the hello messages, i.e., the **hello interval**, is 10 seconds. If a neighbour doesn't receive a _hello_ message from a neighbour within _4*10=40_ seconds, called the **Dead interval**, it assumes the neighbour has gone down. Also, since we can dynamically discover neighbours, in this type of network, there's no need to statically configure a neighbour, with the `neighbor` command.

## Point-to-Point Network
This is the case when two routers are connected via a WAN, or maybe we're running the *Point-to-Point Protocol (PPP)* or HDLC, or even a frame-relay network. Since we only have two routers, we don't have to worry about DR and BDR elections. The hello interval is still 10 seconds and the dead interval is 4x hello interval = 40 seconds. Again, since there's only one other router, there's no need to statically set up the neighbour using the `neighbor` command.

## Non-Broadcast/Non-Broadcast Multi-Access (NBMA) Network
Let us consider the network is as shown, with a single router at the HQ connected to multiple other routers at different remote offices, all connected via a frame-relay network. All of them can be in the same subnet. However, it's impossible for the routers to dynamically discover the neighbours since it's *non-broadcast* and hence we don't have the luxury of a multicast to all OSPF routers. So, we have to statically configure a neighbour in the router's OSPF configuration mode.

There still has to be a DR, but the DR has to be strategically *selected* so that it's adjacent to every router (*R1 in this case*). So, we have to set the OSPF priority to _0_ on all routers but R1, such that it's the only one participating in the election. Further, a **BDR isn't possible** here since the topology won't allow it. Here the *hello interval* is 30 seconds, and the dead timer is 120 seconds. Given the need to statically set up neighbours, the `neighbor` command is required in NBMA.

## Point to Multipoint Network
While topologically this looks like a NBMA network, if the egress interface from R1 going to the Frame-relay service provider is set to use the *Point to Multipoint protocol*, each single link to every other router in the network will be treated like a discrete or separate point-to-point links. They'll all be in different subnets. Just like point-to-point networks, there's no need for DR and BDR elections. Each of these connections are called **Permanent Virtual Circuits (_PVC_s)** and every single one appear to the routers as their own separate point to point network.

The hello timer is 30 seconds and the dead timer is 120 seconds, and since each PVC is separate, there is no need to use the `neighbor` command to configure neighbours.

## Default Network Types
The type of technology used heavily dictates the network type that's available:
* For **Ethernet** networks, the network type is **Broadcast**.
* For **Frame-relay point-to-point sub-interfaces**, the default network type is **Point-to-Point**.
* For **Frame-relay physical interfaces**, the default network type is **NBMA**.
* For **Frame-relay multi-point sub-interfaces**, the default network type is **NBMA**.

The network type for an interface can be seen by using the `show ip ospf interface` command. We can also change the network type by entering the interface/sub-interface configuration mode and then using the command: `ip ospf network <netType>`. However, if we manually change the network type, we should also change the network type of the far-end interface so that they can agree upon whether to use a DR/BDR, as well as the hello and dead timers.

# OSPF Timers
OSPF uses a couple of timers/intervals, namely, the **hello interval** and **dead interval**. The hello interval is the time period (in sec) after which an OSPF enabled interface on the router sends out a hello message. Similarly, the dead timer is the amount of time that a router will wait to receive a hello message from an adjacent router, before considering it to be down. The dead timer, by default, is 4 times the hello timer.

In the following topology, if we see **R2 e0/0**, it's a broadcast interface, with the hello timer set to 10 secs and the dead timer set to 40 secs:
```
R2#sh ip ospf int e0/0
Ethernet0/0 is up, line protocol is up
  Internet Address 10.0.0.2/24, Area 1, Attached via Network Statement
  Process ID 1, Router ID 2.2.2.2, Network Type BROADCAST, Cost: 10
  Topology-MTID    Cost    Disabled    Shutdown      Topology Name
        0           10        no          no            Base
  Transmit Delay is 1 sec, State DR, Priority 1
  Designated Router (ID) 2.2.2.2, Interface address 10.0.0.2
  Backup Designated router (ID) 1.1.1.1, Interface address 10.0.0.1
  Timer intervals configured, Hello 10, Dead 40, Wait 40, Retransmit 5
    oob-resync timeout 40
    Hello due in 00:00:04
  Supports Link-local Signaling (LLS)
  Cisco NSF helper support enabled
  IETF NSF helper support enabled
  Index 1/1/1, flood queue length 0
  Next 0x0(0)/0x0(0)/0x0(0)
  Last flood scan length is 2, maximum is 2
  Last flood scan time is 0 msec, maximum is 0 msec
  Neighbor Count is 1, Adjacent neighbor count is 1
    Adjacent with neighbor 1.1.1.1  (Backup Designated Router)
  Suppress hello for 0 neighbor(s)
```

However, for the Serial sub-interface, **R1 S1/0.103**, which is a _point-to-point_ interface, we have the same timers:
```
R2#sh ip ospf int s1/0.103
Serial1/0.103 is up, line protocol is up
  Internet Address 192.168.0.5/30, Area 0, Attached via Network Statement
  Process ID 1, Router ID 2.2.2.2, Network Type POINT_TO_POINT, Cost: 64
  Topology-MTID    Cost    Disabled    Shutdown      Topology Name
        0           64        no          no            Base
  Transmit Delay is 1 sec, State POINT_TO_POINT
  Timer intervals configured, Hello 10, Dead 40, Wait 40, Retransmit 5
    oob-resync timeout 40
    Hello due in 00:00:09
  Supports Link-local Signaling (LLS)
  Cisco NSF helper support enabled
  IETF NSF helper support enabled
  Index 1/2/3, flood queue length 0
  Next 0x0(0)/0x0(0)/0x0(0)
  Last flood scan length is 1, maximum is 1
  Last flood scan time is 0 msec, maximum is 0 msec
  Neighbor Count is 1, Adjacent neighbor count is 1
    Adjacent with neighbor 4.4.4.4
  Suppress hello for 0 neighbor(s)
```

If we were to change the network type on these two - the adjacencies would be brought down and the hello and dead timers would also change:
```
R2(config)#int e0/0
R2(config-if)#ip ospf network non-broadcast
*Dec 27 11:34:56.120: %OSPF-5-ADJCHG: Process 1, Nbr 1.1.1.1 on Ethernet0/0 from FULL to DOWN, Neighbor Down: Interface down or detached
R2(config-if)#int s1/0.102
R2(config-subif)#ip ospf network non-broadcast
*Dec 27 11:35:32.720: %OSPF-5-ADJCHG: Process 1, Nbr 3.3.3.3 on Serial1/0.102 from FULL to DOWN, Neighbor Down: Interface down or detached
R2(config-subif)#end
R2#sh ip ospf int e0/0 | i Timer
  Timer intervals configured, Hello 30, Dead 120, Wait 120, Retransmit 5
R2#sh ip ospf int s1/0.103 | i Timer
  Timer intervals configured, Hello 10, Dead 40, Wait 40, Retransmit 5
```

On router R3, after the adjacency goes down with R2:
```
R3#sh ip ospf nei

Neighbor ID     Pri   State           Dead Time   Address         Interface
4.4.4.4           0   FULL/  -        00:00:36    192.168.0.10    Serial1/0.203
2.2.2.2           0   FULL/  -        00:00:38    192.168.0.1     Serial1/0.201
R3#
*Dec 27 11:36:09.873: %OSPF-5-ADJCHG: Process 1, Nbr 2.2.2.2 on Serial1/0.201 from FULL to DOWN, Neighbor Down: Dead timer expired
R3#sh ip ospf nei

Neighbor ID     Pri   State           Dead Time   Address         Interface
4.4.4.4           0   FULL/  -        00:00:33    192.168.0.10    Serial1/0.203
```

However, if we were to manually set the timers to match, the adjacency would come back up:
```
R3(config)#int s1/0.201
R3(config-subif)#ip ospf hello 30
R3(config-subif)#end
R3#sh ip ospf int s1/0.
*Dec 27 11:42:13.234: %OSPF-4-NET_TYPE_MISMATCH: Received Hello from 2.2.2.2 on Serial1/0.201 indicating a  potential
             network type mismatch
*Dec 27 11:42:13.439: %OSPF-5-ADJCHG: Process 1, Nbr 2.2.2.2 on Serial1/0.201 from LOADING to FULL, Loading Done
R3#sh ip ospf int s1/0.201
Serial1/0.201 is up, line protocol is up
  Internet Address 192.168.0.2/30, Area 0, Attached via Network Statement
  Process ID 1, Router ID 3.3.3.3, Network Type POINT_TO_POINT, Cost: 64
  Topology-MTID    Cost    Disabled    Shutdown      Topology Name
        0           64        no          no            Base
  Transmit Delay is 1 sec, State POINT_TO_POINT
  Timer intervals configured, Hello 30, Dead 120, Wait 120, Retransmit 5
    oob-resync timeout 120
    Hello due in 00:00:15
  Supports Link-local Signaling (LLS)
  Cisco NSF helper support enabled
  IETF NSF helper support enabled
  Index 1/2/2, flood queue length 0
  Next 0x0(0)/0x0(0)/0x0(0)
  Last flood scan length is 1, maximum is 1
  Last flood scan time is 0 msec, maximum is 0 msec
  Neighbor Count is 1, Adjacent neighbor count is 1
    Adjacent with neighbor 2.2.2.2
  Suppress hello for 0 neighbor(s)
```
Now, even though the network type is set to point-to-point, the adjacency forms since the timers match up. We can even see the neighbourship using:
```
R3#sh ip ospf nei

Neighbor ID     Pri   State           Dead Time   Address         Interface
4.4.4.4           0   FULL/  -        00:00:30    192.168.0.10    Serial1/0.203
2.2.2.2           0   FULL/  -        00:01:58    192.168.0.1     Serial1/0.201
```

However, on closer inspection, we see that we're not really learning routes from R2:
```
R3#sh ip route
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
       a - application route
       + - replicated route, % - next hop override

Gateway of last resort is not set

      3.0.0.0/32 is subnetted, 1 subnets
C        3.3.3.3 is directly connected, Loopback1
      10.0.0.0/24 is subnetted, 1 subnets
O IA     10.0.0.0 [110/138] via 192.168.0.10, 00:11:28, Serial1/0.203
      172.16.0.0/16 is variably subnetted, 3 subnets, 2 masks
C        172.16.1.0/24 is directly connected, Ethernet0/0
L        172.16.1.1/32 is directly connected, Ethernet0/0
O        172.16.2.0/24 [110/74] via 192.168.0.10, 00:29:17, Serial1/0.203
      192.168.0.0/24 is variably subnetted, 5 subnets, 2 masks
C        192.168.0.0/30 is directly connected, Serial1/0.201
L        192.168.0.2/32 is directly connected, Serial1/0.201
O        192.168.0.4/30 [110/128] via 192.168.0.10, 00:29:17, Serial1/0.203
C        192.168.0.8/30 is directly connected, Serial1/0.203
L        192.168.0.9/32 is directly connected, Serial1/0.203
```
The routes for the `192.168.1.1` network that's beyond R2 are missing. To fix this, the network type between neighbours must also match. So, we'd have to change the network type to NBMA on R3 and R4 to match up.

# OSPF Passive interfaces
Let us consider that in the topology below, the `192.168.1.0/24` network only has end users connected and doesn't have any routers connected. Thus, there's no need for us to be sending out OSPF adjacency messages on that interface of R1, i.e., **R1 e0/0**. We still want that network to be advertised out the other interfaces. Plus, if anyone were to plug in their own router into that network, it would be a security concern if authentication isn't enabled. Thus, we can turn it into a passive interface with the `passive interface e 0/0` command:
```
R1(config)#router ospf 1
R1(config-router)#passive-interface e 0/0
```

Now, we'll still be advertising the network:
```
R1#sh ip ospf int br
Interface    PID   Area            IP Address/Mask    Cost  State Nbrs F/C
Et0/0        1     1               192.168.1.1/24     10    DR    0/0
Et0/1        1     1               10.0.0.1/24        10    DR    1/1
```

However, we won't be using it to learn routes:
```
R1#sh ip proto
...
Routing Protocol is "ospf 1"
  Outgoing update filter list for all interfaces is not set
  Incoming update filter list for all interfaces is not set
  Router ID 1.1.1.1
  Number of areas in this router is 1. 1 normal 0 stub 0 nssa
  Maximum path: 4
  Routing for Networks:
    10.0.0.0 0.0.0.255 area 1
    192.168.1.0 0.0.0.255 area 1
  Passive Interface(s):
    Ethernet0/0
  Routing Information Sources:
    Gateway         Distance      Last Update
    2.2.2.2              110      00:15:03
  Distance: (default is 110)
```

Note, however, that if an interface connects us to an *adjacent* router, it must **not be passive** for the adjacencies to form. A good security practice is to first convert all the interfaces to passive interfaces using the `passive-interface default` command, and then manually turning the required interfaces into active interfaces when needed:
```
R1(config)#router ospf 1
R1(config-router)#passive-interface default
*Dec 27 12:23:33.209: %OSPF-5-ADJCHG: Process 1, Nbr 2.2.2.2 on Ethernet0/1 from FULL to DOWN, Neighbor Down: Interface down or detached
R1(config-router)#do sh ip proto | s Passive
  Passive Interface(s):
    Ethernet0/0
    Ethernet0/1
    Ethernet0/2
    Ethernet0/3
    Serial1/0
    Serial1/1
    Serial1/2
    Serial1/3
    Loopback1
    RG-AR-IF-INPUT1
     VoIP-Null0
    VoIP-Null0

R1(config-router)#no passive-interface e0/1
*Dec 27 12:24:58.030: %OSPF-5-ADJCHG: Process 1, Nbr 2.2.2.2 on Ethernet0/1 from LOADING to FULL, Loading Done
```

# OSPFv3 configuration
We need to ensure a few features are turned on in each of the routers for IPv6 and OSPFv3 to operate properly. The first is IPv6 Unicast routing and next, IPv6 Cisco Express Forwarding (CEF). Thus, on each router, we execute:
```
ipv6 unicast-routing
ipv6 cef
```
Next, we set up the IPv6 addresses as per the network diagram.
```
R1(config)#int e0/0
R1(config-if)#ipv6 addr 2000:11AA::1/64
R1(config-if)#int e0/0
R1(config-if)#no shut
*Dec 27 13:40:53.720: %LINK-3-UPDOWN: Interface Ethernet0/0, changed state to up
*Dec 27 13:40:54.724: %LINEPROTO-5-UPDOWN: Line protocol on Interface Ethernet0/0, changed state to up
R1(config-if)#int e0/1
R1(config-if)#ipv6 addr 2000:1122::1/64
R1(config-if)#no shut
*Dec 27 13:40:42.750: %LINK-3-UPDOWN: Interface Ethernet0/1, changed state to up
*Dec 27 13:40:43.756: %LINEPROTO-5-UPDOWN: Line protocol on Interface Ethernet0/1, changed state to up

R2(config)#int e0/0
R2(config-if)#ipv6 addr 2000:1122::2/64
R2(config-if)#no shut
*Dec 27 13:48:33.396: %LINK-3-UPDOWN: Interface Ethernet0/0, changed state to up
*Dec 27 13:48:34.402: %LINEPROTO-5-UPDOWN: Line protocol on Interface Ethernet0/0, changed state to up
R2(config-if)#int s1/0
R2(config-if)#ipv6 addr 2000:2233::2/64
R2(config-if)#no shut
*Dec 27 13:49:10.393: %LINK-3-UPDOWN: Interface Serial1/0, changed state to up
*Dec 27 13:49:11.402: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/0, changed state to up

R3(config)#int s1/0
R3(config-if)#ipv6 addr 2000:2233::3/64
R3(config-if)#no shut
*Dec 27 13:51:47.894: %LINK-3-UPDOWN: Interface Serial1/0, changed state to up
*Dec 27 13:51:48.897: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/0, changed state to up
R3(config-if)#int e0/0
R3(config-if)#ipv6 addr 2000:33AA::3/64
R3(config-if)#no shut
*Dec 27 13:52:22.939: %LINK-3-UPDOWN: Interface Ethernet0/0, changed state to up
*Dec 27 13:52:23.947: %LINEPROTO-5-UPDOWN: Line protocol on Interface Ethernet0/0, changed state to up
```

OSPF uses the IPv4 loop back address as the router IDs, and so, we can even manually set them up like:
```
R1(config)#ipv6 router ospf 1
R1(config-rtr)#router-id 1.1.1.1

R2(config)#ipv6 router ospf 1
R2(config-rtr)#router-id 2.2.2.2

R1(config)#ipv6 router ospf 1
R3(config-rtr)#router-id 3.3.3.3
```
Note, if the loopback interfaces are present, there's no need to manually define the router-id. The OSPF process will auto-assign it to the highest loopback interface address that's currently up.

Unlike OSPFv2 with IPv4, we don't define networks such that any interface that falls within the range can participate in OSPF, but instead directly define which interfaces participate in OSPF. This is done via the interface configuration mode. In out topology all interfaces on R1 belong to _area 0_ and all interfaces on R3 belong to _area 1_ while the interfaces on R2 is shared by both areas since it's the ABR.
```
R1(config)#int e0/0
R1(config-if)#ipv6 ospf 1 area 0
R1(config-if)#int e0/1
R1(config-if)#ipv6 ospf 1 area 0

R3(config)#int e0/0
R3(config-if)#ipv6 ospf 1 area 0
R3(config-if)#int s1/0
R3(config-if)#ipv6 ospf 1 area 0

R2(config)#int e0/0
R2(config-if)#ipv6 ospf 1 area 0
*Dec 28 11:29:04.480: %OSPFv3-5-ADJCHG: Process 1, Nbr 1.1.1.1 on Ethernet0/0 from LOADING to FULL, Loading Done
R2(config-if)#int s1/0
R2(config-if)#ipv6 ospf 1 area 1
*Dec 28 11:29:22.385: %OSPFv3-5-ADJCHG: Process 1, Nbr 3.3.3.3 on Serial1/0 from LOADING to FULL, Loading Done
```

# OSPFv3 Verification
The command for the verification of IPv6 networking are identical to their IPv4 couterparts. For example, we have `show ipv6 interfaces brief` instead of `show ip interfaces brief`. and so on:
```
R1#sh ipv6 int br
Ethernet0/0            [up/up]
    FE80::A8BB:CCFF:FE00:100
    2000:11AA::1
Ethernet0/1            [up/up]
    FE80::A8BB:CCFF:FE00:110
    2000:1122::1
Ethernet0/2            [administratively down/down]
    unassigned
Ethernet0/3            [administratively down/down]
    unassigned
Serial1/0              [administratively down/down]
    unassigned
Serial1/1              [administratively down/down]
    unassigned
Serial1/2              [administratively down/down]
    unassigned
Serial1/3              [administratively down/down]
    unassigned
Loopback1              [up/up]
    unassigned
```

The command to show the IPv6 routing table is:
```
R1#sh ipv6 route
IPv6 Routing Table - default - 7 entries
Codes: C - Connected, L - Local, S - Static, U - Per-user Static route
       B - BGP, HA - Home Agent, MR - Mobile Router, R - RIP
       H - NHRP, I1 - ISIS L1, I2 - ISIS L2, IA - ISIS interarea
       IS - ISIS summary, D - EIGRP, EX - EIGRP external, NM - NEMO
       ND - ND Default, NDp - ND Prefix, DCE - Destination, NDr - Redirect
       O - OSPF Intra, OI - OSPF Inter, OE1 - OSPF ext 1, OE2 - OSPF ext 2
       ON1 - OSPF NSSA ext 1, ON2 - OSPF NSSA ext 2, la - LISP alt
       lr - LISP site-registrations, ld - LISP dyn-eid, a - Application
C   2000:1122::/64 [0/0]
     via Ethernet0/1, directly connected
L   2000:1122::1/128 [0/0]
     via Ethernet0/1, receive
C   2000:11AA::/64 [0/0]
     via Ethernet0/0, directly connected
L   2000:11AA::1/128 [0/0]
     via Ethernet0/0, receive
OI  2000:2233::/64 [110/74]
     via FE80::A8BB:CCFF:FE00:200, Ethernet0/1
OI  2000:33AA::/64 [110/84]
     via FE80::A8BB:CCFF:FE00:200, Ethernet0/1
L   FF00::/8 [0/0]
     via Null0, receive
```
Here, the routes marked with `O` are learnt via OSPF and those with `OI` were also learnt via OSPF, but from another area (in this case _area 1_).

Ping and traceroute also work identically:
```
R1#ping 2000:33AA::3
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 2000:33AA::3, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 10/13/28 ms
R1#traceroute 2000:33AA::3
Type escape sequence to abort.
Tracing the route to 2000:33AA::3

  1 2000:1122::2 1 msec 1 msec 0 msec
  2 2000:2233::3 11 msec 10 msec 10 msec
```

We can also see the details of OSPF running on the router. First to see the adjacencies, we use `show ipv6 ospf neighbours` and then to see the OSPF details of a particular interface, we use `show ipv6 ospf interface <interfaceID>`:
```
R2#sh ipv6 ospf nei

            OSPFv3 Router with ID (2.2.2.2) (Process ID 1)

Neighbor ID     Pri   State           Dead Time   Interface ID    Interface
1.1.1.1           1   FULL/BDR        00:00:35    4               Ethernet0/0
3.3.3.3           0   FULL/  -        00:00:35    7               Serial1/0
R2#sh ipv6 ospf int s1/0
Serial1/0 is up, line protocol is up
  Link Local Address FE80::A8BB:CCFF:FE00:200, Interface ID 7
  Area 1, Process ID 1, Instance ID 0, Router ID 2.2.2.2
  Network Type POINT_TO_POINT, Cost: 64
  Transmit Delay is 1 sec, State POINT_TO_POINT
  Timer intervals configured, Hello 10, Dead 40, Wait 40, Retransmit 5
    Hello due in 00:00:08
  Graceful restart helper support enabled
  Index 1/1/2, flood queue length 0
  Next 0x0(0)/0x0(0)/0x0(0)
  Last flood scan length is 1, maximum is 1
  Last flood scan time is 0 msec, maximum is 0 msec
  Neighbor Count is 1, Adjacent neighbor count is 1
    Adjacent with neighbor 3.3.3.3
  Suppress hello for 0 neighbor(s)
```
The above also gives us the hello and dead intervals as well as the router ID and the interface's network type.

The IPv6 protocols command is `show ipv6 protocols`:
```
R2#sh ipv6 proto
IPv6 Routing Protocol is "connected"
IPv6 Routing Protocol is "application"
IPv6 Routing Protocol is "ND"
IPv6 Routing Protocol is "ospf 1"
  Router ID 2.2.2.2
  Area border router
  Number of areas: 2 normal, 0 stub, 0 nssa
  Interfaces (Area 0):
    Ethernet0/0
  Interfaces (Area 1):
    Serial1/0
  Redistribution:
    None
```

The IPv6 CEF that was enabled earlier maintains a FIB just like in IPv4 CEF. This can be viewed with: `show ipv6 cef`:
```
R2#sh ipv6 cef
::/0
  no route
::/127
  discard
2000:1122::/64
  attached to Ethernet0/0
2000:1122::1/128
  attached to Ethernet0/0
2000:1122::2/128
  receive for Ethernet0/0
2000:11AA::/64
  nexthop FE80::A8BB:CCFF:FE00:110 Ethernet0/0
2000:2233::/64
  attached to Serial1/0
2000:2233::2/128
  receive for Serial1/0
2000:33AA::/64
  nexthop FE80::A8BB:CCFF:FE00:300 Serial1/0
FE80::/10
  receive for Null0
FF00::/8
  multicast
```
The link local addresses (`FE80::`) are those for the next hop neighbours in the forwarding process.

# OSPF Troubleshooting Exercise 1
Let us consider we have the topology below. The Routers are all configured for OSPF on process 1, but for some reason, R2 and R3 are unable to form an adjacency while R1 and R2 have already formed one:
```
R1#sh ip ospf nei

Neighbor ID     Pri   State           Dead Time   Address         Interface
2.2.2.2           1   FULL/BDR        00:00:34    10.1.1.2        Ethernet0/1

R2#sh ip ospf nei

Neighbor ID     Pri   State           Dead Time   Address         Interface
1.1.1.1           1   FULL/DR         00:00:33    10.1.1.1        Ethernet0/0
3.3.3.3           0   EXCHANGE/  -    00:00:37    10.1.1.6        Serial1/0

R3#sh ip ospf nei

Neighbor ID     Pri   State           Dead Time   Address         Interface
2.2.2.2           0   EXSTART/  -     00:00:38    10.1.1.5        Serial1/0
```
The problem is that R2 and R3 are unable to form an adjacency, as demonstrated by R2 being stuck in the exchange state while R3 is still trying to start the exchange. Given that both routers are connected via a point-to-point network type interface, the DR/BDR election won't occur. The ExStart state shows that the primary/secondary router election didn't go well. This might be due to a settings mismatch between the two routers connected to the `10.1.1.4/30` network.

We can check the OSPF settings on R3 using:
```
R3#sh ip proto         
*** IP Routing is NSF aware ***
...
Routing Protocol is "ospf 1"
  Outgoing update filter list for all interfaces is not set
  Incoming update filter list for all interfaces is not set
  Router ID 3.3.3.3
  Number of areas in this router is 1. 1 normal 0 stub 0 nssa
  Maximum path: 4
  Routing for Networks:
    3.3.3.3 0.0.0.0 area 1
    10.1.1.4 0.0.0.3 area 1
    172.16.1.0 0.0.0.255 area 1
  Routing Information Sources:
    Gateway         Distance      Last Update
    2.2.2.2              110      00:18:02
  Distance: (default is 110)
```
We can see we're advertising all the right networks, and all the right information sources for routing are being used. We can also see the interface config for OSPF that connect us to `2.2.2.2`:
```
R3#sh ip ospf int s1/0
Serial1/0 is up, line protocol is up
  Internet Address 10.1.1.6/30, Area 1, Attached via Network Statement
  Process ID 1, Router ID 3.3.3.3, Network Type POINT_TO_POINT, Cost: 64
  Topology-MTID    Cost    Disabled    Shutdown      Topology Name
        0           64        no          no            Base
  Transmit Delay is 1 sec, State POINT_TO_POINT
  Timer intervals configured, Hello 10, Dead 40, Wait 40, Retransmit 5
    oob-resync timeout 40
    Hello due in 00:00:07
  Supports Link-local Signaling (LLS)
  Cisco NSF helper support enabled
  IETF NSF helper support enabled
  Index 1/2/2, flood queue length 0
  Next 0x0(0)/0x0(0)/0x0(0)
  Last flood scan length is 1, maximum is 1
  Last flood scan time is 0 msec, maximum is 0 msec
  Neighbor Count is 1, Adjacent neighbor count is 0
  Suppress hello for 0 neighbor(s)
```

We can now check the settings on R3 to see if they match:
```
R2#sh ip proto
*** IP Routing is NSF aware ***

Routing Protocol is "application"
  Sending updates every 0 seconds
  Invalid after 0 seconds, hold down 0, flushed after 0
  Outgoing update filter list for all interfaces is not set
  Incoming update filter list for all interfaces is not set
  Maximum path: 32
  Routing for Networks:
  Routing Information Sources:
    Gateway         Distance      Last Update
  Distance: (default is 4)

Routing Protocol is "ospf 1"
  Outgoing update filter list for all interfaces is not set
  Incoming update filter list for all interfaces is not set
  Router ID 2.2.2.2
  It is an area border router
  Number of areas in this router is 2. 2 normal 0 stub 0 nssa
  Maximum path: 4
  Routing for Networks:
    2.2.2.2 0.0.0.0 area 1
    10.1.1.0 0.0.0.3 area 0
    10.1.1.4 0.0.0.3 area 1
  Routing Information Sources:
    Gateway         Distance      Last Update
    3.3.3.3              110      00:22:29
    1.1.1.1              110      00:23:56
  Distance: (default is 110)

R2#sh ip ospf int s1/0
  Serial1/0 is up, line protocol is up
    Internet Address 10.1.1.5/30, Area 1, Attached via Network Statement
    Process ID 1, Router ID 2.2.2.2, Network Type POINT_TO_POINT, Cost: 64
    Topology-MTID    Cost    Disabled    Shutdown      Topology Name
          0           64        no          no            Base
    Transmit Delay is 1 sec, State POINT_TO_POINT
    Timer intervals configured, Hello 10, Dead 40, Wait 40, Retransmit 5
      oob-resync timeout 40
      Hello due in 00:00:07
    Supports Link-local Signaling (LLS)
    Cisco NSF helper support enabled
    IETF NSF helper support enabled
    Index 1/1/2, flood queue length 0
    Next 0x0(0)/0x0(0)/0x0(0)
    Last flood scan length is 1, maximum is 1
    Last flood scan time is 0 msec, maximum is 0 msec
    Neighbor Count is 1, Adjacent neighbor count is 0
    Suppress hello for 0 neighbor(s)
```
We can see that the area, network type and timer intervals all match.

Under such circumstances, we can turn on some debugging to try and understand what's going on. The debugging options for OSPF can be seen with:
```
R2#debug ip ospf ?
  <1-65535>       Process ID number
  adj             OSPF adjacency
  capability      OSPF capability
  database-timer  OSPF database timer
  demand-circuit  OSPF demand-circuit negotiation
  events          OSPF miscellaneous events
  flood           OSPF flooding
  ha              OSPF high availability
  hello           OSPF hello
  lsa-generation  OSPF LSA generation
  monitor         OSPF SPF monitoring
  mpls            OSPF MPLS
  nsf             OSPF non-stop forwarding
  nsr             OSPF non-stop routing
  packet          OSPF received packets
  rib             OSPF RIB
  scheduler       OSPF process scheduling
  snmp            OSPF snmp
  spf             OSPF SPF
```

Let's start by debugging the `hello` messages:
```
R2#debug ip ospf hello
OSPF hello debugging is on
*Dec 28 12:56:59.074: OSPF-1 HELLO Se1/0: Send hello to 224.0.0.5 area 1 from 10.1.1.5
*Dec 28 12:57:02.609: OSPF-1 HELLO Et0/0: Rcv hello from 1.1.1.1 area 0 10.1.1.1
*Dec 28 12:57:04.098: OSPF-1 HELLO Et0/0: Send hello to 224.0.0.5 area 0 from 10.1.1.2
*Dec 28 12:57:06.166: OSPF-1 HELLO Se1/0: Rcv hello from 3.3.3.3 area 1 10.1.1.6
*Dec 28 12:57:09.028: OSPF-1 HELLO Se1/0: Send hello to 224.0.0.5 area 1 from 10.1.1.5
*Dec 28 12:57:11.921: OSPF-1 HELLO Et0/0: Rcv hello from 1.1.1.1 area 0 10.1.1.1
*Dec 28 12:57:13.729: OSPF-1 HELLO Et0/0: Send hello to 224.0.0.5 area 0 from 10.1.1.2
*Dec 28 12:57:15.481: OSPF-1 HELLO Se1/0: Rcv hello from 3.3.3.3 area 1 10.1.1.6
R2#u all
All possible debugging has been turned off
```
We can see that the router can send and receive hello messages from either interfaces.

We can now try debugging the packet information:
```
R2#debug ip ospf packet
OSPF packet debugging is on
R2#
*Dec 28 13:01:51.226: OSPF-1 PAK  : Se1/0:  IN: 10.1.1.6->224.0.0.5: ver:2 type:2 len:32 rid:3.3.3.3 area:0.0.0.1 chksum:7B3E auth:0
*Dec 28 13:01:51.226: OSPF-1 PAK  : Se1/0: OUT: 10.1.1.5->224.0.0.5: ver:2 type:2 len:132 rid:2.2.2.2 area:0.0.0.1 chksum:E458 auth:0
R2#
*Dec 28 13:01:55.286: OSPF-1 PAK  : Se1/0:  IN: 10.1.1.6->224.0.0.5: ver:2 type:1 len:48 rid:3.3.3.3 area:0.0.0.1 chksum:E193 auth:0
*Dec 28 13:01:55.524: OSPF-1 PAK  : Se1/0: OUT: 10.1.1.5->224.0.0.5: ver:2 type:1 len:48 rid:2.2.2.2 area:0.0.0.1 chksum:E193 auth:0
*Dec 28 13:01:55.906: OSPF-1 PAK  : Se1/0:  IN: 10.1.1.6->224.0.0.5: ver:2 type:2 len:32 rid:3.3.3.3 area:0.0.0.1 chksum:7B3E auth:0
*Dec 28 13:01:55.906: OSPF-1 PAK  : Se1/0: OUT: 10.1.1.5->224.0.0.5: ver:2 type:2 len:132 rid:2.2.2.2 area:0.0.0.1 chksum:E442 auth:0
R2#u all
All possible debugging has been turned off
```
We can see RID information being exchanged, but nothing useful.

Now, we can try checking the adjacency, since that's where the issue seems to reside:
```
R2#debug ip ospf adj
OSPF adjacency debugging is on
R2#
*Dec 28 13:04:19.802: OSPF-1 ADJ   Se1/0: Rcv DBD from 3.3.3.3 seq 0x44C opt 0x52 flag 0x7 len 32  mtu 1480 state EXCHANGE
*Dec 28 13:04:19.802: OSPF-1 ADJ   Se1/0: Nbr 3.3.3.3 has smaller interface MTU
*Dec 28 13:04:19.802: OSPF-1 ADJ   Se1/0: Send DBD to 3.3.3.3 seq 0x44C opt 0x52 flag 0x2 len 132
R2#
*Dec 28 13:04:24.411: OSPF-1 ADJ   Se1/0: Rcv DBD from 3.3.3.3 seq 0x44C opt 0x52 flag 0x7 len 32  mtu 1480 state EXCHANGE
*Dec 28 13:04:24.411: OSPF-1 ADJ   Se1/0: Nbr 3.3.3.3 has smaller interface MTU
*Dec 28 13:04:24.411: OSPF-1 ADJ   Se1/0: Send DBD to 3.3.3.3 seq 0x44C opt 0x52 flag 0x2 len 132
R2#u all
All possible debugging has been turned off
```
It now tells us that R3 has a smaller MTU size. Now we have somewhere to start.

First we check the MTU size on the interface **R2 S1/0** and then compare it with **R3 S1/0** to see if they match:
```
R2#sh int s1/0 | i MTU
  MTU 1500 bytes, BW 1544 Kbit/sec, DLY 20000 usec,
R3#sh int s1/0 | i MTU
  MTU 1500 bytes, BW 1544 Kbit/sec, DLY 20000 usec,
```
We can see they match, but that's only the MTU for the interface at L2.

We can see the MTU settings for IP (L3) with:
```
R2#sh ip int s1/0 | i MTU     
  MTU is 1500 bytes
R3#sh ip int s1/0 | i MTU
  MTU is 1480 bytes
```
We can see that there's a mismatch. The value of `1480` as the MTU isn't a normal value. We have to check the running config. Alternatively, we could've directly checked the running config as soon as we saw the MTU debug warning:
```
R3#sh run | s Serial1/0
interface Serial1/0
 description Conn to R2
 ip address 10.1.1.6 255.255.255.252
 ip mtu 1480
 serial restart-delay 0
```
We see that the MTU has been set manually to a non-standard value of `1480`. The MTUs is one of the parameters that should match on every interface on the same subnet for an adjacency to be formed. If this were set to match that of R2 (`1500B`, default), then the adjacency should form. We can set it back to default using the `default ip mtu` command:
```
R3(config)#int S1/0
R3(config-if)#do ping 1.1.1.1
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 1.1.1.1, timeout is 2 seconds:
..
Success rate is 0 percent (0/2)
R3(config-if)#default ip mtu
*Dec 28 13:14:19.422: %OSPF-5-ADJCHG: Process 1, Nbr 2.2.2.2 on Serial1/0 from LOADING to FULL, Loading Done
R3(config-if)#do ping 1.1.1.1
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 1.1.1.1, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 11/11/12 ms
```

We can further see that the adjacency is now in a `FULL` state in the neighbour table on either router:
```
R2#sh ip ospf nei

Neighbor ID     Pri   State           Dead Time   Address         Interface
1.1.1.1           1   FULL/DR         00:00:32    10.1.1.1        Ethernet0/0
3.3.3.3           0   FULL/  -        00:00:37    10.1.1.6        Serial1/0

R3#sh ip ospf nei

Neighbor ID     Pri   State           Dead Time   Address         Interface
2.2.2.2           0   FULL/  -        00:00:39    10.1.1.5        Serial1/0
```

Finally, we can see that the inter-area routes are being learnt, which would indicate the adjacency is up and OSPF is working:
```
R3#sh ip route
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
       a - application route
       + - replicated route, % - next hop override

Gateway of last resort is not set

      1.0.0.0/32 is subnetted, 1 subnets
O IA     1.1.1.1 [110/75] via 10.1.1.5, 00:05:15, Serial1/0
      2.0.0.0/32 is subnetted, 1 subnets
O        2.2.2.2 [110/65] via 10.1.1.5, 00:05:15, Serial1/0
      3.0.0.0/32 is subnetted, 1 subnets
C        3.3.3.3 is directly connected, Loopback1
      10.0.0.0/8 is variably subnetted, 3 subnets, 2 masks
O IA     10.1.1.0/30 [110/74] via 10.1.1.5, 00:05:15, Serial1/0
C        10.1.1.4/30 is directly connected, Serial1/0
L        10.1.1.6/32 is directly connected, Serial1/0
      172.16.0.0/16 is variably subnetted, 2 subnets, 2 masks
C        172.16.1.0/24 is directly connected, Ethernet0/0
L        172.16.1.1/32 is directly connected, Ethernet0/0
O IA  192.168.1.0/24 [110/84] via 10.1.1.5, 00:05:15, Serial1/0
```

# OSPF Troubleshooting Exercise 2
In the topology shown below, where we have a redundant link between R2 and R3 - one with an Ethernet link and another a Serial link, we can see that we have two adjacencies between R2 (`2.2.2.2`) and R3 (`3.3.3.3`):
```
R3#sh ip ospf nei

Neighbor ID     Pri   State           Dead Time   Address         Interface
2.2.2.2           1   FULL/DR         00:00:31    10.1.1.9        Ethernet0/1
2.2.2.2           0   FULL/  -        00:00:39    10.1.1.5        Serial1/0
```

If we check the routing, we see:
```
R3#sh ip route
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
       a - application route
       + - replicated route, % - next hop override

Gateway of last resort is not set

      1.0.0.0/32 is subnetted, 1 subnets
O IA     1.1.1.1 [110/21] via 10.1.1.9, 00:18:20, Ethernet0/1
                 [110/21] via 10.1.1.5, 00:00:55, Serial1/0
      2.0.0.0/32 is subnetted, 1 subnets
O        2.2.2.2 [110/11] via 10.1.1.9, 00:18:20, Ethernet0/1
                 [110/11] via 10.1.1.5, 00:00:55, Serial1/0
      3.0.0.0/32 is subnetted, 1 subnets
C        3.3.3.3 is directly connected, Loopback1
      10.0.0.0/8 is variably subnetted, 5 subnets, 2 masks
O IA     10.1.1.0/30 [110/20] via 10.1.1.9, 00:18:20, Ethernet0/1
                     [110/20] via 10.1.1.5, 00:00:55, Serial1/0
C        10.1.1.4/30 is directly connected, Serial1/0
L        10.1.1.6/32 is directly connected, Serial1/0
C        10.1.1.8/30 is directly connected, Ethernet0/1
L        10.1.1.10/32 is directly connected, Ethernet0/1
      172.16.0.0/16 is variably subnetted, 2 subnets, 2 masks
C        172.16.1.0/24 is directly connected, Ethernet0/0
L        172.16.1.1/32 is directly connected, Ethernet0/0
O IA  192.168.1.0/24 [110/30] via 10.1.1.9, 00:18:20, Ethernet0/1
                     [110/30] via 10.1.1.5, 00:00:55, Serial1/0
```

Specifically, we see that both the Ethernet and the Serial Interfaces are being used to load-balance. However, Serial Interfaces have a default interface speed of a T1 line, i.e., `~1.5Mbps` while Ethernet Interfaces have a interface speed default of `10Mbps`. Thus, ideally we'd be using the Ethernet link with the Serial as a backup. This isn't the case, as we see:
```
1.0.0.0/32 is subnetted, 1 subnets
O IA     1.1.1.1 [110/21] via 10.1.1.9, 00:18:20, Ethernet0/1
           [110/21] via 10.1.1.5, 00:00:55, Serial1/0
```

First, we see the maximum paths settings in the `sh ip proto` command to see the number of concurrent load-balancing links:
```
R3#sh ip proto | s ospf
Routing Protocol is "ospf 1"
  Outgoing update filter list for all interfaces is not set
  Incoming update filter list for all interfaces is not set
  Router ID 3.3.3.3
  Number of areas in this router is 1. 1 normal 0 stub 0 nssa
  Maximum path: 4
  Routing for Networks:
    3.3.3.3 0.0.0.0 area 1
    10.1.1.4 0.0.0.3 area 1
    10.1.1.8 0.0.0.3 area 1
    172.16.1.0 0.0.0.255 area 1
  Routing Information Sources:
    Gateway         Distance      Last Update
     2.2.2.2              110      00:05:21
  Distance: (default is 110)
```
we can see that it's set to `4`. The criteria for load-balancing is that the paths must have the same cost. Since in OSPF, the cost is a function of the bandwidth, either one of the interfaces must have an error or a non-standard value in the cost configuration.

We can check the OSPF cost settings using:
```
R3#sh ip ospf int e0/1
Ethernet0/1 is up, line protocol is up
  Internet Address 10.1.1.10/30, Area 1, Attached via Network Statement
  Process ID 1, Router ID 3.3.3.3, Network Type BROADCAST, Cost: 10
  Topology-MTID    Cost    Disabled    Shutdown      Topology Name
        0           10        no          no            Base
  Transmit Delay is 1 sec, State BDR, Priority 1
  Designated Router (ID) 2.2.2.2, Interface address 10.1.1.9
  Backup Designated router (ID) 3.3.3.3, Interface address 10.1.1.10
  Timer intervals configured, Hello 10, Dead 40, Wait 40, Retransmit 5
    oob-resync timeout 40
    Hello due in 00:00:00
  Supports Link-local Signaling (LLS)
  Cisco NSF helper support enabled
  IETF NSF helper support enabled
  Index 1/4/4, flood queue length 0
  Next 0x0(0)/0x0(0)/0x0(0)
  Last flood scan length is 1, maximum is 1
  Last flood scan time is 1 msec, maximum is 1 msec
  Neighbor Count is 1, Adjacent neighbor count is 1
    Adjacent with neighbor 2.2.2.2  (Designated Router)
  Suppress hello for 0 neighbor(s)
R3#sh ip ospf int s1/0
Serial1/0 is up, line protocol is up
  Internet Address 10.1.1.6/30, Area 1, Attached via Network Statement
  Process ID 1, Router ID 3.3.3.3, Network Type POINT_TO_POINT, Cost: 10
  Topology-MTID    Cost    Disabled    Shutdown      Topology Name
        0           10        no          no            Base
  Transmit Delay is 1 sec, State POINT_TO_POINT
  Timer intervals configured, Hello 10, Dead 40, Wait 40, Retransmit 5
    oob-resync timeout 40
    Hello due in 00:00:03
  Supports Link-local Signaling (LLS)
  Cisco NSF helper support enabled
  IETF NSF helper support enabled
  Index 1/2/2, flood queue length 0
  Next 0x0(0)/0x0(0)/0x0(0)
  Last flood scan length is 1, maximum is 1
  Last flood scan time is 0 msec, maximum is 0 msec
  Neighbor Count is 1, Adjacent neighbor count is 1
    Adjacent with neighbor 2.2.2.2
  Suppress hello for 0 neighbor(s)
```
We can see that they both have the same cost. This shouldn't be the case, given that Ethernet links are typically faster than Serial links.

We can check the bandwidth settings now, to see if they're non-standard:
```
R3#sh int e0/1 | i BW
  MTU 1500 bytes, BW 10000 Kbit/sec, DLY 1000 usec,
R3#sh int S1/0 | i BW
  MTU 1500 bytes, BW 10000 Kbit/sec, DLY 20000 usec,
```
It appears that the Serial interface has a non-standard interface speed of `10000Kbps` or `10Mbps`, which causes OSPF to use it for load-balancing. We can change this behavior by finding the offending line in the config:
```
R3#sh run | s Serial1/0
interface Serial1/0
 description Conn to R2
 bandwidth 10000
 ip address 10.1.1.6 255.255.255.252
 serial restart-delay 0
```

We remove the `bandwidth 10000` setting by:
```
R3(config)#int s1/0
R3(config-if)#default bandwidth
R3(config-if)#end
R3#sh ip route
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
       a - application route
       + - replicated route, % - next hop override

Gateway of last resort is not set

      1.0.0.0/32 is subnetted, 1 subnets
O IA     1.1.1.1 [110/21] via 10.1.1.9, 00:31:50, Ethernet0/1
      2.0.0.0/32 is subnetted, 1 subnets
O        2.2.2.2 [110/11] via 10.1.1.9, 00:31:50, Ethernet0/1
      3.0.0.0/32 is subnetted, 1 subnets
C        3.3.3.3 is directly connected, Loopback1
      10.0.0.0/8 is variably subnetted, 5 subnets, 2 masks
O IA     10.1.1.0/30 [110/20] via 10.1.1.9, 00:31:50, Ethernet0/1
C        10.1.1.4/30 is directly connected, Serial1/0
L        10.1.1.6/32 is directly connected, Serial1/0
C        10.1.1.8/30 is directly connected, Ethernet0/1
L        10.1.1.10/32 is directly connected, Ethernet0/1
      172.16.0.0/16 is variably subnetted, 2 subnets, 2 masks
C        172.16.1.0/24 is directly connected, Ethernet0/0
L        172.16.1.1/32 is directly connected, Ethernet0/0
O IA  192.168.1.0/24 [110/30] via 10.1.1.9, 00:31:50, Ethernet0/1
```
Now we can see that only the Ethernet link is being used, as we intended.

We can also see that Serial1/0 now has the correct interface speed:
```
R3#sh ip ospf int s1/0  
Serial1/0 is up, line protocol is up
  Internet Address 10.1.1.6/30, Area 1, Attached via Network Statement
  Process ID 1, Router ID 3.3.3.3, Network Type POINT_TO_POINT, Cost: 64
  Topology-MTID    Cost    Disabled    Shutdown      Topology Name
        0           64        no          no            Base
  Transmit Delay is 1 sec, State POINT_TO_POINT
  Timer intervals configured, Hello 10, Dead 40, Wait 40, Retransmit 5
    oob-resync timeout 40
    Hello due in 00:00:02
  Supports Link-local Signaling (LLS)
  Cisco NSF helper support enabled
  IETF NSF helper support enabled
  Index 1/2/2, flood queue length 0
  Next 0x0(0)/0x0(0)/0x0(0)
  Last flood scan length is 1, maximum is 1
  Last flood scan time is 0 msec, maximum is 0 msec
  Neighbor Count is 1, Adjacent neighbor count is 1
    Adjacent with neighbor 2.2.2.2
  Suppress hello for 0 neighbor(s)
R3#sh int s1/0 | i BW
  MTU 1500 bytes, BW 1544 Kbit/sec, DLY 20000 usec,
```
The cost is now `64` due to an interface speed of `1.544Mbps`.

# Enhanced Interior Gateway Routing Protocol (EIGRP)
# EIGRP Overview
Some of the defining characteristics of EIGRP are its _fast convergence times_ and _scalability_. So, if a link fails, an alternate link takes its place in the routing tables very quickly (in seconds) - whether that's a small network or a large one. An advantage of EIGRP over OSPF is its ability to load-balance over unequal cost paths. We can use the _variance_ option to perform load-balancing over paths that have different metrics.

Just like OSPF, EIGRP supports VLSM (_Variable Length Subnet Masking_), i.e., it's a **classless** routing protocol. This means unlike RIPv2, we're not limited to the classful boudaries for our advertisements. Thus, we can choose to only advertise `10.1.1.0/24` network, ignore advertising for the `10.1.2.0/24` network and advertise the `10.1.3.0/24` network and so on, which isn't possible in the case of classful routing protocols.

To communicate among the neighbours, a multicast address of `224.0.0.10` for IPv4 and `FF02::A` for IPv6 are used. It's one of the best _distance-vector_ protocols with the support for _dynamic route updates_ and the fact that Cisco made EIGRP an _open-standard_ also means that it's supported in a multi-vendor environment.

# EIGRP Components
Four essential components of the operation of the **Enhanced Interior Gateway Routing Protocol (_EIGRP_)** are:
* **Neighbour Discovery** - EIGRP can dynamically discover other EIGRP speaking routers on the network and form neighbourships with them when appropriate.
* **Reliable Transport Protocol (_RTP_)** - RTP lets routers ensure that the _EIGRP packets_ that they sent to their EIGRP speaking neighbour really did reach them _in order_. This becomes important when packets travel through different paths. However, since not all packets need to be reliably transmitted RTP is only used when needed. For example, a router doesn't need to send _EIGRP hello messages_ to all the neighbours individually, and can just send a _multicast hello_ to `244.0.0.10`. Thus, EIGRP can also indicate inside the _hello_ message that the recepient routers don't need to _acknowledge_ the hello messages. However, routing updates need to be and will be acknowledged. RTP for EIGRP **must not be confused with Realtime Transport Protocol (RTP)** which is a Layer 4 protocol for transmission of UDP packets, used in applications such as video transmission in chats, etc.
* **Diffusing Update Algorithm (_DUAL_)** - **DUAL** is an algorithm that runs on EIGRP speaking routers, which calculates the successor among all the neighbours for each destination network. A **Successor** is an EIGRP speaking neighbouring router that has the best path (with the lowest metric) to a destination network, i.e., the best next-hop router for a destination network. The selected, most-attractive route via the successor is called the **Successor Route**. Another EIGRP router that provides an alternative, but not the best path to a destination router, _without causing a routing loop_, is called a **Feasible Successor** and acts as a backup to the _Successor_. The route through it is called a _feasible successor route_.
* **Protocol-Dependent Modules** - EIGRP not only acts as a routing protocol for IPv4/IPv6, but also as a routing protocol for other non-IP Layer 3 protocols, like _AppleTalk, IPX_, etc. The *Protocol Dependent Modules* provide support for these. Even though we might not need to route for non-IP protocols, EIGRP *does* support them.

# EIGRP Data Structures
EIGRP uses _three_ different data-structures:
* **Neighbour Table** - Contains information about IGPR speaking neighbours; can be viewed with `show ip eigrp neighbors`.
* **Interface Table** - Contains information about the Router's interfaces participating in EIGRP; can be viewed with `show ip eigrp interfaces`.
* **Topology Table** - Contains routes known to EIGRP that are either _successor_ or _feasible successor_ routes; can be viewed with `show ip eigrp topology`. To see all the routes, many which EIGRP may never use, we use the command `show ip eigrp topology all-links`.

Just because a route is known by EIGRP doesn't mean, however, that it'll be injected into the IP routing table.

> [Config Required]

# EIGRP Timers
While EIGRP is really fast (i.e., has _low convergence times_), improper timers can slow it down. The timers are used as in OSPF to determine if a neighbour becomes unavailable. This can be either due to a connected link failing or a neighbour failing. In case a directly connected link goes down, i.e., the interfaces status changes from _up/up_ to anything else, EIGRP can instantly remove/recalculate that neighbourship. However, if a neighbour goes down but the interface remains up/up, then we have to wait for the hold timer to expire. We have a couple of timers - the _hello_ timer and the _hold_ timer.

The default _hello_ interval is 5 seconds on a LAN, and the default hold time is 15 sec. The timer values also change based on the connecting network type, i.e., the hello interval for frame relay networks is 60 seconds. In case of LANs, if the router running EIGRP doesn't get a _hello_ message from a neighbour for a period of 15 seconds, it declares that neighbourship dead. Unlike OSPF, the value of the timers don't have to match between neighbours. Thus, we can have different hello and hold timer configurations for different neighbours. While it's a best practice to ensure that the timers match at either end of a circuit, they don't have to match for EIGRP to work!

Another important distinction between the hold timer and the dead timer from OSPF, is that the value for the hold timer doesn't tell the current router to assume a neighbour is dead if not heard from within 15 seconds - instead it tells the _neighbour_ to declare this router as _dead_ if it can't send a hello to it within every 15 seconds. Thus, the hello interval is telling R1 when to send the hello messages, and the hold interval instructs R2 what to do. Thus, R2 will reset it's hello timer for R1 every time it gets a _hello_ message from R1, or declare it dead once the timer expires. By default the hold timer is 3 times the hello interval, but it doesn't have to be.

> [Config Required]

# EIGRP Metric Calculation
EIGRP has 5 total criteria for calculating the metric:
* Bandwidth
* Delay
* Reliability
* Load
* MTU

An acrostic to remember them is '*Big Dogs Really Like Me*'. However, it doesn't use all of them while calculating the metric by default:

>Metric = [(K1 * Bw<sub>min</sub> + (K2 * Bw<sub>min</sub>)/(256 - Load) + K3 * Delay) + K5/(K4 + Reliability)] * 256    
> Where, K<sub>1</sub> = 1    
> K<sub>2</sub> = 0    
> K<sub>3</sub> = 1    
> K<sub>4</sub> = 0    
> K<sub>5</sub> = 0, and    
> Bw<sub>min</sub> = 10<sup>7</sup> / least-bandwidth in Kbps

The bandwidth in the above formula has to be in Kbps, which when divided by 10<sup>7</sup> gives us the value for _Bw<sub>min</sub>_. The delay is cumulative in nature, i.e., each interface adds to the delay. Although the delay is in microseconds, the delay in the formula has to be in _tens of microseconds_, i.e., 10<sup>-5</sup> seconds. So, the delay becomes (delay in micro-secs)/10. Reliability is a ratio of a number between _0_ and _255_, divided by 255. Thus, if our link is 100% reliable, then the reliability would be _255/255_. The load defines how _busy_ our link is, i.e., how much traffic is passing over it. It's a number over 255 as well, and so if minimal traffic passes over the link, the load will be _1/255_. The MTU doesn't even appear in the formula, because it acts as a tie-breaker when the above formula gives us two different routes with the same metric. The link with the *highest MTU* wins.

The values of _K1 - K5_ are the weights given to each component in the calculation of the metric. The values of these weights/constants don't have to be 0 or 1, but can be values >1, based on their importance. Thus, by default the bandwidth and the delay are the only components EIGRP considers for the calculation of the metric:

> Metric = (Bw<sub>min</sub> + Delay) * 256 (where K<sub>1</sub>=K<sub>3</sub>=1 ; K<sub>2</sub>=K<sub>4</sub>=K<sub>5</sub>=0)    
> Metric (Reduced/Default) = [(10,000,000/Min Bandwidth) + (Sum of interface delays/10)] * 256

The default formula of the calculation of the metric should be left alone unless we know what we're doing. For example, Cisco states that factoring load in a link may cause the links to switch frequently, due to oscillating load values. This may be because one link has a low load, and is thus desirable. Once traffic flows through it, the load increases, and the other link becomes desirable. Now the route is switched to the old link and load on it increases, causing the route to be switched back and forth.

## EIGRP Metric Exercise
Let us consider the topology below and calculate the metric for the links in the network. Let us consider we want to find out the metric to reach the `192.168.1.1/24` network from the perspective of R1.

> The least bandwidth in the route is of the Serial link, with 1.544 Mbps = 1544 Kbps.    
> So, Bw<sub>min</sub> = 10<sup>7</sup> / 1544 = 6476.684 ~= 6476 (Integer Trunkation)    
> Interface Delay Sum = 20000 + 1000 = 21000    
> Delay = 20100/10 = 2100    
> Metric = (6476 + 2100) * 256 ~= 2,195,456.    

The above prediction can be easily verified. First, we'll see how to obtain the bandwidth and the delay values:
```
R1#sh int s1/0 | i BW
  MTU 1500 bytes, BW 1544 Kbit/sec, DLY 20000 usec,

R2#sh int s1/0 | i BW
  MTU 1500 bytes, BW 1544 Kbit/sec, DLY 20000 usec,
R2#sh int e0/0 | i BW
  MTU 1500 bytes, BW 10000 Kbit/sec, DLY 1000 usec,
```

Now, to find the metric to the `192.168.1.0/24` network, we check the feasible distance to it on R1 using `show ip eigrp topology`:
```

```
> Config required

## Changing K-Values
The values of the constants or weight can be changed in router config mode:
```

```
The context-sensitive help states that the next value should be a **Type of Service (_ToS_)** value, which is a **Quality of Service (_QoS_)** marking called **IP Precedence**. The higher the _ToS/IP Precedence_, the higher the priority of the packet. The only TOS value supported here is 0. Now, we follow up with the values of _K1 - K5_. Note that the *K-Values need to match at either end of the link for neighbourship to be maintained*.
```

```

# EIGRP Feasibility Condition
EIGRP has two motivations:
- To minimize convergence time and provide very fast failover alternate routes.
- To ensure there are no routing loops.

To help EIGRP determine if it's safe to failover right now, or if additional checking is required, we have the **EIGRP Feasibility Condition**. An EIGRP route is considered a **feasible successor route** if the **Reported Distance (_RD_)** from our _neighbour_ is less than the **Feasible Distance (_FD_)** of the _successor route_. We have to remember that **RD** is the distance from the neighbour to the destination, and **FD** is the distance to the neighbour plus RD. Let us illustrate this condition with the help of the topology below. Let us consider we want to get from R1 to the network `10.1.1.0/24` network, connected to R5.

Here, we have three different paths: _R1-R2-R5_ through **R2**, _R1-R3-R5_ through **R3** and _R1-R4-R5_ through **R5**. The nubmers next to the links indicate the cost to travel through those links. Then we get the following table on R1:
```
Neighbour   RD      FD = RD + Dist to Nbr.      (Feaisble?) Successor
=========== ======= =========================== =====================
    R2       6,000  6,000 + 10,000 = 16,000     Successor
    R3      11,000  7,000 + 11,000 = 18,000     Feasible Successor
    R4      18,000  4,000 + 10,000 = 22,000     NO.
```

First, we choose the path with the lowest cost - which in this case is _R1-R2-R5_, which has a FD of only 16,000. A route is only called feasible if there's a stand-by route for failover that's available immediately via one of the other neighbours. In order to become a feasible successor, the RD of the path being considered must be less than the FD of the path via the current successor. Thus, in this case, for R3 to be come the feasible successor, its RD (cost to reach the destination network) has to be less than the FD of route via R2. This is true (Since `11,000 < 16,000`). However, when we compare R2 and R4, we see that RD of R4 = `18,000` is *not less than* the FD of the current router, R1 = `16,000`. Thus it won't become a feasible successor.

The failure of the feasibility condition doesn't necessarily indicate the presence of a routing loop, as in this case the _R1-R4-R5_ path didn't have any routing loops, but failed the feasibility criteria anyway. It just means that further analysis is required to determine if there's a routing loop. The job of a feasible successor router is to ensure that a backup route is available for use instantly when the primary link fails, and since the route through R4 requires more analysis, it's not a feasible successor router. The path through R4 may still be used as a backup path, but it's going to take longer to switchover since the router R1 has to first ensure that path isn't causing a routing loop. For this, R1 will send R4 a query and R4 will send its neighbour R5 a query, etc. After this querying process, the router R4 is ready to use, but it's not nearly as fast as having a feasible successor router with a standby link. While in this simple topology the querying process will end quickly, in larger enterprise networks, the querying will generate a noticeable delay.

# EIGRP for IPv4 Configuration and Verification
Let us assume that we want to enable EIGRP on the following topology. Just like OSPF, we'll be using network statements to define which interfaces will be participating in routing protocol. We begin the EIGRP configuration by declaring an **Autonomous System (_AS_) Number**. Then on each router we define the network statements. In OSPF we had to include the wildcard mask, but in EIGRP, if the wildcard mask is skipped, then the router uses the network's classful address mask to figure out the wildcard mask.
```
R1(config)#router eigrp 1
R1(config-router)#network 192.168.1.1 0.0.0.255
R1(config-router)#network 192.168.2.0 0.0.0.255
R1(config-router)#network 10.1.1.1 0.0.0.0

R2(config)#router eigrp 1
R2(config-router)#network 192.168.2.0
*Dec 30 13:20:48.303: %DUAL-5-NBRCHANGE: EIGRP-IPv4 1: Neighbor 192.168.2.1 (Ethernet0/0) is up: new adjacency
R2(config-router)#network 172.16.0.0
R2(config-router)#network 10.0.0.0        
```
On the configuration of R2, we skipped the wildcard mask for the `192.168.2.0/24` network because the classful mask of the `192.168.*.0` network is 24 bits. Almost immediately, an adjacency will form with R1. Further, we have two different links in the `172.16.0.0/12` range: `172.16.1.1` and `172.16.1.5` networks. The default classful mask length for the `172.16.0.0` network is 12 bits, not the required 30 bits, but since it encompasses the IP address' block and since there aren't any interfaces within this block that we don't want to participate in EIGRP, we can just write it this way. Similarly, we include the entire `10.0.0.0/8` network since `10.2.2.2` is an IP within this address block.

Now we configure R3 and R4. Again, we just enabled routing on the entire `172.16.0.0` network, but since the `172.16.1.4/30` network is the only one assigned to an interface, that's the only one that'll be advertised. An adjacency is formed with R2. Then, we had two different networks that we wanted to participate in EIGRP: `10.3.3.3/32` and `10.10.10.1/24`. Since both fall within the `10.0.0.0/8` network, we include them both with the `network 10.0.0.0` command, since the classful mask of `/8` will generate a `0.255.255.255` wildcard mask which will encompass both the networks:
```
R3(config)#router eigrp 1
R3(config-router)#network 172.16.0.0
*Dec 30 13:32:07.181: %DUAL-5-NBRCHANGE: EIGRP-IPv4 1: Neighbor 172.16.1.1 (Serial1/0) is up: new adjacency
R3(config-router)#network 10.0.0.0

R4(config)#router eigrp 1
R4(config-router)#network 0.0.0.0
*Dec 30 13:39:33.729: %DUAL-5-NBRCHANGE: EIGRP-IPv4 1: Neighbor 10.10.10.1 (Ethernet0/0) is up: new adjacency
*Dec 30 13:39:33.738: %DUAL-5-NBRCHANGE: EIGRP-IPv4 1: Neighbor 172.16.1.5 (Serial1/0) is up: new adjacency
```
Finally, in the case of R4, we included all active interfaces in routing by using the `network 0.0.0.0` command. It's the IP address for all possible IPv4 networks, and will have a wildcard mask of (`255.255.255.255`). This automatically activates EIGRP on all interfaces. This is why two different adjacencies are formed.

## EIGRP Verification
Now that EIGRP has been configured on all the routers, we can verify the configuration. First we go to R2 since it has 4 different interfaces all participating in EIGRP. To see which interfaces are participating in EIGRP, we use `show ip eigrp interfaces`:
```
R2#sh ip eigrp int
EIGRP-IPv4 Interfaces for AS(1)
                              Xmit Queue   PeerQ        Mean   Pacing Time   Multicast    Pending
Interface              Peers  Un/Reliable  Un/Reliable  SRTT   Un/Reliable   Flow Timer   Routes
Et0/0                    1        0/0       0/0           6       0/2           50           0
Se1/0                    1        0/0       0/0          17       2/95         147           0
Se1/1                    1        0/0       0/0          16       1/50         110           0
Lo1                      0        0/0       0/0           0       0/0            0           0
```

To see which IP addresses are our neighbours, we use the command `show ip eigrp neighbors`:
```
R2#sh ip eigrp nei
EIGRP-IPv4 Neighbors for AS(1)
H   Address                 Interface              Hold Uptime   SRTT   RTO  Q  Seq
                                                   (sec)         (ms)       Cnt Num
2   172.16.1.6              Se1/1                    14 00:07:58   16   300  0  10
1   172.16.1.2              Se1/0                    11 00:15:24   17   570  0  17
0   192.168.2.1             Et0/0                    11 00:26:43    6   100  0  10
```

Next, to see which routes EIGRP is aware of, we use the `show ip eigrp topology` command:
```
R2#sh ip eigrp nei
EIGRP-IPv4 Neighbors for AS(1)
H   Address                 Interface              Hold Uptime   SRTT   RTO  Q  Seq
                                                   (sec)         (ms)       Cnt Num
2   172.16.1.6              Se1/1                    14 00:07:58   16   300  0  10
1   172.16.1.2              Se1/0                    11 00:15:24   17   570  0  17
0   192.168.2.1             Et0/0                    11 00:26:43    6   100  0  10
R2#sh ip eigrp topo
EIGRP-IPv4 Topology Table for AS(1)/ID(10.2.2.2)
Codes: P - Passive, A - Active, U - Update, Q - Query, R - Reply,
       r - reply Status, s - sia Status

P 10.3.3.3/32, 1 successors, FD is 2297856
        via 172.16.1.6 (5665536/409600), Serial1/1
        via 172.16.1.2 (10639872/128256), Serial1/0
P 10.1.1.1/32, 1 successors, FD is 409600
        via 192.168.2.1 (409600/128256), Ethernet0/0
P 192.168.2.0/24, 1 successors, FD is 281600
        via Connected, Ethernet0/0
P 192.168.1.0/24, 1 successors, FD is 307200
        via 192.168.2.1 (307200/281600), Ethernet0/0
P 10.4.4.4/32, 1 successors, FD is 2297856
        via 172.16.1.6 (5639936/128256), Serial1/1
        via 172.16.1.2 (10665472/409600), Serial1/0
P 172.16.1.4/30, 1 successors, FD is 5511936
        via Connected, Serial1/1
P 172.16.1.0/30, 1 successors, FD is 10511872
        via Connected, Serial1/0
P 10.2.2.2/32, 1 successors, FD is 128256
        via Connected, Loopback1
P 10.10.10.0/24, 1 successors, FD is 2195456
        via 172.16.1.6 (5537536/281600), Serial1/1
        via 172.16.1.2 (10537472/281600), Serial1/0
```

Here, we can see that R2 knows 2 different routes to sw3, i.e., the `10.10.10.0/24` network - one through R3(`172.16.1.2`) and the other through R4 (`172.16.1.6`):
```
P 10.10.10.0/24, 1 successors, FD is 2195456
        via 172.16.1.6 (5537536/281600), Serial1/1
        via 172.16.1.2 (10537472/281600), Serial1/0
```
The first number in `172.16.1.6 (5537536/281600)`, i.e., `5537536` is the **Feasible Distance (_FD_)**, the total cost of getting to that network, and the 2nd number `281600` is the **Reported Distance (_RD_)**, which is the cost to traverse to the destination from the neighbour. Thus, it costs `281600` to get to the destination `10.10.10.0/24` _from_ R4 (172.16.1.6) and costs `5537536` to get to the destination from R2. while both routes are known by EIGRP, when we check the IP routing table, we see that only one of these routes were injected into the routing table, the one with the least metric, i.e., R4 (`172.16.1.6`):
```
R2#sh ip route
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
       a - application route
       + - replicated route, % - next hop override

Gateway of last resort is not set

      10.0.0.0/8 is variably subnetted, 5 subnets, 2 masks
D        10.1.1.1/32 [90/409600] via 192.168.2.1, 00:11:49, Ethernet0/0
C        10.2.2.2/32 is directly connected, Loopback1
D        10.3.3.3/32 [90/5665536] via 172.16.1.6, 00:13:05, Serial1/1
D        10.4.4.4/32 [90/5639936] via 172.16.1.6, 00:13:05, Serial1/1
D        10.10.10.0/24 [90/5537536] via 172.16.1.6, 00:13:05, Serial1/1
      172.16.0.0/16 is variably subnetted, 4 subnets, 2 masks
C        172.16.1.0/30 is directly connected, Serial1/0
L        172.16.1.1/32 is directly connected, Serial1/0
C        172.16.1.4/30 is directly connected, Serial1/1
L        172.16.1.5/32 is directly connected, Serial1/1
D     192.168.1.0/24 [90/307200] via 192.168.2.1, 00:11:49, Ethernet0/0
      192.168.2.0/24 is variably subnetted, 2 subnets, 2 masks
C        192.168.2.0/24 is directly connected, Ethernet0/0
L        192.168.2.2/32 is directly connected, Ethernet0/0
```

This is due to the fact that one of the links is a 256Kbps line while the other is a 512Kbps line to the same destination. Thus, the higher speed interfaces connected between R2 and R4 generate a lower **Feasible Distance (_FD_)**, and thus has the lower cost and becomes the preferred route. However, the 2nd route via `172.16.1.2 (10537472/281600)` has met the *Feasibility Condition* since the RD of path through R3 (`281600`) is lower than the FD of the **Successor**, i.e., the current preferred path through R4 (`5537536`). Hence it has become the *Feasible Successor Router*, and it'll take over instantly if R4 or the connecting links fail.

The output of the `show ip eigrp topo` command only shows us the successor or feasible successor routes. To see all possible routes, including the *non-successor* routes, we use the commnand `show ip eigrp topology all-links`:
```
R2#sh ip eigrp topo all
EIGRP-IPv4 Topology Table for AS(1)/ID(10.2.2.2)
Codes: P - Passive, A - Active, U - Update, Q - Query, R - Reply,
       r - reply Status, s - sia Status

P 10.3.3.3/32, 1 successors, FD is 2297856, serno 15
        via 172.16.1.6 (5665536/409600), Serial1/1
        via 172.16.1.2 (10639872/128256), Serial1/0
P 10.1.1.1/32, 1 successors, FD is 409600, serno 3
        via 192.168.2.1 (409600/128256), Ethernet0/0
        via 172.16.1.2 (11203072/5691136), Serial1/0, serno 28
P 192.168.2.0/24, 1 successors, FD is 281600, serno 1
        via Connected, Ethernet0/0
P 192.168.1.0/24, 1 successors, FD is 307200, serno 2
        via 192.168.2.1 (307200/281600), Ethernet0/0
        via 172.16.1.2 (11100672/5588736), Serial1/0, serno 30
P 10.4.4.4/32, 1 successors, FD is 2297856, serno 16
        via 172.16.1.6 (5639936/128256), Serial1/1
        via 172.16.1.2 (10665472/409600), Serial1/0
P 172.16.1.4/30, 1 successors, FD is 5511936, serno 18
        via Connected, Serial1/1
        via 172.16.1.2 (11049472/5537536), Serial1/0, serno 32
P 172.16.1.0/30, 1 successors, FD is 10511872, serno 13
        via Connected, Serial1/0
        via 172.16.1.6 (11049472/10537472), Serial1/1, serno 23
P 10.2.2.2/32, 1 successors, FD is 128256, serno 6
        via Connected, Loopback1
P 10.10.10.0/24, 1 successors, FD is 2195456, serno 17
        via 172.16.1.6 (5537536/281600), Serial1/1
        via 172.16.1.2 (10537472/281600), Serial1/0
```

Finally, we use the `show ip protocols` command to get the details of the running EIGRP process on the router:
```
R2#sh ip proto  
*** IP Routing is NSF aware ***
...
Routing Protocol is "eigrp 1"
  Outgoing update filter list for all interfaces is not set
  Incoming update filter list for all interfaces is not set
  Default networks flagged in outgoing updates
  Default networks accepted from incoming updates
  EIGRP-IPv4 Protocol for AS(1)
    Metric weight K1=1, K2=0, K3=1, K4=0, K5=0
    Soft SIA disabled
    NSF-aware route hold timer is 240
    Router-ID: 10.2.2.2
    Topology : 0 (base)
      Active Timer: 3 min
      Distance: internal 90 external 170
      Maximum path: 4
      Maximum hopcount 100
      Maximum metric variance 1

  Automatic Summarization: disabled
  Maximum path: 4
  Routing for Networks:
    10.0.0.0
    172.16.0.0
    192.168.2.0
  Routing Information Sources:
    Gateway         Distance      Last Update
    192.168.2.1           90      00:28:17
    172.16.1.6            90      00:28:41
    172.16.1.2            90      00:28:17
  Distance: internal 90 external 170
```
We can see the Autonomous System (AS) number, the value of the K-constants/metric weights, the router ID, the networks being advertised and which neighbours are sending us routing updates.

We can also see the timers for a particular interface using the `show ip eigrp interface detail <intID>` command. Skipping the interface ID would show us the details of all available interfaces participating in EIGRP:
```
R2#sh ip eigrp int detail s1/0
EIGRP-IPv4 Interfaces for AS(1)
                              Xmit Queue   PeerQ        Mean   Pacing Time   Multicast    Pending
Interface              Peers  Un/Reliable  Un/Reliable  SRTT   Un/Reliable   Flow Timer   Routes
Se1/0                    1        0/0       0/0          17       2/95         147           0
  Hello-interval is 5, Hold-time is 15
  Split-horizon is enabled
  Next xmit serial <none>
  Packetized sent/expedited: 7/0
  Hello's sent/expedited: 698/2
  Un/reliable mcasts: 0/0  Un/reliable ucasts: 8/10
  Mcast exceptions: 0  CR packets: 0  ACKs suppressed: 0
  Retransmissions sent: 1  Out-of-sequence rcvd: 1
  Topology-ids on interface - 0
  Authentication mode is not set
```

## Statically Configuring EIGRP Neighbour
Although we don't do this quite often, we _can_ statically define a neighbour with EIGRP. We do this by going to the router configuration mode and specifying the neighbour's IP address and the interface which connects to it. Let's do this for R1:
```
R1(config)#router eigrp 1
R1(config-router)#neighbor 192.168.2.2 e0/1   
*Dec 30 14:23:55.706: %DUAL-5-NBRCHANGE: EIGRP-IPv4 1: Neighbor 192.168.2.2 (Ethernet0/1) is down: Static peer replaces multicast
```
We need to be careful while doing this because we lose all the neighbourships that were dynamically discovered by EIGRP on that interface. In this case, of there were any more neighbours connected to switch _sw2_, R1'd lose its neighbourship with all of them. Further, the new/static neighbourship hasn't formed yet, and won't till we define R1 as a static neighbour on R2:
```
R2(config)#router eigrp 1
R2(config-router)#neighbor 192.168.2.1 e0/0
*Dec 30 14:27:32.403: %DUAL-5-NBRCHANGE: EIGRP-IPv4 1: Neighbor 192.168.2.1 (Ethernet0/0) is up: new adjacency
```

We can now see that R2's a neighbour of R1 again, and the `show ip eigrp neighbors detail` command shows us that it's a statically configured neighbour:
```
R2#sh ip eigrp nei
EIGRP-IPv4 Neighbors for AS(1)
H   Address                 Interface              Hold Uptime   SRTT   RTO  Q  Seq
                                                   (sec)         (ms)       Cnt Num
2   192.168.2.1             Et0/0                    12 00:01:24   15   100  0  6
1   172.16.1.6              Se1/1                    13 00:06:52   14   288  0  25
0   172.16.1.2              Se1/0                    12 00:06:52   18   582  0  21
R2#sh ip eigrp nei det
EIGRP-IPv4 Neighbors for AS(1)
H   Address                 Interface              Hold Uptime   SRTT   RTO  Q  Seq
                                                   (sec)         (ms)       Cnt Num
2   192.168.2.1             Et0/0                    13 00:02:09   15   100  0  6
   Static neighbor
   Version 18.0/2.0, Retrans: 0, Retries: 0, Prefixes: 2
   Topology-ids from peer - 0
1   172.16.1.6              Se1/1                    10 00:07:36   14   288  0  25
   Version 18.0/2.0, Retrans: 0, Retries: 0, Prefixes: 4
   Topology-ids from peer - 0
0   172.16.1.2              Se1/0                    13 00:07:36   18   582  0  21
   Version 18.0/2.0, Retrans: 1, Retries: 0, Prefixes: 6
   Topology-ids from peer - 0
Max Nbrs: 0, Current Nbrs: 0
```

# Configuring Unequal Cost Load Balancing
OSPF can load-balance accross equal cost paths, and that's what EIGRP does by default, as well. However, it also has the option of _variance_ that lets it load-balance across unequal cost paths if one of those is the successor route and one or more are feasible successor routes. The maximum number of paths that can be used to load-balance by default is _4_ and can be seen as _maximum path_ in the output of the `show ip protocols` command:
```
R2#sh ip proto | s eigrp
Routing Protocol is "eigrp 1"
  Outgoing update filter list for all interfaces is not set
  Incoming update filter list for all interfaces is not set
  Default networks flagged in outgoing updates
  Default networks accepted from incoming updates
  EIGRP-IPv4 Protocol for AS(1)
    Metric weight K1=1, K2=0, K3=1, K4=0, K5=0
    Soft SIA disabled
    NSF-aware route hold timer is 240
    Router-ID: 10.2.2.2
    Topology : 0 (base)
      Active Timer: 3 min
      Distance: internal 90 external 170
      Maximum path: 4
      Maximum hopcount 100
      Maximum metric variance 1
```
This can be changed by going to the router configuration mode and then change the `maximum-paths` option:
```
R2(config)#router eigrp 1
R2(config-router)#maximum-paths ?
  <1-32>  Number of paths
```

We can see that the only route to the `10.10.10.0/24` network is through R4, and the route through R3 isn't in the routing table:
```
R2#sh ip route | s 10.10.10.0/24
D        10.10.10.0/24 [90/5537536] via 172.16.1.6, 00:39:39, Serial1/1
```
However, EIGRP does know the route via R3 (`172.16.1.2`):
```
R2#sh ip eigrp topo | s 10.10.10.0/24
P 10.10.10.0/24, 1 successors, FD is 5537536
        via 172.16.1.6 (5537536/281600), Serial1/1
        via 172.16.1.2 (10537472/281600), Serial1/0
```

The **Variance** is an integer factor, a value with which we multiply the FD of the successor route to get a maximum FD across which we're willing to load-balance. Any feasible successor route which has a FD equal to or less than this maximum FD will then participate in load-balancing. In this case, we have an FD of about 5.5M for the successor route. If the factor were to be 4, the max FD would be 22M, which is much higher than our required 10.5M. A better method than guessing the factor would be to divide the highest FD we have for a route we want to use in load-balancing, in our case: 10.5M by 5.5M, which is the FD of the successor route, to obtain an approx factor, which in this case is _1.9 ~= 2_. Thus, in this case, our variance multiplier should be _2_. We can set it in the router configuration mode:
```
R2(config)#router eigrp 1
R2(config-router)#variance 2
```
Now, we should see 2 routes instead of just the successor route in the IP routing table:
```
R2#sh ip route | s 10.10.10.0/24
D        10.10.10.0/24 [90/5537536] via 172.16.1.6, 00:01:32, Serial1/1
                       [90/10537472] via 172.16.1.2, 00:01:32, Serial1/0
```

# EIGRP for IPv6 Overview
EIGRP for IPv6 is similar to EIGRP for IPv4, with a new key differences:
* The next hop address is the neighbour's Link Local address. This isn't possible in IPv4 since there are no link local addresses in IPv4.
* Instead of using EIGRP specific authentication features like in EIGRP for IPv4, EIGRP for IPv6 used the authentication features built into IPv6.
* Since there are no IPv6 address classes, auto-summarization isn't possible in IPv6 and the wild-card mask must be specified in each instance.
* Neighbours don't need to be in the same subnet.
* Multicast address used is FF02::A

# EIGRP for IPv6 Configuration
Similar to the process for OSPFv3, we should first start IPv6 unicast routing and IPv6 CEF. Then, we can start the EIGRP process for the particular AS.
```
R1(config)#ipv6 unicast-routing
R1(config)#ipv6 cef
R1(config)#ipv6 router eigrp 1
R1(config-rtr)#
```

In the router configuration mode we can define the number of paths used for load-balancing, the variance and passive interfaces, etc., but we won't be defining the interfaces that'll be participating in EIGRP here. Just like OSPF, instead of defining the networks that will contain the interfaces which'll participate in EIGRP, we'll directly go to the interface configuration mode and ask them to join EIGRP.
```
R1(config-rtr)#int e0/0
R1(config-if)#ipv6 eigrp 1
R1(config-if)#int s1/0
R1(config-if)#ipv6 eigrp 1
```
Since we already have a loopback interface, we don't need to separately specify the Router ID for EIGRP.

Now we can move on to the configuration of Router R2 and R3. We have to ensure that the **autonomous system numbers must match between routers**. We can also ignore the loop back interface and directly assign a router ID:
```
R2(config)#ipv6 uni
R2(config)#ipv6 cef
R2(config)#int s1/0
R2(config-if)#ipv6 eigrp 1
R2(config-if)#int s1/1
R2(config-if)#ipv6 eigrp 1
R2(config)#ipv6 router eigrp 1
R2(config-rtr)#eigrp router-id 4.4.4.4

R3(config)#ipv6 uni             
R3(config)#ipv6 cef
R3(config)#int s1/0
R3(config-if)#ipv6 eigrp 1
R3(config-if)#int e0/0
R3(config-if)#ipv6 eigrp 1
R3(config)#ipv6 router eigrp 1
```

# EIGRP for IPv6 Verification
We can see the IPv6 routes knows via EIGRP with:
```
R1#sh ipv6 route
IPv6 Routing Table - default - 7 entries
Codes: C - Connected, L - Local, S - Static, U - Per-user Static route
       B - BGP, HA - Home Agent, MR - Mobile Router, R - RIP
       H - NHRP, I1 - ISIS L1, I2 - ISIS L2, IA - ISIS interarea
       IS - ISIS summary, D - EIGRP, EX - EIGRP external, NM - NEMO
       ND - ND Default, NDp - ND Prefix, DCE - Destination, NDr - Redirect
       O - OSPF Intra, OI - OSPF Inter, OE1 - OSPF ext 1, OE2 - OSPF ext 2
       ON1 - OSPF NSSA ext 1, ON2 - OSPF NSSA ext 2, la - LISP alt
       lr - LISP site-registrations, ld - LISP dyn-eid, a - Application
C   2000:1::/64 [0/0]
     via Ethernet0/0, directly connected
L   2000:1::1/128 [0/0]
     via Ethernet0/0, receive
C   2000:2::/64 [0/0]
     via Serial1/0, directly connected
L   2000:2::1/128 [0/0]
     via Serial1/0, receive
D   2000:3::/64 [90/2681856]
     via FE80::A8BB:CCFF:FE00:200, Serial1/0
D   2000:4::/64 [90/2707456]
     via FE80::A8BB:CCFF:FE00:200, Serial1/0
L   FF00::/8 [0/0]
     via Null0, receive
```
The EIGRP IPv6 routes will be indicated with the `D` in the first column. To exclusively see those routes, we could use `show ipv6 route eigrp`:
```
R1#sh ipv6 route eigrp
IPv6 Routing Table - default - 7 entries
Codes: C - Connected, L - Local, S - Static, U - Per-user Static route
       B - BGP, HA - Home Agent, MR - Mobile Router, R - RIP
       H - NHRP, I1 - ISIS L1, I2 - ISIS L2, IA - ISIS interarea
       IS - ISIS summary, D - EIGRP, EX - EIGRP external, NM - NEMO
       ND - ND Default, NDp - ND Prefix, DCE - Destination, NDr - Redirect
       O - OSPF Intra, OI - OSPF Inter, OE1 - OSPF ext 1, OE2 - OSPF ext 2
       ON1 - OSPF NSSA ext 1, ON2 - OSPF NSSA ext 2, la - LISP alt
       lr - LISP site-registrations, ld - LISP dyn-eid, a - Application
D   2000:3::/64 [90/2681856]
     via FE80::A8BB:CCFF:FE00:200, Serial1/0
D   2000:4::/64 [90/2707456]
     via FE80::A8BB:CCFF:FE00:200, Serial1/0
```
To see if route for a specific network exists, we can mention the name of the network in the command:
```
R1#sh ipv6 route 2000:1::/64
Routing entry for 2000:1::/64
  Known via "connected", distance 0, metric 0, type connected
  Route count is 1/1, share count 0
  Routing paths:
    directly connected via Ethernet0/0
      Last updated 00:19:18 ago
```

We can see the EIGRP protocol to get the K-Values:
```
R1#sh ipv6 proto
IPv6 Routing Protocol is "connected"
IPv6 Routing Protocol is "application"
IPv6 Routing Protocol is "ND"
IPv6 Routing Protocol is "eigrp 1"
EIGRP-IPv6 Protocol for AS(1)
  Metric weight K1=1, K2=0, K3=1, K4=0, K5=0
  Soft SIA disabled
  NSF-aware route hold timer is 240
  Router-ID: 1.1.1.1
  Topology : 0 (base)
    Active Timer: 3 min
    Distance: internal 90 external 170
    Maximum path: 16
    Maximum hopcount 100
    Maximum metric variance 1

  Interfaces:
    Ethernet0/0
    Serial1/0
  Redistribution:
    None
```

On Router R2, we can verify if our manual configuration of `4.4.4.4` was accepted for the router ID:
```
R2#sh ipv6 proto
IPv6 Routing Protocol is "connected"
IPv6 Routing Protocol is "application"
IPv6 Routing Protocol is "ND"
IPv6 Routing Protocol is "eigrp 1"
EIGRP-IPv6 Protocol for AS(1)
  Metric weight K1=1, K2=0, K3=1, K4=0, K5=0
  Soft SIA disabled
  NSF-aware route hold timer is 240
  Router-ID: 4.4.4.4
  Topology : 0 (base)
    Active Timer: 3 min
    Distance: internal 90 external 170
    Maximum path: 16
    Maximum hopcount 100
    Maximum metric variance 1

  Interfaces:
    Serial1/0
    Serial1/1
  Redistribution:
    None
```

We can see the IPv6 neighbours using:
```
R2#sh ipv6 eigrp nei
EIGRP-IPv6 Neighbors for AS(1)
H   Address                 Interface              Hold Uptime   SRTT   RTO  Q  Seq
                                                   (sec)         (ms)       Cnt Num
1   Link-local address:     Se1/0                    14 00:12:18   19   114  0  7
    FE80::A8BB:CCFF:FE00:100
0   Link-local address:     Se1/1                    14 00:12:19   20   120  0  7
    FE80::A8BB:CCFF:FE00:300
```
EIGRP uses link-local addresses for next hops.

We can also see the interfaces that are participating in EIGRP:
```
R2#sh ipv6 eigrp int
EIGRP-IPv6 Interfaces for AS(1)
                              Xmit Queue   PeerQ        Mean   Pacing Time   Multicast    Pending
Interface              Peers  Un/Reliable  Un/Reliable  SRTT   Un/Reliable   Flow Timer   Routes
Se1/0                    1        0/0       0/0          19       0/15          95           0
Se1/1                    1        0/0       0/0          20       0/15          95           0
```

We can see the timers using:
```
R2#sh ipv6 eigrp int det
EIGRP-IPv6 Interfaces for AS(1)
                              Xmit Queue   PeerQ        Mean   Pacing Time   Multicast    Pending
Interface              Peers  Un/Reliable  Un/Reliable  SRTT   Un/Reliable   Flow Timer   Routes
Se1/0                    1        0/0       0/0          19       0/15          95           0
  Hello-interval is 5, Hold-time is 15
  Split-horizon is enabled
  Next xmit serial <none>
  Packetized sent/expedited: 5/0
  Hello's sent/expedited: 256/3
  Un/reliable mcasts: 0/0  Un/reliable ucasts: 6/7
  Mcast exceptions: 0  CR packets: 0  ACKs suppressed: 0
  Retransmissions sent: 0  Out-of-sequence rcvd: 0
  Topology-ids on interface - 0
  Authentication mode is not set
Se1/1                    1        0/0       0/0          20       0/15          95           0
  Hello-interval is 5, Hold-time is 15
  Split-horizon is enabled
  Next xmit serial <none>
  Packetized sent/expedited: 5/0
  Hello's sent/expedited: 258/3
  Un/reliable mcasts: 0/0  Un/reliable ucasts: 7/7
  Mcast exceptions: 0  CR packets: 0  ACKs suppressed: 0
  Retransmissions sent: 0  Out-of-sequence rcvd: 0
  Topology-ids on interface - 0
  Authentication mode is not set
```
Again, just like in IPv4, the hold timer doesn't state that it will wait 15 seconds before declaring that a neighbour is down, but instead it tells its neighbours to wait for 15 seconds for a hello message from R2 which if not received would indicate that R2 is down.

Finally, we can can see which routes IPv6 EIGRP is aware of using:
```
R2#sh ipv6 eigrp topo
EIGRP-IPv6 Topology Table for AS(1)/ID(4.4.4.4)
Codes: P - Passive, A - Active, U - Update, Q - Query, R - Reply,
       r - reply Status, s - sia Status

P 2000:2::/64, 1 successors, FD is 2169856
        via Connected, Serial1/0
P 2000:3::/64, 1 successors, FD is 2169856
        via Connected, Serial1/1
P 2000:4::/64, 1 successors, FD is 2195456
        via FE80::A8BB:CCFF:FE00:300 (2195456/281600), Serial1/1
P 2000:1::/64, 1 successors, FD is 2195456
        via FE80::A8BB:CCFF:FE00:100 (2195456/281600), Serial1/0
```
The _passive_ states indicate that the routes are stable and are not being recalculated.

# EIGRP Troubleshooting Exercise 1
In this trouble ticket, we seem to be unable to learn routes from R3 or have R3 learn routes via EIGRP. The parameters for routers that must match between EIGRP neighbours are:
* AS number
* K Values
* Auth credentials
* Subnet and masks

The configuration on R1 is:
```
R1#sh ip proto | b eigrp
Routing Protocol is "eigrp 1"
  Outgoing update filter list for all interfaces is not set
  Incoming update filter list for all interfaces is not set
  Default networks flagged in outgoing updates
  Default networks accepted from incoming updates
  EIGRP-IPv4 Protocol for AS(1)
    Metric weight K1=1, K2=0, K3=1, K4=0, K5=0
    Soft SIA disabled
    NSF-aware route hold timer is 240
    Router-ID: 1.1.1.1
    Topology : 0 (base)
      Active Timer: 3 min
      Distance: internal 90 external 170
      Maximum path: 4
      Maximum hopcount 100
      Maximum metric variance 1

  Automatic Summarization: disabled
  Maximum path: 4
  Routing for Networks:
    1.1.1.1/32
    10.1.1.0/24
    172.16.1.0/30
  Routing Information Sources:
    Gateway         Distance      Last Update
    10.1.1.2              90      00:12:15
    172.16.1.2            90      00:03:14
  Distance: internal 90 external 170

R1#sh ip eigrp nei
EIGRP-IPv4 Neighbors for AS(1)
H   Address                 Interface              Hold Uptime   SRTT   RTO  Q  Seq
                                                   (sec)         (ms)       Cnt Num
0   172.16.1.2              Se1/0                    10 00:13:02   16   100  0  17
R1#sh ip eigrp int
EIGRP-IPv4 Interfaces for AS(1)
                              Xmit Queue   PeerQ        Mean   Pacing Time   Multicast    Pending
Interface              Peers  Un/Reliable  Un/Reliable  SRTT   Un/Reliable   Flow Timer   Routes
Lo0                      0        0/0       0/0           0       0/0            0           0
Et0/0                    0        0/0       0/0           0       0/2           50           0
Se1/0                    1        0/0       0/0          16       0/16          72           0
R1#sh ip eigrp topo
EIGRP-IPv4 Topology Table for AS(1)/ID(1.1.1.1)
Codes: P - Passive, A - Active, U - Update, Q - Query, R - Reply,
       r - reply Status, s - sia Status

P 10.2.2.0/24, 1 successors, FD is 332800
        via 172.16.1.2 (2195456/281600), Serial1/0
P 192.168.1.0/30, 1 successors, FD is 307200
        via 172.16.1.2 (2195456/281600), Serial1/0
P 2.2.2.2/32, 1 successors, FD is 435200
        via 172.16.1.2 (2297856/128256), Serial1/0
P 172.16.1.0/30, 1 successors, FD is 2169856
        via Connected, Serial1/0
P 10.1.1.0/24, 1 successors, FD is 281600
        via Connected, Ethernet0/0
P 1.1.1.1/32, 1 successors, FD is 128256
        via Connected, Loopback0

R1#sh ip route
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
       a - application route
       + - replicated route, % - next hop override

Gateway of last resort is not set

      1.0.0.0/32 is subnetted, 1 subnets
C        1.1.1.1 is directly connected, Loopback0
      2.0.0.0/32 is subnetted, 1 subnets
D        2.2.2.2 [90/2297856] via 172.16.1.2, 00:03:45, Serial1/0
      10.0.0.0/8 is variably subnetted, 3 subnets, 2 masks
C        10.1.1.0/24 is directly connected, Ethernet0/0
L        10.1.1.1/32 is directly connected, Ethernet0/0
D        10.2.2.0/24 [90/2195456] via 172.16.1.2, 00:03:45, Serial1/0
      172.16.0.0/16 is variably subnetted, 2 subnets, 2 masks
C        172.16.1.0/30 is directly connected, Serial1/0
L        172.16.1.1/32 is directly connected, Serial1/0
      192.168.1.0/30 is subnetted, 1 subnets
D        192.168.1.0 [90/2195456] via 172.16.1.2, 00:03:45, Serial1/0
R1#sh ip route eigrp
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
       a - application route
       + - replicated route, % - next hop override

Gateway of last resort is not set

      2.0.0.0/32 is subnetted, 1 subnets
D        2.2.2.2 [90/2297856] via 172.16.1.2, 00:03:52, Serial1/0
      10.0.0.0/8 is variably subnetted, 3 subnets, 2 masks
D        10.2.2.0/24 [90/2195456] via 172.16.1.2, 00:03:52, Serial1/0
      192.168.1.0/30 is subnetted, 1 subnets
D        192.168.1.0 [90/2195456] via 172.16.1.2, 00:03:52, Serial1/0
```

On R2, the configuration is:
```
R2#sh ip proto | b eigrp
Routing Protocol is "eigrp 1"
  Outgoing update filter list for all interfaces is not set
  Incoming update filter list for all interfaces is not set
  Default networks flagged in outgoing updates
  Default networks accepted from incoming updates
  EIGRP-IPv4 Protocol for AS(1)
    Metric weight K1=1, K2=0, K3=1, K4=0, K5=0
    Soft SIA disabled
    NSF-aware route hold timer is 240
    Router-ID: 2.2.2.2
    Topology : 0 (base)
      Active Timer: 3 min
      Distance: internal 90 external 170
      Maximum path: 4
      Maximum hopcount 100
      Maximum metric variance 1

  Automatic Summarization: disabled
  Maximum path: 4
  Routing for Networks:
    2.2.2.2/32
    10.2.2.0/24
    172.16.1.0/30
    192.168.1.0/30
  Routing Information Sources:
    Gateway         Distance      Last Update
    192.168.1.1           90      00:14:35
    172.16.1.1            90      00:05:35
  Distance: internal 90 external 170

R2#sh ip eigrp nei
EIGRP-IPv4 Neighbors for AS(1)
H   Address                 Interface              Hold Uptime   SRTT   RTO  Q  Seq
                                                   (sec)         (ms)       Cnt Num
0   172.16.1.1              Se1/0                    10 00:15:06   19   114  0  13
R2#sh ip eigrp int
EIGRP-IPv4 Interfaces for AS(1)
                              Xmit Queue   PeerQ        Mean   Pacing Time   Multicast    Pending
Interface              Peers  Un/Reliable  Un/Reliable  SRTT   Un/Reliable   Flow Timer   Routes
Lo0                      0        0/0       0/0           0       0/0            0           0
Et0/0                    0        0/0       0/0           0       0/0            0           0
Se1/0                    1        0/0       0/0          19       0/16          92           0
Et0/1                    0        0/0       0/0           0       0/2           50           0
R2#sh ip eigrp topo
EIGRP-IPv4 Topology Table for AS(1)/ID(2.2.2.2)
Codes: P - Passive, A - Active, U - Update, Q - Query, R - Reply,
       r - reply Status, s - sia Status

P 10.2.2.0/24, 1 successors, FD is 281600
        via Connected, Ethernet0/0
P 192.168.1.0/30, 1 successors, FD is 281600
        via Connected, Ethernet0/1
P 2.2.2.2/32, 1 successors, FD is 128256
        via Connected, Loopback0
P 172.16.1.0/30, 1 successors, FD is 2169856
        via Connected, Serial1/0
P 10.1.1.0/24, 1 successors, FD is 307200
        via 172.16.1.1 (2195456/281600), Serial1/0
P 1.1.1.1/32, 1 successors, FD is 435200
        via 172.16.1.1 (2297856/128256), Serial1/0

R2#sh ip route
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
       a - application route
       + - replicated route, % - next hop override

Gateway of last resort is not set

      1.0.0.0/32 is subnetted, 1 subnets
D        1.1.1.1 [90/2297856] via 172.16.1.1, 00:05:35, Serial1/0
      2.0.0.0/32 is subnetted, 1 subnets
C        2.2.2.2 is directly connected, Loopback0
      10.0.0.0/8 is variably subnetted, 3 subnets, 2 masks
D        10.1.1.0/24 [90/2195456] via 172.16.1.1, 00:05:35, Serial1/0
C        10.2.2.0/24 is directly connected, Ethernet0/0
L        10.2.2.1/32 is directly connected, Ethernet0/0
      172.16.0.0/16 is variably subnetted, 2 subnets, 2 masks
C        172.16.1.0/30 is directly connected, Serial1/0
L        172.16.1.2/32 is directly connected, Serial1/0
      192.168.1.0/24 is variably subnetted, 2 subnets, 2 masks
C        192.168.1.0/30 is directly connected, Ethernet0/1
L        192.168.1.2/32 is directly connected, Ethernet0/1
R2#sh ip route eigrp
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
       a - application route
       + - replicated route, % - next hop override

Gateway of last resort is not set

      1.0.0.0/32 is subnetted, 1 subnets
D        1.1.1.1 [90/2297856] via 172.16.1.1, 00:05:35, Serial1/0
      10.0.0.0/8 is variably subnetted, 3 subnets, 2 masks
D        10.1.1.0/24 [90/2195456] via 172.16.1.1, 00:05:35, Serial1/0
```

On router R3, the configuration is:
```
R3#sh ip proto | b eigrp
Routing Protocol is "eigrp 10"
  Outgoing update filter list for all interfaces is not set
  Incoming update filter list for all interfaces is not set
  Default networks flagged in outgoing updates
  Default networks accepted from incoming updates
  EIGRP-IPv4 Protocol for AS(10)
    Metric weight K1=1, K2=0, K3=1, K4=0, K5=0
    Soft SIA disabled
    NSF-aware route hold timer is 240
    Router-ID: 3.3.3.3
    Topology : 0 (base)
      Active Timer: 3 min
      Distance: internal 90 external 170
      Maximum path: 4
      Maximum hopcount 100
      Maximum metric variance 1

  Automatic Summarization: disabled
  Maximum path: 4
  Routing for Networks:
    3.3.3.3/32
    10.1.1.0/24
    192.168.1.0/30
  Routing Information Sources:
    Gateway         Distance      Last Update
  Distance: internal 90 external 170

R3#sh ip eigrp nei
EIGRP-IPv4 Neighbors for AS(10)
R3#sh ip eigrp int
EIGRP-IPv4 Interfaces for AS(10)
                              Xmit Queue   PeerQ        Mean   Pacing Time   Multicast    Pending
Interface              Peers  Un/Reliable  Un/Reliable  SRTT   Un/Reliable   Flow Timer   Routes
Et0/0                    0        0/0       0/0           0       0/0            0           0
Et0/1                    0        0/0       0/0           0       0/0            0           0
Lo0                      0        0/0       0/0           0       0/0            0           0
R3#sh ip eigrp topo
EIGRP-IPv4 Topology Table for AS(10)/ID(3.3.3.3)
Codes: P - Passive, A - Active, U - Update, Q - Query, R - Reply,
       r - reply Status, s - sia Status

P 192.168.1.0/30, 1 successors, FD is 281600
        via Connected, Ethernet0/1
P 3.3.3.3/32, 1 successors, FD is 128256
        via Connected, Loopback0
P 10.1.1.0/24, 1 successors, FD is 281600
        via Connected, Ethernet0/0

R3#sh ip route
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
       a - application route
       + - replicated route, % - next hop override

Gateway of last resort is not set

      3.0.0.0/32 is subnetted, 1 subnets
C        3.3.3.3 is directly connected, Loopback0
      10.0.0.0/8 is variably subnetted, 2 subnets, 2 masks
C        10.1.1.0/24 is directly connected, Ethernet0/0
L        10.1.1.2/32 is directly connected, Ethernet0/0
      192.168.1.0/24 is variably subnetted, 2 subnets, 2 masks
C        192.168.1.0/30 is directly connected, Ethernet0/1
L        192.168.1.1/32 is directly connected, Ethernet0/1
R3#sh ip route eigrp
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
       a - application route
       + - replicated route, % - next hop override

Gateway of last resort is not set
```

We can see that R3 has learnt no routes and none of the other routers have learnt routes from it. This would indicate an issue with the EIGRP process running on R3. Upon careful inspection, we see that the Autonomous System number is `10` on R3 while it's `1` on the rest of the routers. Since in EIGRP, the autonomous system number must match between neighbours, this would stop R3 from becoming a neighbour with R1 and R2 as we see in the example above.

Since the network statements are correct, we can simply copy them from the running config and paste them for the correct AS:
```
R3#sh run | s router eigrp
router eigrp 10
 network 3.3.3.3 0.0.0.0
 network 10.1.1.0 0.0.0.255
 network 192.168.1.0 0.0.0.3
```
Now we create the correct AS with `AS(1)` and paste the network statements:
```
R3(config)#router eigrp 1
R3(config-router)# network 3.3.3.3 0.0.0.0
R3(config-router)# network 10.1.1.0 0.0.0.255
R3(config-router)# network 192.168.1.0 0.0.0.3
*Dec 31 07:08:03.789: %DUAL-5-NBRCHANGE: EIGRP-IPv4 1: Neighbor 10.1.1.1 (Ethernet0/0) is up: new adjacency
*Dec 31 07:08:08.817: %DUAL-5-NBRCHANGE: EIGRP-IPv4 1: Neighbor 192.168.1.2 (Ethernet0/1) is up: new adjacency
R3(config-router)#exit
R3(config)#no router eigrp 10
```
We just saw the two adjacencies with R1 and R2 come up. Now we can check the neibourship to ensure everything is correct:
```
R3#sh ip eigrp nei
EIGRP-IPv4 Neighbors for AS(1)
H   Address                 Interface              Hold Uptime   SRTT   RTO  Q  Seq
                                                   (sec)         (ms)       Cnt Num
1   192.168.1.2             Et0/1                    10 00:01:42    9   100  0  22
0   10.1.1.1                Et0/0                    14 00:01:47   10   100  0  20
```

Initially we couldn't see the `3.3.3.3` network on R1. Now, we should be able to:
```
R1#sh ip route eigrp
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
       a - application route
       + - replicated route, % - next hop override

Gateway of last resort is not set

      2.0.0.0/32 is subnetted, 1 subnets
D        2.2.2.2 [90/435200] via 10.1.1.2, 00:03:17, Ethernet0/0
      3.0.0.0/32 is subnetted, 1 subnets
D        3.3.3.3 [90/409600] via 10.1.1.2, 00:03:17, Ethernet0/0
      10.0.0.0/8 is variably subnetted, 3 subnets, 2 masks
D        10.2.2.0/24 [90/332800] via 10.1.1.2, 00:03:17, Ethernet0/0
      192.168.1.0/30 is subnetted, 1 subnets
D        192.168.1.0 [90/307200] via 10.1.1.2, 00:03:17, Ethernet0/0
```

# EIGRP Troubleshooting Exercise 2
In this trouble ticket, the users connected to sw1 can't communicate with user on sw2. We have the configuration for PC1 and PC2 as:
```
PC-1> sh ip
NAME        : PC-1[1]
IP/MASK     : 10.1.1.3/24
GATEWAY     : 10.1.1.1
DNS         :
MAC         : 00:50:79:66:68:00
LPORT       : 10002
RHOST:PORT  : 127.0.0.1:10003
MTU:        : 1500

PC-2> sh ip
NAME        : PC-2[1]
IP/MASK     : 10.2.2.2/24
GATEWAY     : 10.2.2.1
DNS         :
MAC         : 00:50:79:66:68:01
LPORT       : 10004
RHOST:PORT  : 127.0.0.1:10005
MTU:        : 1500
```

First we verify the problem and then check if each PC can reach their respective gateways:
```
PC-1> ping 10.2.2.1
*10.1.1.1 icmp_seq=1 ttl=255 time=0.999 ms (ICMP type:3, code:1, Destination host unreachable)
*10.1.1.1 icmp_seq=2 ttl=255 time=0.995 ms (ICMP type:3, code:1, Destination host unreachable)
*10.1.1.1 icmp_seq=3 ttl=255 time=1.002 ms (ICMP type:3, code:1, Destination host unreachable)
*10.1.1.1 icmp_seq=4 ttl=255 time=1.835 ms (ICMP type:3, code:1, Destination host unreachable)
*10.1.1.1 icmp_seq=5 ttl=255 time=2.011 ms (ICMP type:3, code:1, Destination host unreachable)
PC-1> ping 10.1.1.1
84 bytes from 10.1.1.1 icmp_seq=1 ttl=255 time=1.838 ms
84 bytes from 10.1.1.1 icmp_seq=2 ttl=255 time=1.838 ms

PC-2> ping 10.2.2.1
84 bytes from 10.2.2.1 icmp_seq=1 ttl=255 time=1.831 ms
84 bytes from 10.2.2.1 icmp_seq=2 ttl=255 time=1.982 ms
```

Our next step should be to see if PC2 is reachable from either R1 or R3:
```
R1#ping 10.2.2.1
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.2.2.1, timeout is 2 seconds:
.....
Success rate is 0 percent (0/5)

R3#ping 10.2.2.1
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.2.2.1, timeout is 2 seconds:
.....
Success rate is 0 percent (0/5)
```

Now since we aren't able to ping `10.2.2.1`, we need to confirm if R2 is a neighbour on either router:
```
R1#sh ip eigrp nei
EIGRP-IPv4 Neighbors for AS(1)
H   Address                 Interface              Hold Uptime   SRTT   RTO  Q  Seq
                                                   (sec)         (ms)       Cnt Num
1   10.1.1.2                Et0/0                    13 00:04:18   10   100  0  8
0   172.16.1.2              Se1/0                    10 00:04:46   18   108  0  11
R1#sh ip eigrp topo
EIGRP-IPv4 Topology Table for AS(1)/ID(1.1.1.1)
Codes: P - Passive, A - Active, U - Update, Q - Query, R - Reply,
       r - reply Status, s - sia Status
P 192.168.1.0/30, 1 successors, FD is 307200
        via 10.1.1.2 (307200/281600), Ethernet0/0
        via 172.16.1.2 (2195456/281600), Serial1/0
P 2.2.2.2/32, 1 successors, FD is 435200
        via 10.1.1.2 (435200/409600), Ethernet0/0
        via 172.16.1.2 (2297856/128256), Serial1/0
P 172.16.1.0/30, 1 successors, FD is 2169856
        via Connected, Serial1/0
P 3.3.3.3/32, 1 successors, FD is 409600
        via 10.1.1.2 (409600/128256), Ethernet0/0
P 10.1.1.0/24, 1 successors, FD is 281600
        via Connected, Ethernet0/0
P 1.1.1.1/32, 1 successors, FD is 128256
        via Connected, Loopback0
R1#sh ip route eigrp
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
       a - application route
       + - replicated route, % - next hop override
Gateway of last resort is not set
      2.0.0.0/32 is subnetted, 1 subnets
D        2.2.2.2 [90/435200] via 10.1.1.2, 00:04:39, Ethernet0/0
      3.0.0.0/32 is subnetted, 1 subnets
D        3.3.3.3 [90/409600] via 10.1.1.2, 00:04:39, Ethernet0/0
      192.168.1.0/30 is subnetted, 1 subnets
D        192.168.1.0 [90/307200] via 10.1.1.2, 00:04:39, Ethernet0/0
R1#sh ip route 10.2.2.1
% Subnet not in table

R3#sh ip eigrp nei
EIGRP-IPv4 Neighbors for AS(1)
H   Address                 Interface              Hold Uptime   SRTT   RTO  Q  Seq
                                                   (sec)         (ms)       Cnt Num
1   10.1.1.1                Et0/0                    14 00:05:59 1603  5000  0  9
0   192.168.1.2             Et0/1                    14 00:06:27    2   100  0  10
R3#sh ip eigrp topo
EIGRP-IPv4 Topology Table for AS(1)/ID(3.3.3.3)
Codes: P - Passive, A - Active, U - Update, Q - Query, R - Reply,
       r - reply Status, s - sia Status
P 192.168.1.0/30, 1 successors, FD is 281600
        via Connected, Ethernet0/1
P 2.2.2.2/32, 1 successors, FD is 409600
        via 192.168.1.2 (409600/128256), Ethernet0/1
P 172.16.1.0/30, 2 successors, FD is 2195456
        via 10.1.1.1 (2195456/2169856), Ethernet0/0
        via 192.168.1.2 (2195456/2169856), Ethernet0/1
P 3.3.3.3/32, 1 successors, FD is 128256
        via Connected, Loopback0
P 10.1.1.0/24, 1 successors, FD is 281600
        via Connected, Ethernet0/0
P 1.1.1.1/32, 1 successors, FD is 409600
        via 10.1.1.1 (409600/128256), Ethernet0/0
R3#sh ip route eigrp
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
       a - application route
       + - replicated route, % - next hop override
Gateway of last resort is not set
      1.0.0.0/32 is subnetted, 1 subnets
D        1.1.1.1 [90/409600] via 10.1.1.1, 00:06:07, Ethernet0/0
      2.0.0.0/32 is subnetted, 1 subnets
D        2.2.2.2 [90/409600] via 192.168.1.2, 00:06:35, Ethernet0/1
      172.16.0.0/30 is subnetted, 1 subnets
D        172.16.1.0 [90/2195456] via 192.168.1.2, 00:06:07, Ethernet0/1
                    [90/2195456] via 10.1.1.1, 00:06:07, Ethernet0/0
R3#sh ip route 10.2.2.1
% Subnet not in table
```
We can see from the above output that R2 is a neighbour for both routers R1 and R3, but for some reason we don't have a route for the `10.2.2.0` subnet in the routing tables or the known-EIGRP routes, while the other routes from R2 are there.

This means we should check the EIGRP configuration on R2, specifically, which networks are being advertised and which interfaces are participating in EIGRP:
```
R2#sh ip eigrp int
EIGRP-IPv4 Interfaces for AS(1)
                              Xmit Queue   PeerQ        Mean   Pacing Time   Multicast    Pending
Interface              Peers  Un/Reliable  Un/Reliable  SRTT   Un/Reliable   Flow Timer   Routes
Lo0                      0        0/0       0/0           0       0/0            0           0
Se1/0                    1        0/0       0/0          19       0/16          92           0
Et0/1                    1        0/0       0/0          11       0/2           50           0
R2#sh ip proto | b eigrp
Routing Protocol is "eigrp 1"
  Outgoing update filter list for all interfaces is not set
  Incoming update filter list for all interfaces is not set
  Default networks flagged in outgoing updates
  Default networks accepted from incoming updates
  EIGRP-IPv4 Protocol for AS(1)
    Metric weight K1=1, K2=0, K3=1, K4=0, K5=0
    Soft SIA disabled
    NSF-aware route hold timer is 240
    Router-ID: 2.2.2.2
    Topology : 0 (base)
      Active Timer: 3 min
      Distance: internal 90 external 170
      Maximum path: 4
      Maximum hopcount 100
      Maximum metric variance 1

  Automatic Summarization: disabled
  Maximum path: 4
  Routing for Networks:
    2.2.2.2/32
    172.16.1.0/30
    192.168.1.0/30
  Routing Information Sources:
    Gateway         Distance      Last Update
    192.168.1.1           90      00:09:24
    172.16.1.1            90      00:09:24
  Distance: internal 90 external 170
```
We can see from the above output that the `10.2.2.0/24` network isn't participating in EIGRP and neither is the interface it's directly connected to, **R2 E0/0**.

Now we check the actual EIGRP configuration on R2:
```
R2#sh run | s router eigrp
router eigrp 1
 network 2.2.2.2 0.0.0.0
 network 172.16.1.0 0.0.0.3
 network 192.168.1.0 0.0.0.3
```
We can see that we're missing the `network 10.2.2.0 0.0.0.255` statement. If we add this, everything should be working correctly:
```
R2(config)#router eigrp 1
R2(config-router)#network 10.2.2.0 0.0.0.255
R2(config-router)#do sh ip proto | b eigrp
Routing Protocol is "eigrp 1"
  Outgoing update filter list for all interfaces is not set
  Incoming update filter list for all interfaces is not set
  Default networks flagged in outgoing updates
  Default networks accepted from incoming updates
  EIGRP-IPv4 Protocol for AS(1)
    Metric weight K1=1, K2=0, K3=1, K4=0, K5=0
    Soft SIA disabled
    NSF-aware route hold timer is 240
    Router-ID: 2.2.2.2
    Topology : 0 (base)
      Active Timer: 3 min
      Distance: internal 90 external 170
      Maximum path: 4
      Maximum hopcount 100
      Maximum metric variance 1

  Automatic Summarization: disabled
  Maximum path: 4
  Routing for Networks:
    2.2.2.2/32
    10.2.2.0/24
    172.16.1.0/30
    192.168.1.0/30
  Routing Information Sources:
    Gateway         Distance      Last Update
    192.168.1.1           90      00:12:45
    172.16.1.1            90      00:12:45
  Distance: internal 90 external 170
```
We can see that now EIGRP is advertising the network.

We check if PC-1 can now ping PC-2:
```
PC-1> ping 10.2.2.2
10.2.2.2 icmp_seq=1 timeout
10.2.2.2 icmp_seq=2 timeout
84 bytes from 10.2.2.2 icmp_seq=3 ttl=62 time=4.129 ms
84 bytes from 10.2.2.2 icmp_seq=4 ttl=62 time=5.336 ms
84 bytes from 10.2.2.2 icmp_seq=5 ttl=62 time=3.952 ms
```
The first two timeouts were due to the ARPing process.

We can also confirm that R1 and R3 know about the `10.2.2.0/24` network:
```
R1#sh ip route 10.2.2.2
Routing entry for 10.2.2.0/24
  Known via "eigrp 1", distance 90, metric 332800, type internal
  Redistributing via eigrp 1
  Last update from 10.1.1.2 on Ethernet0/0, 00:03:35 ago
  Routing Descriptor Blocks:
  * 10.1.1.2, from 10.1.1.2, 00:03:35 ago, via Ethernet0/0
      Route metric is 332800, traffic share count is 1
      Total delay is 3000 microseconds, minimum bandwidth is 10000 Kbit
      Reliability 255/255, minimum MTU 1500 bytes
      Loading 1/255, Hops 2

R3#sh ip route 10.2.2.2
Routing entry for 10.2.2.0/24
  Known via "eigrp 1", distance 90, metric 307200, type internal
  Redistributing via eigrp 1
  Last update from 192.168.1.2 on Ethernet0/1, 00:03:16 ago
  Routing Descriptor Blocks:
  * 192.168.1.2, from 192.168.1.2, 00:03:16 ago, via Ethernet0/1
      Route metric is 307200, traffic share count is 1
      Total delay is 2000 microseconds, minimum bandwidth is 10000 Kbit
      Reliability 255/255, minimum MTU 1500 bytes
      Loading 1/255, Hops 1
```

# Wide Area Networks (_WANs_)
# Point to Point Protocol (_PPP_)
**Point-to-Point Protocol (_PPP_)** is a protocol meant to run between two devices that share a point-to-point connection. For point to multipoint networks, we also have the **Multi-Link Point-to-Point Protocol (_MLPPP_)**. Finally, there's also a protocol called **Point-to-Point over Ethernet Protocol (_PPPoE_)** that lets us configure and run Point-to-Point Protocol over an Ethernet network.

# Configuring and Verifying PPP and MLPPP
The default Layer 2 encapsulation on Cisco's Serial Interfaces is called **High-level Data Link Control (_HDLC_)**. An alternative to this is the **Point to Point (_PPP_)** protocol. It is commonly used on leased lines that connect two sites of the same enterprise and supports:
* Authentication with PAP/CHAP
* Data Compression
* Error Checking and Correction
* Combining multiple physical interfaces into a single logical interface called a _multilink interface_.

## Sub-Protocols
Some of the important protocols that work in conjunction with each other and PPP to provide the functionality of PPP are:
* **Link Control Protocol (_LCP_)** - This is the protocol used by PPP to setup, destroy or maintain the connections.
* **Network Control Protocols (_NCPs_)** - There are several different NCPs, one for each protocol used, that negotiates the configuration of that protocol. PPP can support multiple Layer 3 and 2 protocols, and each of the protocols that are encapsulated by PPP is given their own NCP to control that protocol. For ex, IP has **IPCP (_IP Control Protocol_)** and CDP has **CPDCP (_CDP Control Protocol_)**.

Let us consider we want to configure PPP on the two serial links shown above. First of all we have to switch from the default HDLC to PPP encapsulation:
```
R1(config)#int s1/0
R1(config-if)#encap ppp
*Dec 31 10:49:22.024: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/0, changed state to down
R1(config-if)#int s1/1
R1(config-if)#encap ppp
*Dec 31 10:49:40.785: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/1, changed state to down
```
The interface just went down since the other ends of the links are still configured to be HDLC. We have to change that:
```
R2(config)#int s1/0
R2(config-if)#encap ppp
*Dec 31 10:51:00.837: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/0, changed state to up
R2(config-if)#int s1/1
R2(config-if)#encap ppp
*Dec 31 10:51:09.549: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/1, changed state to up
```

We can now confirm that we're up at both layer 1 and 2, and then also confirm that PPP is the protocol being used:
```
R2#sh ip int br | e un
Interface                  IP-Address      OK? Method Status                Protocol
Serial1/0                  10.1.1.2        YES manual up                    up      
Serial1/1                  10.1.1.6        YES manual up                    up      

R2#sh int s1/0
Serial1/0 is up, line protocol is up
  Hardware is M4T
  Description: S0 Con to R1
  Internet address is 10.1.1.2/30
  MTU 1500 bytes, BW 1544 Kbit/sec, DLY 20000 usec,
     reliability 255/255, txload 1/255, rxload 1/255
  Encapsulation PPP, LCP Open
  Open: IPCP, CDPCP, crc 16, loopback not set
  Keepalive set (10 sec)
  Restart-Delay is 0 secs
  Last input 00:00:09, output 00:00:09, output hang never
  Last clearing of "show interface" counters 00:02:51
  Input queue: 0/75/0/0 (size/max/drops/flushes); Total output drops: 0
  Queuing strategy: fifo
  Output queue: 0/40 (size/max)
  5 minute input rate 0 bits/sec, 0 packets/sec
  5 minute output rate 0 bits/sec, 0 packets/sec
     43 packets input, 2326 bytes, 0 no buffer
     Received 0 broadcasts (0 IP multicasts)
     0 runts, 0 giants, 0 throttles
     0 input errors, 0 CRC, 0 frame, 0 overrun, 0 ignored, 0 abort
     43 packets output, 2326 bytes, 0 underruns
     0 output errors, 0 collisions, 0 interface resets
     0 unknown protocol drops
     0 output buffer failures, 0 output buffers swapped out
     0 carrier transitions     DCD=up  DSR=up  DTR=up  RTS=up  CTS=up
```
In the above output we can also see the NCPs being used : _IPCP_ and _CDPCP_.

## Authentication
We'll set up PAP on the first link, i.e., S1/0 on either router, and CHAP on S1/1 of either router.

### Password Authentication Protocol (_PAP_)
A relatively unsecure protocol used by PPP that sends the PAP password accross the network to the server for authentication in clear-text. PAP only allows one-way authentication, and hence we'll set R1 as our auth server and R2 as the auth-client. First we set the global PAP username and password on the server:
```
R1(config)#username papuser password pappass
R1(config)#int s1/0
R1(config-if)#ppp authentication pap
*Dec 31 11:00:33.354: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/0, changed state to down
```
The link layer immediately went down because we aren't authenticated yet. To do so, we go to R2, i.e., the client:
```
R2(config)#int s1/0
R2(config-if)#ppp pap sent-username papuser password pappass
*Dec 31 11:02:43.164: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/0, changed state to up
```
We're now authenticated and hence layer 2 went back up.

The PAP server just sent the PAP client a challenge user-name and asked for the password for that user. Hence, the `sent-username` section is required. We can actually see this happening if we have debugging turned on:
```
R2(config-if)#do debug ppp authentication
PPP authentication debugging is on
R2(config-if)#shut
*Dec 31 11:07:50.247: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/0, changed state to down
*Dec 31 11:07:50.247: %LINK-5-CHANGED: Interface Serial1/0, changed state to administratively down
R2(config-if)#no shut
*Dec 31 11:07:54.888: %LINK-3-UPDOWN: Interface Serial1/0, changed state to up
*Dec 31 11:07:54.888: Se1/0 PPP: Using default call direction
*Dec 31 11:07:54.888: Se1/0 PPP: Treating connection as a dedicated line
*Dec 31 11:07:54.888: Se1/0 PPP: Session handle[F4000008] Session id[7]
*Dec 31 11:07:54.923: Se1/0 PPP: No authorization without authentication
*Dec 31 11:07:54.923: Se1/0 PAP: Using hostname from interface PAP
*Dec 31 11:07:54.923: Se1/0 PAP: Using password from interface PAP
*Dec 31 11:07:54.923: Se1/0 PAP: O AUTH-REQ id 1 len 20 from "papuser"
*Dec 31 11:07:54.939: Se1/0 PAP: I AUTH-ACK id 1 len 5
*Dec 31 11:07:54.939: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/0, changed state to up
R2(config-if)#do u all
All possible debugging has been turned off
```
The `O AUTH-REQ id 1 len 20 from "papuser"` statement means we're being challenged by _papuser_, the username on the auth server, in reply to which we provide the password. Once successful, an acknowledgement was sent via the server, `I AUTH-ACK id 1 len 5` and then layer 2 came back up.

### Challenge Handshake Authentication Protocol (_CHAP_)
CHAP is a secure protocol used by PPP that first calculates the hash of a password and then sends the hash across the network for comparison and authentication. Unlike PAP, CHAP provides 2-way authentication, i.e., both the routers authenticate to each others. On Router R1, we need to create a username for the other router, i.e., `R2` that wants to authenticate with R1. The passwords are going to match on both routers, but the usernames will vary:
```
R1(config)#username R2 password chappass
R1(config)#int s1/1
R1(config-if)#ppp authentication chap
*Dec 31 11:27:36.095: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/1, changed state to down
```

Now, we need to create a user called `R1` on router R2 and set the same password on it. Then, we'll enable CHAP on **R2 S1/1** as well:
```
R2(config)#username R1 password chappass
*Dec 31 11:29:51.327: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/1, changed state to up
R2(config)#int s1/1
R2(config-if)#ppp authentication chap
*Dec 31 11:30:47.909: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/1, changed state to down
*Dec 31 11:30:47.964: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/1, changed state to up
```
Once the interface bounces, the authentication is complete and the authentication is set up completely.

We can now confirm that both of our serial interfaces are up at both layer 1 and 2:
```
R2#sh ip int br | e un
Interface                  IP-Address      OK? Method Status                Protocol
Serial1/0                  10.1.1.2        YES manual up                    up      
Serial1/1                  10.1.1.6        YES manual up                    up      
```

## Compression
Can be of two types - software compression and hardware compression. In software compression, the router's processor has to be involved in the compression of the data packets prior to transmission over the wire. In case of heavy traffic flow over the router, this can be very taxing on the resources of the router. Almost all Cisco routers can do software compression, but some even support hardware compression, where the task of data compression is offloaded to a dedicated chip/circuit and thus the processor's resources aren't consumed. Due to the relative scarcity of processing power as compared to the available bandwidth, we generally don't have to use this feature. Some variants of the compression algorithm provided are:
* MPPC compression Algorithm
* Predictor Compression Type
* Stac Compression Algorithm

Cisco suggests that we use the Stac compression since it's the most versatile, and so, we'll set it up on S1/0 of R1 and R2. All we need to do is use the command `compress stac`:
```
R1(config)#int s1/0
R1(config-if)#comp stac

R2(config)#int s1/0
R2(config-if)#comp stac
```

Data via S1/0 will now be compressed and then sent. We can test this by first sending large packets via ping and then comparing the compressed and uncompressed bytes:
```
R1#ping 10.1.1.2 size 1500
Type escape sequence to abort.
Sending 5, 1500-byte ICMP Echos to 10.1.1.2, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 12/12/14 ms
R1#show compress
 Serial1/0
         Software compression enabled
         uncompressed bytes xmt/rcv 7510/7510
         compressed bytes   xmt/rcv 371/381
         Compressed bytes sent:       371 bytes   0 Kbits/sec  ratio: 20.242
         Compressed bytes recv:       381 bytes   0 Kbits/sec  ratio: 19.711
         1  min avg ratio xmt/rcv 8.682/9.907
         5  min avg ratio xmt/rcv 2.135/2.549
         10 min avg ratio xmt/rcv 2.135/2.549
         no bufs xmt 0 no bufs rcv 0
         resyncs 1
         Additional Stac Stats:
         Transmit bytes:  Uncompressed =        0 Compressed =        371
         Received bytes:  Compressed =        386 Uncompressed =        0
```
The stac algorithm compressed our `7510B` packets to `371B`. The compression ratio depends upon the file type.

## Error Detection and Correction
This features enables the routers involved in PPP to take a look at the Layer 2 frame and if an error is detected, the frame is discarded and re-transmitted. It's extremely simple to turn on using `ppp reliable-link` command:
```
R1(config-if)#ppp reliabl  
R1(config-if)#ppp reliable-link
*Dec 31 11:46:31.033: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/0, changed state to down
*Dec 31 11:46:31.101: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/0, changed state to up

R2(config)#int s1/0
R2(config-if)#ppp reli  
*Dec 31 11:46:45.543: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/0, changed state to down
*Dec 31 11:47:01.815: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/0, changed state to up
```

We can now confirm that the reliable link is on, since the output of the show interface command will now contain an extra block:
```
R1#sh int s1/0
Serial1/0 is up, line protocol is up
  Hardware is M4T
  Description: S0 con to R2
  Internet address is 10.1.1.1/30
  MTU 1500 bytes, BW 1544 Kbit/sec, DLY 20000 usec,
     reliability 255/255, txload 1/255, rxload 1/255
  Encapsulation PPP, LCP Open
  Open: IPCP, CCP, CDPCP
  LAPB DTE, state CONNECT, modulo 8, k 7, N1 12080, N2 3
      T1 3000, T2 0, interface outage (partial T3) 0, T4 0, PPP over LAPB
      VS 0, VR 6, tx NR 6, Remote VR 0, Retransmissions 0
      Queues: U/S frames 0, I frames 0, unack. 0, reTx 0
      IFRAMEs 56/46 RNRs 0/0 REJs 0/0 SABM/Es 1/0 FRMRs 0/0 DISCs 0/0, crc 16, loopback not set
  Keepalive set (10 sec)
  Restart-Delay is 0 secs
  Last input 00:00:07, output 00:00:07, output hang never
  Last clearing of "show interface" counters 00:59:49
  Input queue: 0/75/0/0 (size/max/drops/flushes); Total output drops: 0
  Queuing strategy: fifo
  Output queue: 0/40 (size/max)
  5 minute input rate 0 bits/sec, 0 packets/sec
  5 minute output rate 0 bits/sec, 0 packets/sec
     936 packets input, 36428 bytes, 0 no buffer
     Received 0 broadcasts (0 IP multicasts)
     0 runts, 0 giants, 0 throttles
     0 input errors, 0 CRC, 0 frame, 0 overrun, 0 ignored, 0 abort
     1032 packets output, 39376 bytes, 0 underruns
     0 output errors, 0 collisions, 8 interface resets
     12 unknown protocol drops
     0 output buffer failures, 0 output buffers swapped out
     8 carrier transitions     DCD=up  DSR=up  DTR=up  RTS=up  CTS=up
```
The `reTx 0` value tells us if we've retransmitted any frames.

**Note** this feature doesn't work with MLPPP and hence has to be turned off before MLPPP can be activated.

## Multiple Link support
Using the **Multi-Link Point-to-Point (_MLPPP_)**, several physical links can be logically combined to form a single logical link. While the concept is similar to EtherChannels or Port-Channels, MLPPP supports the bonding of interfaces of different speeds to form the logical link. Further, Port-Channels are only available for Ethernet networks while Multi-Link PPP is available for Point to Point networks. The MLPPP also does load-balancing across all the physical interfaces that make up the logical interface.

To configure one, we just make a new (virtual/logical) multilink interface in configuration mode. Then, we assign an IP to it from one of the links we're combining since the individual physical links won't have their own IP address but just the IP address of the virtual link. We then convert it into a PPP multilink interface by using the `ppp multilink` statement. At this point, our multilink interface is ready for the physical links to join it's multilink group (i.e., _group 1_):
```
R1(config)#int multilink 1
R1(config-if)#ip addr 10.1.1.1 255.255.255.252
% 10.1.1.0 overlaps with Serial1/0
R1(config-if)#ppp multilink
R1(config-if)#exit
R1(config)#int s1/0
R1(config-if)#no ip addr
R1(config-if)#ppp multilink group 1
*Dec 31 12:46:18.826: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/0, changed state to down
*Dec 31 12:46:18.877: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/0, changed state to up
R1(config-if)#int s1/1
R1(config-if)#no ip addr
R1(config-if)#ppp mul gr 1
*Dec 31 12:46:27.692: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/1, changed state to down
*Dec 31 12:46:27.745: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/1, changed state to up
```
The `ppp multilink group 1` command asks the interface to join the _multilink group_ of interface _Multilink1_.

Now we configure the same settings on R2:
```
R2(config)#int multi 1
R2(config-if)#ppp multilink
R2(config-if)#ip addr 10.1.1.2 255.255.255.252
% 10.1.1.0 overlaps with Serial1/0
R2(config-if)#int s1/0
R2(config-if)#no ip addr
R2(config-if)#ppp multilink group 1
R2(config-if)#
*Dec 31 12:49:24.680: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/0, changed state to down
*Dec 31 12:49:24.728: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/0, changed state to up
*Dec 31 12:49:24.743: %LINEPROTO-5-UPDOWN: Line protocol on Interface Multilink1, changed state to down
*Dec 31 12:49:24.743: %LINK-3-UPDOWN: Interface Multilink1, changed state to up
*Dec 31 12:49:24.743: %LINEPROTO-5-UPDOWN: Line protocol on Interface Multilink1, changed state to up
R2(config-if)#int s1/1
R2(config-if)#no ip addr
R2(config-if)#ppp multilink gr 1
*Dec 31 12:49:40.312: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/1, changed state to down
*Dec 31 12:49:40.388: %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial1/1, changed state to up
```

We can now ping the over the multilink interface:
```
R2#ping 10.1.1.1
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.1.1.1, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 9/10/11 ms
```

# Configure and Verify PPPoE Client-side Interfaces
**Point-to-Point Protocol over Ethernet (_PPPoE_)** allows us to carry the PPP protocol over Ethernet frames so that we can get the features of PPP in an Ethernet network. Such a feature is authentication. In the case of residential **Digital Subscriber Line (_DSL_)** users, both their _land-line_ phone services and data services are connected via the same DSL modem. So, the DSL modem is connected to phones and/or computers or a router at the customer's side, and also a link leading to the **ISP (_Internet Service Provider_)**.

This link to the ISP leads to the ISP's **DSL Access Multiplexer (_DSLAM_)**. The link between the DSLAM and the DSL modem is set up to use PPPoE and this is one of the most common real-world use-case of PPPoE. We have to use this because Ethernet by itself has no authentication mechanism. While only the client-side configuration is required for CCNA, to emulate the connection in a lab, it's useful to know the server config as well.

## Server Config on ISP Router
There are six steps in configuring the ISP router for PPPoE:
* Set up the username & password with which the user will authenticate
* Set up a **dialer pool** - local IP pool (not DHCP pool) containing the IP addresses which'll be handed out the clients connecting to the router.
* Set up a _Virtual-Template_, assign an IP address to it for connection and associate it to distribute IP address from the pool
* Set up the same Virtual-Template to for _CHAP callin_ authentication
* Assign the Virtual-Templete to a _Broad-Band Access Group_.
* Assign the Broad-Band Access group to the ingress interface from which client's authentication requests will originate.

For the authentication, we need to set up the username and password with which the user will authenticate with CHAP. We can set it up with:
```
ISP(config)#username dsl_user password cisco
```

For the setup of `virtual-template1` we have to assign an IP address to it, specify a pool of IP addresses from which it can hand out IPs and set up the CHAP authentication for **callin**, i.e., authenticate remotely on incoming call only:
```
ISP(config)#ip local pool ISP_POOL 10.1.1.2 10.1.1.254
ISP(config)#int virtual-Template 1
ISP(config-if)#ip addr 10.1.1.1 255.255.255.0  
ISP(config-if)#peer default ip address pool ISP_POOL
ISP(config-if)#ppp authentication chap callin
```

We have to set up a **Broad-Band Access (_BBA_) Group** which will refer to `virtual-template1`:
```
ISP(config)#bba-group pppoe ISP_GROUP
*Jan  1 10:06:25.860: %LINEPROTO-5-UPDOWN: Line protocol on Interface Virtual-Access1, changed state to up
*Jan  1 10:06:25.860: %LINK-3-UPDOWN: Interface Virtual-Access1, changed state to up
ISP(config-bba-group)#virtual-template 1
```

Finally, on the ingress interface to the ISP router, we have to enable the PPPoE group:
```
ISP(config)#int e0/0
ISP(config-if)#pppoe enable group ISP_GROUP
ISP(config-if)#no shut
*Jan  1 10:42:20.789: %LINK-3-UPDOWN: Interface Ethernet0/0, changed state to up
*Jan  1 10:42:21.798: %LINEPROTO-5-UPDOWN: Line protocol on Interface Ethernet0/0, changed state to up
```

## Client-Side configuration
The first thing we have to do on the client is set up a **dialer interface**, which lets us specify various layer 2 and layer 3 parameters for the PPPoE connection. A _dialer interface_ is a logical interface that points to a **dialer pool**. This _dialer pool_ contains one or more physical interfaces. We'll be configuring our dialer interface to dynamically obtain an IP address from the PPPoE server via PPP's NCP of **IP Control Protocol (_IPCP_)** (instead of _DHCP_ which is used over Ethernet). We'd also set the MTU to `1492B`.  This is because the typical Ethernet (non-jumbo) frames have an MTU of `1500B` but our PPP header is of `8B`. We'd like to avoid the processor overhead of frame fragmentation which will be caused by a frame of `1508B` while still accommodating the PPP header. Finally, we'll ask the dialer interface to use the PPP encapsulation:
```
R1(config)#int dialer 1
R1(config-if)#ip address negotiated
R1(config-if)#mtu 1492
R1(config-if)#encap ppp
```

Now we can configure the authentication on R1, using the username we defined on the ISP router. In our case, it's `dsl_user` with a password of `cisco`:
```
R1(config-if)#ppp chap hostname dsl_user
R1(config-if)#ppp chap password cisco
```

The way we use the dialer interface is by associating with a dialer pool and then also associating a physical interface with the same dialer pool.  Once done, we can bring up the physical interface:
```
R1(config)#int dialer1
R1(config-if)#dialer pool 10
R1(config-if)#int e0/0
R1(config-if)#pppoe-client dial-pool-number 10
R1(config-if)#no shut
R1(config-if)#
*Jan  1 11:04:38.832: %LINK-3-UPDOWN: Interface Ethernet0/0, changed state to up
*Jan  1 11:04:39.841: %LINEPROTO-5-UPDOWN: Line protocol on Interface Ethernet0/0, changed state to up
*Jan  1 11:05:02.483: %DIALER-6-BIND: Interface Vi1 bound to profile Di1
*Jan  1 11:05:02.489: %LINK-3-UPDOWN: Interface Virtual-Access1, changed state to up
*Jan  1 11:05:02.521: %LINEPROTO-5-UPDOWN: Line protocol on Interface Virtual-Access1, changed state to up
```

At this point, our configuration is complete and our router R1 was able to authenticate with the ISP server and get a dynamic IP address via IPCP:
```
R1#sh ip int br | e adm
Interface                  IP-Address      OK? Method Status                Protocol
Ethernet0/0                unassigned      YES NVRAM  up                    up      
Dialer1                    10.1.1.2        YES IPCP   up                    up      
Virtual-Access1            unassigned      YES unset  up                    up      
```

We can see the details of the dialer interface with the `sh interfaces dialer1` command:
```
R1#sh int Di1
Dialer1 is up, line protocol is up (spoofing)
  Hardware is Unknown
  Internet address is 10.1.1.2/32
  MTU 1492 bytes, BW 56 Kbit/, DLY 20000 usec,
     reliability 255/255, txload 1/255, rxload 1/255
  Encapsulation PPP, LCP Closed, loopback not set
  Keepalive set (10 sec)
  DTR is pulsed for 1 seconds on reset
  Interface is bound to Vi1
  Last input never, output never, output hang never
  Last clearing of "show interface" counters 00:11:33
  Input queue: 0/75/0/0 (size/max/drops/flushes); Total output drops: 0
  Queuing strategy: fifo
  Output queue: 0/40 (size/max)
  5 minute input rate 0 bits/sec, 0 packets/sec
  5 minute output rate 0 bits/sec, 0 packets/sec
     2 packets input, 28 bytes
     60 packets output, 840 bytes
Bound to:
Virtual-Access1 is up, line protocol is up
  Hardware is Virtual Access interface
  MTU 1492 bytes, BW 56 Kbit/sec, DLY 20000 usec,
     reliability 255/255, txload 1/255, rxload 1/255
  Encapsulation PPP, LCP Open
  Stopped: CDPCP
  Open: IPCP
  PPPoE vaccess, cloned from Dialer1
  Vaccess status 0x44, loopback not set
  Keepalive set (10 sec)
  DTR is pulsed for 5 seconds on reset
  Interface is bound to Di1 (Encapsulation PPP)
  Last input 00:00:05, output never, output hang never
  Last clearing of "show interface" counters 00:05:06
  Input queue: 0/75/0/0 (size/max/drops/flushes); Total output drops: 0
  Queuing strategy: fifo
  Output queue: 0/40 (size/max)
  5 minute input rate 0 bits/sec, 0 packets/sec
  5 minute output rate 0 bits/sec, 0 packets/sec
     68 packets input, 957 bytes, 0 no buffer
     Received 0 broadcasts (0 IP multicasts)
     0 runts, 0 giants, 0 throttles
     0 input errors, 0 CRC, 0 frame, 0 overrun, 0 ignored, 0 abort
     67 packets output, 950 bytes, 0 underruns
     0 output errors, 0 collisions, 0 interface resets
     0 unknown protocol drops
     0 output buffer failures, 0 output buffers swapped out
     0 carrier transitions
```

If we see the status of the interface, we see it's set to `Dialer1 is up, line protocol is up (spoofing)`. The _spoofing_ keyword indicates that the actual Layer 2 operation isn't being handled by the dialer interface, but by a _Virtual Access_ interface to which it is **bound**. The Vi1 interface itself has the status: `Virtual-Access1 is up, line protocol is up`. We can also see the IP address obtained in the process and the MTU size:
```
Internet address is 10.1.1.2/32
MTU 1492 bytes, BW 56 Kbit/sec, DLY 20000 usec,
```

We can also use the `show pppoe session` command:
```
R1#sh pppoe session
     1 client session

Uniq ID  PPPoE  RemMAC          Port                    VT  VA         State
           SID  LocMAC                                      VA-st      Type
    N/A      1  aabb.cc00.0200  Et0/0                   Di1 Vi1        UP      
                aabb.cc00.0100                              UP              
```
Here, we can see two different MAC addresses: the bottom MAC address, `aabb.cc00.0100` is the *local MAC* for the port **R1 e0/0** and the one above, `aabb.cc00.0200` is for **ISP e0/0** and is called the _remote MAC_. We can also see that the interface on R1 being used to connect to the ISP is `Et0/0`, or **R1 e0/0**.

# Troubleshooting PPP and PPPoE
Some common issues with PPP and PPPoE are:
- **Encapsulation Mismatch** - The default encapsulation for Cisco's Serial Interfaces is HDLC (High-level Data Link Control) Protocol, and not PPP. Hence, if one side is set to PPP and the other to HDLC, there's going to be an encapsulation mismatch and the PPP won't work.
- **Authentication Mismatch** - We have several options for the authentication : we can skip authentication by not configuring it or set it to PAP or CHAP. We should ensure that the same authenticaton method is used on either side of the Point to Point link. The username and password need to match up as well.
- **Dialer Interface Misconfiguration** - The Dialer interface may be pointing to the wrong dialer pool.
- **Dialer Pool Misconfig** - The *dialer pool* may be set up for the wrong IP address range on the ISP server.
- **Clocking on Physical Interface** - One side of a serial interface cable needs to send a clocking signal while the other side needs to synchronize itself on the basis of that clock signal. The side that provides the clocking signal is typically on the ISP side and is called **Data Circuit-Terminating Equipment (_DCE_)** while the side that receives the clocking signal is called the **Data Terminal Equipment (_DTE_)**. We need to ensure that the clock signal source of our serial connection is the DCE side while the recepient is the DTE side. The Serial cables themselves are labled with the DCE/DTE side labels.

## Checking Serial Interface Controllers
The `show controller <serialIntID>` command shows us which side we're on - the DCE or DTE:
```
R1# show controllers serial 0/1/0
Interface Serial0/1/0
Hardware is PowerQUICC MPC860
DTE V.35 clocks stopped.
...

ISP# show controllers serial 0/1/0
Interface Serial0/1/0
Hardware is PowerQUICC MPC860
DCE V.35, no clock
...
```

# Options for WAN Connectivity
# MPLS
**Multi Protocol Label Switching (_MPLS_)** is a WAN technology where forwarding decisions are made on the basis of a 20bit label stored in a 32bit header. In this system, the routers in a service provider's cloud can perform routing decisions on the basis of the label instead of the IP address stored in the layer 3 header. Originally, MPLS was designed since label switching was faster as opposed to forwarding based on IP, but given the increase in processing power and efficiency of modern routers, that may no longer be a factor. However, there are other advantages.

From a service provider's perspective, it becomes easier to separate the traffic of one customer from another customer's traffic simply on the basis of the labels. This gives us a very fine level of control over how traffic flows through a network. Quality of Service (QoS) control is another advantage since we can treat different types of traffic differently. MPLS can also interface with a wide number of protocols. If one customer uses ATM while another uses frame-relay, MPLS is still compatible with both simultaneously.

Typically in an IPv4 packet, there's a data payload that's encapsulated with the IP header on layer 3 to form the _IP packet_ and then again, the entire IP packet is encapsulated with the layer 2 header to form the layer 2 _frame_ before being sent out on the wire. MPLS inserts its own **32-bit header, called the shim header** in between the layer 2 and layer 3 headers, which contains the actual labels the routers in the service provider's MPLS cloud use to forward the packets. There are some important types of devices for MPLS:

**Customer Premise Equipment (_CPE_)** - The router at the customer's site that connects to a service provider's MPLS cloud. Traffic leaving the CPE doesn't have to be labled since it hasn't entered the MPLS cloud yet. The CPE leads to the _PE router_.

**Edge Label Switch Router (_ELSR_)/Provider Edge (_PE_) Router** - These are the routers at the edge (i.e., ingress or egress sections) of the MPLS cloud and hence have to attach the shim header into the incoming traffic and remove the shim header from traffic leaving the cloud. The ELSRs forward the packets to LSRs within the cloud for routing to the right ELSR at the other edge of the cloud that's connected to the destination network.

**Label Switch Router (_LSR_)/Provider Router (_P-Router_)** - LSRs are routers that view the labels on incoming traffic to make forwarding decisions, relabels them for the next LSRs so that the packet reaches the right destination network. Every LSR hop changes the label in the packet.

# Metro Ethernet
A _Metropolitan Ethernet_ or **Metro Ethernet** is a _Metropolitan Area Network (MAN)_ technology that runs on high speed Ethernet connections. However, since we are spanning huge distances - for example between different corporate office in different parts of the city, we won't be using UTP wires as the medium, but fiber optics. A part of the metro ethernet is the service provider, whom the customer uses the reach the internet. Some of the advantages of Metro Ethernet are:
* Easier to connect to most LANs since it's based on Ethernet technology, which is what modern LANs typically use.
* Metro Ethernet is cheaper than the alternatives, like _SONET_. **Synchronous Optical Network (_SONET_)** is a multiplexing standard for fiber optic cables that allows multiple channels of communications to pass traffic through a single fiber optic cable by sharing it.
* Lower end speeds in Metro Ethernet starts from 10 Gbps, with 40 Gbps speeds being a more common one. At the higher end of speeds, modern installations contain 100Gbps links.

# VPN Fundamentals
A **Virtual Private Network (_VPN_)** is a logically defined network where data flows through a tunnel between two sites. The traffic may be encrypted while within the tunnel, which allows the data to flow securely through untrusted networks, such as the internet. Some of the advantages of VPN are:
* It can use common broadband technologies, such as DSL and cable, which already exist in most small offices and homes.
* It's very scalable since any new connection just needs to be able to connect to the internet, to reach the **VPN concentrator** at the main site. The VPN concentrator is typically a Cisco ASA (_Adaptive Security Appliances_)/Router that has sufficient processing power to handle a number of incoming VPN sessions.
* The reason for companies using leased-line, or the cheaper alternative, frame-relay clouds in the old days was to avoid having their data intercepted while travelling through the internet. However, with the encryption, the data can travel through an untrusted network within the encrypted tunnel.

Cisco has two broad category of VPNs:
**Site-to-Site VPN** - In this two sites are connected via a VPN tunnel, with the routers/ASAs at either end of the tunnel acting as the end-points. This kind of VPN is transparent to the end user, since they never have to be made aware of the VPN. The traffic exiting one site is encrypted and passed through the VPN till it reaches the end of the tunnel at the other site, where the other router decrypts the traffic.

**Remote-Access VPN** - In remote access VPNs, the authentication is done at the end-user station, e.g., PC or a laptop. There are a couple of **SSL (_Secure Sockets Layer_) VPN** options:
* Securely through a web browser, e.g., _Clientless Cisco SSL VPN_. We can connect to a website using HTTPS which will then grant me access to the internal network of the office.
* Installing a software client, e.g., Cisco AnyConnect SSL VPN Client, or an VPN client built into the OS.

## IPsec
IPsec is the most popular technology used to secure the communications between sites connected through a VPN. It's a kind of VPN that not only maintains the confidentiality of the data flowing through it, but also maintain data integrity to ensure the data isn't modified in transit by use of hashing algorithms, provide authentication features and anti-replay protection. **Anti-replay protection** ensures that a malicious user can't perform a packet capture of a successful login and then send the captured packets again at a later time to log himself in.

An IPsec tunnel is like a _tunnel within a tunnel_. There's an outer tunnel called the **Internet Key Exchange (_IKE_) Phase I** Tunnel or a **ISAKMP** tunnel, where the security parameters/configuration for the inner tunnel are negotiated to reach consensus among the sites. The **IKE Phase II** Tunnel, or IPsec tunnel, is the inner tunnel in an IPsec connection. The actual traffic between the two sites passes through this tunnel.

IPsec does have a major disadvantage, because *it can only be used for unicast IP traffic*. It can't be used for multicast, broadcast or non-IP traffic. Hence, we have the option of taking our data that's in any protocol and encapsulate within a **Generic Routing Encapsulation (_GRE_) tunnel**, which is a logical connection capable of encapsulating a lot of data types. This means that any type of packet can be encapsulated within the GRE packets which is essentially an IP unicast packet and hence can be routed through an IPsec tunnel.

# GRE Tunnel Theory and Configuration
Let us consider that we have two routers are two different sites, separated by a service provider's cloud, or even the internet, and we need the two routers to be _layer-2 adjacent_, so that they can form a neighbourship between themselves. In such a case, we can form a **Generic Routing Encapsulation (_GRE_)** tunnel, which can encapsulate multiple layer 3 protocols. From the perspective of the router, the entire logical tunnel thus created appears to be a single hop! GRE however, doesn't do security by itself, and thus have to be sent through an IPsec tunnel for that.

## GRE Tunnel Configuration
In the topology below, we can see in order to reach R4 from R1, we need to go through multiple hops - R2 and R3, but once the GRE tunnel is up, it'll look like just a single hop from the router's perspective. First, we create a virtual tunnel interface, on both R1 and R4 and then assign the IP address to them.
```
R1(config)#int tunnel 1
*Jan  3 12:13:04.679: %LINEPROTO-5-UPDOWN: Line protocol on Interface Tunnel1, changed state to down
R1(config-if)#ip addr 192.168.0.1 255.255.255.248
R1(config-if)#desc GRE Start
```
Now we have to define the source and the destination of the tunnel from R1's perspective:
```
R1(config-if)#tunnel source lo1
R1(config-if)#tunnel destination 4.4.4.4
*Jan  3 12:16:24.849: %LINEPROTO-5-UPDOWN: Line protocol on Interface Tunnel1, changed state to up
```
There are of course several more ways to define the tunnel's source - by using the interface name on the egress interface, ip address or the loopback address, as shown here.

Now we'll set up R4 in a similar manner:
```
R4(config)#int tunnel 1
*Jan  3 12:19:16.447: %LINEPROTO-5-UPDOWN: Line protocol on Interface Tunnel1, changed state to down
R4(config-if)#ip addr 192.168.0.2 255.255.255.248
R4(config-if)#desc GRE End
R4(config-if)#tunnel source lo1
R4(config-if)#tunnel destination 1.1.1.1
*Jan  3 12:20:09.663: %LINEPROTO-5-UPDOWN: Line protocol on Interface Tunnel1, changed state to up
```

All routers have OSPF running on them, with area 0, and if we include the `192.168.0.0/29` subnet in OSPF, we'll see:
```
R1(config-router)#network 192.168.0.0 0.0.0.7 ar 0        

R4(config-router)#network 192.168.0.0 0.0.0.7 ar 0
*Jan  3 12:23:36.345: %OSPF-5-ADJCHG: Process 1, Nbr 1.1.1.1 on Tunnel1 from LOADING to FULL, Loading Done
```
We can see that an adjacency comes up once the tunnel is up.

We can ping the other side of the tunnel:
```
R4#ping 192.168.0.1
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 192.168.0.1, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 28/29/31 ms
```

We can see more information about this tunnel with the command `show interface tunnel 1`:
```
R4#sh int tu1
Tunnel1 is up, line protocol is up
  Hardware is Tunnel
  Description: GRE End
  Internet address is 192.168.0.2/29
  MTU 17916 bytes, BW 100 Kbit/sec, DLY 50000 usec,
     reliability 255/255, txload 1/255, rxload 1/255
  Encapsulation TUNNEL, loopback not set
  Keepalive not set
  Tunnel linestate evaluation up
  Tunnel source 4.4.4.4 (Loopback1), destination 1.1.1.1
   Tunnel Subblocks:
      src-track:
         Tunnel1 source tracking subblock associated with Loopback1
          Set of tunnels with source Loopback1, 1 member (includes iterators), on interface <OK>
  Tunnel protocol/transport GRE/IP
    Key disabled, sequencing disabled
    Checksumming of packets disabled
  Tunnel TTL 255, Fast tunneling enabled
  Tunnel transport MTU 1476 byt
  Tunnel transmit bandwidth 8000 (kbps)
  Tunnel receive bandwidth 8000 (kbps)
  Last input 00:00:05, output 00:00:03, output hang never
  Last clearing of "show interface" counters 00:11:06
  Input queue: 0/75/0/0 (size/max/drops/flushes); Total output drops: 0
  Queuing strategy: fifo
  Output queue: 0/0 (size/max)
  5 minute input rate 0 bits/sec, 0 packets/sec
  5 minute output rate 0 bits/sec, 0 packets/sec
     65 packets input, 7000 bytes, 0 no buffer
     Received 0 broadcasts (0 IP multicasts)
     0 runts, 0 giants, 0 throttles
     0 input errors, 0 CRC, 0 frame, 0 overrun, 0 ignored, 0 abort
     58 packets output, 6252 bytes, 0 underruns
     0 output errors, 0 collisions, 0 interface resets
     0 unknown protocol drops
     0 output buffer failures, 0 output buffers swapped out
```
We can see that the source is `4.4.4.4` and the destination is `1.1.1.1`. We can also see that the encapsulation is `TUNNEL` which denotes the GRE encapsulation.

However, the real test of the tunnel is a traceroute:
```
R4#traceroute 192.168.0.1
Type escape sequence to abort.
Tracing the route to 192.168.0.1
VRF info: (vrf in name/id, vrf out name/id)
  1 192.168.0.1 34 msec 30 msec 29 msec
```
We can now confirm that the R1 router is only 1 hop away via the tunnel.

# Troubleshooting GRE Issues
Some of the common issues that may present themselves while working with GRE tunnels are:
* The source IP address isn't reachable from far-end router
* The destination IP address isn't reachable from local router
* GRE is blocked by an **Access Control List (_ACL_)**
* Fragmentation may be caused due to MTU settings throughout the tunnel. Since our **GRE headers are 24B**, which means that if the interface MTUs were originally set to 1500B, our MTU will now have to be `1476B` to avoid fragmentation.
* **Recursive Routing** - This is the case when the best route to reach the destination of the tunnel, is through the tunnel itself, which'll bring down the tunnel.

Recursive routing can be demonstrated when load-balancing in EIGRP across unequal cost paths. In such a case, the router will try to load balance across the serial link and the tunnel created via the serial link, which is essentially the same path - causing the tunnel to fail! In cases of recursive routing, it's better to set up a static route to the destination of the tunnel, instead of using a dynamic routing protocol like EIGRP.

# DMVPN Fundamentals
Let us consider a hub-and-spoke VPN topology as shown below. Every VPN in the remote offices are connected to the headquarters. If remote office B would want to communicate with remote office C, it'd have to sent the packet to headquarters first, to be route to remote office C. This isn't very efficient. Another approach would be a full-mesh of VPN connections, but that wouldn't be scalable. This is why we have **Dynamic Multipoint VPN (_DMVPN_)** which lets us create and tear down VPN connections on an _as-needed basis_, similar to Virtual Circuits in a frame-relay cloud. On eof the technologies that makes DMVPN possible is **Multipoint GRE (_mGRE_)**, which allows a single router interface to have multiple GRE tunnels.

In the topology above, we have two options:
* Make the HQ router's egress interface a mGRE interface,
* Make all the router's egress interfaces mGRE interfaces.

However, the routers still need to know the IP address at the far end of the tunnel. For this, we need the **Next Hop Resolution Protocol (_NHRP_)**, which allows the interface configured with mGRE find out the IP address of the link at the far-end of the tunnel.

# WAN Topologies
# Single Homed vs Dual homed Connections
A **Single Homed connection** is when we have one connection to one ISP. In such cases, the routing is simpler because we don't have to know about all the routes on the internet. Our edge router needs only know about the routes internal to our network, and for everything else, we set a default route that's the gateway router of the ISP, which will connect our network to the internet.

A **Dual Homed connection** is when we have dual connections, for redundancy with the same ISP. Now since we have multiple connections going out to the internet, the routing will start to be more challenging. In such cases, instead of using static/default routing, we use the exterior gateway protocol called **Border Gateway Protocol (_BGP_)** to route between the various autonomous systems on the internet.

A **Single multi-homed connection** is when we have a single link per ISP to two, or more ISPs. We can also have two or more connections per ISP to two or more ISPs, which is called **Dual multi-homed connection**.

# Border Gateway Protocol (_BGP_)
In situations where we have more than one route to the internet from our network, instead of using static routes, we should be using an exterior gateway protocol, like the **Border Gateway Protocol (_BGP_)**. Unlike Interior Gateway Protocols (IGPs) like OSPF and EIGRP, BGP is meant to route between autonomous systems. Some of the properties of BGW are:
* Just like IGPs, BGP also forms neighbourships, but they don't have to be adjacent - they can be several hops away!
* There is no mechanism to dynamically discover the IP address of a neighbour via multicast - the neighbour's IP address must be explicitly specified.
* A TCP session is established between neighbours.
* BGP advertises both the network prefix and length, together called **Network Layer Reachability Information (_NLRI_)** for BGP. This is similar to OSPF and EIGRP.
* Unlike IGPs, BGP, along with the NLRI, will also advertise **Path Attributes (_PA_s)** that are used to select the best route.
* BGP is a **Path Vector** routing protocol. Similar to _Distance Vector_ protocols, such as RIP which stores the direction (next hop) in which a network is available and the number of hops to reach the network, BGP stores the number of *Autonomous Systems* it has to cross to reach that network, which is its metric.

Let us consider the following network, where we have our AS=`65,001`. We're also connected to AS `65,002` and `65,004` via links from our ISP. Additionally AS `65,003` may be a network that we're not directly connected to by our ISP, and may be an AS out on the internet we're trying to reach. Unlike IGPs, BGP doesn't have bandwidth as its metric, but rather the number of AS hops to reach a destination AS. In the figure below, we have two links, a T1 with 1.544Mbps bandwidth and a link with half that speed (768Kbps). Unlike IGPs, BGP may end up using the path with the lower bandwidth if the destination network is closer, i.e., lesser AS hops away when compared to the higher bandwidth T1.

In BGP we can *influence* these path attributes to control the path selection. One of the path attributes for BGP is **AS_PATH** which contains a list of all the AS through which a packet must flow to reach the destination network - the shorter the _AS_PATH_, the better. In the above case, to ensure the T1 is used with BGP, we can ask R2 to *prepend* multiple instances of our own AS in the AS_PATH when advertising routes to IPS1, to tell ISP1 that  our AS is further away than it really is. ISP1 will think that to get to our AS, it first needs to go to AS 65001, then to AS 65001 again, then to AS 65001, and so on. This solves the issue of the 768Kbps link used as the preferred inbound path.

For outbound path selection, we can use the **Local Preference** path attribute, which is a PA that can be assigned to routes originating/received from some other AS. This is then exchanged between the routers in an AS. BGP would prefer routes with a higher local preference. Thus, we can tag the routes coming in from ISP2 with a local preference of 200, while those that we get from ISP1 get tagged with a local preference of 100. This would influence R2's path selection to favour the T1 link.

# BGP Configuration and Verification
The objective of BGP at the CCNA level is to ensure that routers in different AS can use eBGP as their EGP and can advertise routes to each other.
Let us configure the network shown in the diagram below. When setting up R1 for BGP, we start the process for BGP on R1 with the AS=`64500` since that's the AS number in which R1 is contained.

After that, we have to manually specify the IP and the _remote-AS_, i.e., the AS number of the neighbour using the `neighbour <ip> remote-as <as#>` command. This makes that IP a BGP neighbour. Now we need to advertise routes to it. For this we use the network command - which unlike in IGPs actually states which networks to advertise. Thus, the config on R1 and R2 will be:
```
R1(config)#router bgp 64500
R1(config-router)#neighbor 198.51.100.2 remote-as 64495
R1(config-router)#network 192.0.2.0 mask 255.255.255.0

R2(config)#router bgp 64495
R2(config-router)#neighbor 198.51.100.1 remote-as 64500
*Jan  4 10:47:34.095: %BGP-5-ADJCHANGE: neighbor 198.51.100.1 Up
R2(config-router)#network 203.0.113.0 mask 255.255.255.0
```

Now that the BGP configuration is done, we can verify which networks are known to BGP:
```
R2#sh ip bgp
BGP table version is 3, local router ID is 203.0.113.1
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal,
              r RIB-failure, S Stale, m multipath, b backup-path, f RT-Filter,
              x best-external, a additional-path, c RIB-compressed,
Origin codes: i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

     Network          Next Hop            Metric LocPrf Weight Path
 *>  192.0.2.0        198.51.100.1             0             0 64500 i
 *>  203.0.113.0      0.0.0.0                  0         32768 i
```
Just because a network is in the BGP table doesn't mean that it'll get injected into the IP routing table of the router. Only the best, valid path will get injected _if_ BGP is the most authoritative source for that network. The `*` in the `*>` before each network tells us that the path is valid. This means that the next hop for the path is reachable by this router. The `>` means the path is the best path to the network.

The `Path` in the output is the value of *AS_PATH* and here is only `64500` for `192.0.2.0` since it's in that AS. Typically, for AS out on the internet, this path is much bigger.

# Network Services
# Hot Standby Router Protocol (_HSRP_) Operation
HSRP is a Cisco proprietary **First Hop Redundancy Protocol (_FHRP_)**. Hosts on a subnet depend on a gateway router to forward packets to and from outside it's own subnet. However, if that gateway were to go down, the host would be reduced only communicating on it's local subnet, and be unable to reach any outside network. A _FHRP_ solves this problem by letting a secondary router step in when the primary router fails so that we can avoid a single point of failure like a single physical gateway. The gateway's IP is assigned to a virtual router instead of a physical router. An industry standard _FHRP_ also exists, called **Virtual Router Redundancy Protocol (_VRRP_)**.

Let us consider the topology below. Since in our modern networks, we have multilayer switches, they're typically the ones our devices use as the default gateway. Neither sw2 or sw3 has the IP address `10.1.1.1` but sw2 takes the active role in routing packets meant for `10.1.1.1` while sw3 will step in if sw1 fails, and is thus the standby _router_. The switches do this by not only hosting the IP address for the gateway but the MAC address for the gateway as well, that the PC learns via ARPing.

When sw2 goes down sw3 will get to know about it very soon, since _hello messages_ are exchanged between _routers_ with a default hello interval of _3 seconds_. If sw3 doesn't get a hello message from sw2, which was the active switch, for a period called the _hold time_, it's transition to _active_ state itself. The hold time is a value not less than 3 times the hello timer, which by default would be _10 sec_. While this might be a long time to wait, if we have high bandwidth links between sw2 and sw3, such as GigE Links, we can set the hello timer to sub-seconds value, which would make our hold time _1 sec or less_.

## Interface Tracking
Let us consider that instead of Sw2 going down, the link between sw2 and the internet fails. In such case by default, sw3 will still get hello messages from sw2 and remain in a stand-by state. Hence, HSRP has a feature called **interface tracking**, which can monitor the status of an interface and can decrement a priority value if that interface goes down to ensure traffic is re-routed via a live interface. By default in the **Active Router Election**, the router with the highest HSRP priority becomes the active router. Default priority is 100. When sw2's link goes down, it's priority decrease will cause sw3 to have the greater priority and become the active router. However, when sw2 comes back up after a repair, it won't automatically get back it's original priority. To solve this, we have the **preempt option** which lets a router that was previously the active router reclaim its role of active router when it comes back up after a failure or when its priority increasest to the highest value.

## Enhanced Object Tracking
This feature allows the aforementioned priority value to be decremented not just on the basis of a link failure, but a host of other reasons. This may be a route no longer being in a router's IP table, or a metric to a network exceeding a certain value, etc., all of which can cause a decrease in priority.

# HSRP Configuration
_**NOTE**: A known bug with IOU images is that HSRP won't work with them, use IOSv images instead!_

Let us configure the topology below to have a virtual router with `10.1.1.1` as the gateway for hosts on sw1. Unlike _VRRP_, _HSRP_ doens't support setting the IP address of a physical interface as the Virtual Router's IP. Here, we want the entire configuration to be in HSRP _Group 10_, an arbitrary HSRP group. This is because HSRP can have multiple instances running for different IP ranges, and each instance is called a _group_. First we go to sw2, the multilayer switch and enter the interface configuration mode for **sw2 e0/0**:
```
sw2(config)#int e0/0
sw2(config-if)#standby 10 ip 10.1.1.1
sw2(config-if)#standby 10 priority 110
sw2(config-if)#standby 10 preempt
*Jan  4 12:38:40.257: %HSRP-5-STATECHANGE: Ethernet0/0 Grp 10 state Standby -> Active
```
We want the virtual router to have an IP address of `10.1.1.1`, which is what is set in the IP address value. Further, since we want sw2 to be the primary router, we set it's priority to `110`, which is greater than the default value of `100`. Finally, if we lose our role as the active router, we want to reclaim our role as the primary/active once it's repaired. So, we set up the preempt option. This concludes our initial configuration on sw2.

We want to set up a similar configuration on sw3, and so we use:
```
sw3(config)#int e0/0
sw3(config-if)#standby 10 ip 10.1.1.1
sw3(config-if)#standby 10 preempt
*Jan  4 12:42:53.376: %HSRP-5-STATECHANGE: Ethernet0/0 Grp 10 state Speak -> Standby
```
On sw3 we didn't turn up the priority since we _want_ it to be the Stand-by router for 10.1.1.1 Virtual router in the HSRP config. This concludes our basic HSRP config.

Now we can check which route the PC takes to reach the `1.1.1.1` site on the internet:
```
PC-1> sh ip        

NAME        : PC-1[1]
IP/MASK     : 10.1.1.100/24
GATEWAY     : 10.1.1.1
DNS         :
MAC         : 00:50:79:66:68:00
LPORT       : 10001
RHOST:PORT  : 127.0.0.1:10002
MTU:        : 1500

PC-1> trace 1.1.1.1
trace to 1.1.1.1, 8 hops max, press Ctrl+C to stop
 1   10.1.1.2   9.426 ms  9.919 ms  10.416 ms
 2   *172.16.0.2   14.382 ms (ICMP type:3, code:3, Destination port unreachable)
```
We can see that the first hope is actually `10.1.1.2` to reach the site `1.1.1.1`, which is actually a router here with the interface `172.16.0.2` connecting to it by our active HSRP router, R2.

Now let's test the failover and transition of R3 from the standby router to the active router. Since we're using a VPCS virtual PC, the ping command has an option of `-t` for perpetual ping and `-i` to set the interval between sending packets in ms. We want to start the perpetual ping on PC-1, shutdown port G0/0 on sw2 to simulate a failure and see if the failover succeeds:
```
PC-1> ping 1.1.1.1 -i 500 -t
84 bytes from 1.1.1.1 icmp_seq=1 ttl=254 time=23.804 ms
84 bytes from 1.1.1.1 icmp_seq=2 ttl=254 time=16.857 ms
84 bytes from 1.1.1.1 icmp_seq=3 ttl=254 time=16.863 ms
84 bytes from 1.1.1.1 icmp_seq=4 ttl=254 time=11.903 ms
84 bytes from 1.1.1.1 icmp_seq=5 ttl=254 time=38.690 ms
84 bytes from 1.1.1.1 icmp_seq=6 ttl=254 time=14.880 ms
84 bytes from 1.1.1.1 icmp_seq=7 ttl=254 time=15.372 ms
84 bytes from 1.1.1.1 icmp_seq=8 ttl=254 time=23.333 ms
84 bytes from 1.1.1.1 icmp_seq=9 ttl=254 time=11.412 ms
...
```

On R2:
```
sw2(config)#int g0/0
sw2(config-if)#shutdown
*Jan  5 10:20:51.708: %LINK-5-CHANGED: Interface GigabitEthernet0/0, changed state to administratively down
*Jan  5 10:20:52.706: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/0, changed state to down
*Jan  5 10:20:52.710: %HSRP-5-STATECHANGE: GigabitEthernet0/0 Grp 10 state Active -> Init
```

This causes the pings to timeout on PC-1:
```
...
1.1.1.1 icmp_seq=10 timeout
1.1.1.1 icmp_seq=11 timeout
1.1.1.1 icmp_seq=12 timeout
1.1.1.1 icmp_seq=13 timeout
1.1.1.1 icmp_seq=14 timeout
1.1.1.1 icmp_seq=15 timeout
```

The pings timeout till sw3 steps in to be the active router simulating the `10.1.1.1` IP:
```
*Jan  5 10:20:39.914: %HSRP-5-STATECHANGE: GigabitEthernet0/0 Grp 10 state Standby -> Active
```

This immediately makes the ping succeed on PC-1 again:
```
1.1.1.1 icmp_seq=16 timeout
1.1.1.1 icmp_seq=17 timeout
84 bytes from 1.1.1.1 icmp_seq=18 ttl=254 time=13.393 ms
84 bytes from 1.1.1.1 icmp_seq=19 ttl=254 time=29.758 ms
84 bytes from 1.1.1.1 icmp_seq=20 ttl=254 time=40.672 ms
84 bytes from 1.1.1.1 icmp_seq=21 ttl=254 time=37.200 ms
84 bytes from 1.1.1.1 icmp_seq=22 ttl=254 time=48.606 ms
84 bytes from 1.1.1.1 icmp_seq=23 ttl=254 time=36.234 ms
84 bytes from 1.1.1.1 icmp_seq=24 ttl=254 time=26.789 ms
84 bytes from 1.1.1.1 icmp_seq=25 ttl=254 time=25.296 ms
84 bytes from 1.1.1.1 icmp_seq=26 ttl=254 time=14.385 ms
84 bytes from 1.1.1.1 icmp_seq=27 ttl=254 time=11.846 ms
84 bytes from 1.1.1.1 icmp_seq=28 ttl=254 time=17.856 ms
84 bytes from 1.1.1.1 icmp_seq=29 ttl=254 time=16.838 ms

PC-1> trace 1.1.1.1
trace to 1.1.1.1, 8 hops max, press Ctrl+C to stop
 1   10.1.1.3   11.907 ms  14.309 ms  9.424 ms
 2   *172.16.0.6   17.860 ms (ICMP type:3, code:3, Destination port unreachable)

```
When we perform a trace route, we see that we're now using `10.1.1.3`. i.e., sw3 as the next hop to reach the _internet_. Now let's see what happens when the router _sw2_ comes back up.

For this, we'll use HSRP debugging on _sw3_, which has several options:
```
sw3#debug standby ?
  errors   HSRP errors
  events   HSRP events
  packets  HSRP packets
  terse    Display limited range of HSRP errors, events and packets
```

We'll use the `terse` option as it shows us a limited range of all kinds of errors, events and packet flows. We'll start the perpetual ping on PC-1 again, switch the port on sw2 back on and see what happens on sw3:
```
sw3#debug standby terse
HSRP:
  HSRP Errors debugging is on
  HSRP Events debugging is on
    (protocol, neighbor, redundancy, track, ha, arp, interface)
  HSRP Packets debugging is on
    (Coup, Resign)

PC-1> ping 1.1.1.1 -i 500 -t
84 bytes from 1.1.1.1 icmp_seq=1 ttl=254 time=18.348 ms
84 bytes from 1.1.1.1 icmp_seq=2 ttl=254 time=12.888 ms
84 bytes from 1.1.1.1 icmp_seq=3 ttl=254 time=19.344 ms
84 bytes from 1.1.1.1 icmp_seq=4 ttl=254 time=30.258 ms
84 bytes from 1.1.1.1 icmp_seq=5 ttl=254 time=15.374 ms
84 bytes from 1.1.1.1 icmp_seq=6 ttl=254 time=24.799 ms
84 bytes from 1.1.1.1 icmp_seq=7 ttl=254 time=16.819 ms
...

sw2(config-if)#no shut
sw2(config-if)#
*Jan  5 10:30:22.974: %LINK-3-UPDOWN: Interface GigabitEthernet0/0, changed state to up
*Jan  5 10:30:23.976: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/0, changed state to up
*Jan  5 10:30:24.000: %DUAL-5-NBRCHANGE: EIGRP-IPv4 1: Neighbor 10.1.1.3 (GigabitEthernet0/0) is up: new adjacency
sw2(config-if)#
*Jan  5 10:30:25.274: %HSRP-5-STATECHANGE: GigabitEthernet0/0 Grp 10 state Listen -> Active

...
84 bytes from 1.1.1.1 icmp_seq=8 ttl=254 time=16.870 ms
84 bytes from 1.1.1.1 icmp_seq=9 ttl=254 time=17.856 ms
84 bytes from 1.1.1.1 icmp_seq=10 ttl=254 time=15.872 ms
84 bytes from 1.1.1.1 icmp_seq=11 ttl=254 time=13.394 ms
84 bytes from 1.1.1.1 icmp_seq=12 ttl=254 time=21.824 ms
84 bytes from 1.1.1.1 icmp_seq=13 ttl=254 time=15.377 ms
84 bytes from 1.1.1.1 icmp_seq=14 ttl=254 time=19.343 ms
84 bytes from 1.1.1.1 icmp_seq=15 ttl=254 time=13.392 ms
```
We can see that the pings weren't affected when sw2 was coming back up.

Now we can analyse the debugging on sw3:
```
*Jan  5 10:29:52.626: HSRP: Gi0/0 Grp 10 ARP src 10.1.1.100 tgt 10.1.1.1, reply with mac 0000.0c07.ac0a
*Jan  5 10:30:00.836: %DUAL-5-NBRCHANGE: EIGRP-IPv4 1: Neighbor 10.1.1.2 (GigabitEthernet0/0) is up: new adjacency
*Jan  5 10:30:01.849: HSRP: Gi0/0 Nbr 10.1.1.2 Adv in, active 0 passive 1
*Jan  5 10:30:01.850: HSRP: Gi0/0 Nbr 10.1.1.2 created
*Jan  5 10:30:01.852: HSRP: Gi0/0 Nbr 10.1.1.2 is passive
*Jan  5 10:30:02.110: HSRP: Gi0/0 Nbr 10.1.1.2 Adv in, active 1 passive 1
*Jan  5 10:30:02.111: HSRP: Gi0/0 Nbr 10.1.1.2 is no longer passive
*Jan  5 10:30:02.112: HSRP: Gi0/0 Nbr 10.1.1.2 destroyed
*Jan  5 10:30:02.117: HSRP: Gi0/0 Grp 10 Coup   in  10.1.1.2 Listen  pri 110 vIP 10.1.1.1
*Jan  5 10:30:02.120: HSRP: Gi0/0 Grp 10 Active: j/Coup rcvd from higher pri router (110/10.1.1.2)
*Jan  5 10:30:02.121: HSRP: Gi0/0 Grp 10 Active router is 10.1.1.2, was local
*Jan  5 10:30:02.122: HSRP: Gi0/0 Nbr 10.1.1.2 created
*Jan  5 10:30:02.124: HSRP: Gi0/0 Nbr 10.1.1.2 active for group 10
*Jan  5 10:30:02.125: HSRP: Gi0/0 Grp 10 Active -> Speak
*Jan  5 10:30:02.127: %HSRP-5-STATECHANGE: GigabitEthernet0/0 Grp 10 state Active -> Speak
*Jan  5 10:30:02.128: HSRP: Gi0/0 Grp 10 Redundancy "hsrp-Gi0/0-10" state Active -> Speak
*Jan  5 10:30:02.134: HSRP: Gi0/0 Grp 10 Removed 10.1.1.1 from ARP
*Jan  5 10:30:02.140: HSRP: Gi0/0 IP Redundancy "hsrp-Gi0/0-10" update, Active -> Speak
*Jan  5 10:30:13.746: HSRP: Gi0/0 Grp 10 Speak: d/Standby timer expired (unknown)
*Jan  5 10:30:13.747: HSRP: Gi0/0 Grp 10 Standby router is local
*Jan  5 10:30:13.747: HSRP: Gi0/0 Grp 10 Speak -> Standby
*Jan  5 10:30:13.748: %HSRP-5-STATECHANGE: GigabitEthernet0/0 Grp 10 state Speak -> Standby
*Jan  5 10:30:13.749: HSRP: Gi0/0 Grp 10 Redundancy "hsrp-Gi0/0-10" state Speak -> Standby
*Jan  5 10:30:13.755: HSRP: Gi0/0 IP Redundancy "hsrp-Gi0/0-10" standby, unknown -> local
*Jan  5 10:30:13.756: HSRP: Gi0/0 IP Redundancy "hsrp-Gi0/0-10" update, Speak -> Standby
sw3#u all
All possible debugging has been turned off
```

## HSRP States
There are five different states of an interface participating in HSRP:
* **Init** - The state of an HSRP interface after coming back up or after an interface configuration change.
* **Listen** - The interface now knows the _virtual IP address_ and is listening for hello messages.
* **Speak** - The interface now sends out hello messages to participate in the **Active/Standby router election**.
* **Standby** - The router on which the interface is located is now acting as the backup/standby router after losing the election, but is next in line to become the active router if the incumbent active router fails. It still sends out hello messages.
* **Active** - The HSRP state of an interface that's actively forwarding packets for the Virtual IP and MAC addresses. This too has to send out hello messages to let the backup router know it's still alive and hence ask it to stay on _stand-by_.

We can see that in the previous HSRP failover debugging, we get the following messages:
```
*Jan  5 10:30:02.117: HSRP: Gi0/0 Grp 10 Coup   in  10.1.1.2 Listen  pri 110 vIP 10.1.1.1
*Jan  5 10:30:02.120: HSRP: Gi0/0 Grp 10 Active: j/Coup rcvd from higher pri router (110/10.1.1.2)
*Jan  5 10:30:02.121: HSRP: Gi0/0 Grp 10 Active router is 10.1.1.2, was local
*Jan  5 10:30:02.122: HSRP: Gi0/0 Nbr 10.1.1.2 created
*Jan  5 10:30:02.124: HSRP: Gi0/0 Nbr 10.1.1.2 active for group 10
*Jan  5 10:30:02.125: HSRP: Gi0/0 Grp 10 Active -> Speak
*Jan  5 10:30:02.127: %HSRP-5-STATECHANGE: GigabitEthernet0/0 Grp 10 state Active -> Speak
...
*Jan  5 10:30:13.748: %HSRP-5-STATECHANGE: GigabitEthernet0/0 Grp 10 state Speak -> Standby
```
First sw2 sends sw3 a **coup message** claiming its right to be the active router. Sw3 realizes that sw2 has a higher priority and relinquishes its role as the active router. The interface on sw3 first goes from _active_ to _speak_ and eventually, to _standby_.

## HSRP Verification
We can see the status of HSRP with the command `show standby brief`:
```
sw3#sh standby brief
                     P indicates configured to preempt.
                     |
Interface   Grp  Pri P State   Active          Standby         Virtual IP
Gi0/0       10   100 P Standby 10.1.1.2        local           10.1.1.1
```
We can see that **Gi0/0** participates in HSRP for _HSRP group 10_ with a default priority of `100`, has pre-emption turned on. The Virtual IP address is `10.1.1.1`, the active router has the IP `10.1.1.2` and the standby router is a _local interface_, i.e., sw3 is the backup router.

To get more details, we use the `show standby` command, optionally with an interface name:
```
sw3#sh standby g0/0
GigabitEthernet0/0 - Group 10
  State is Standby
    6 state changes, last state change 00:19:47
  Virtual IP address is 10.1.1.1
  Active virtual MAC address is 0000.0c07.ac0a (MAC Not In Use)
    Local virtual MAC address is 0000.0c07.ac0a (v1 default)
  Hello time 3 sec, hold time 10 sec
    Next hello sent in 2.544 secs
  Preemption enabled
  Active router is 10.1.1.2, priority 110 (expires in 8.608 sec)
  Standby router is local
  Priority 100 (default 100)
  Group name is "hsrp-Gi0/0-10" (default)
```
Here, we can also see the virtual MAC address, which is `0000.0c07.ac0a` which is the default for HSRPv1. The same virtual MAC is used by both active and standby routers to ensure the frames are switched correctly. The first part of the MAC address, `0000.0c` is a vendor code for Cisco. The next part, `07.ac` tells us that it's a Virtual MAC address, specifically for _HSRPv1_. The final two Hex bits, `0a` is the group number in Hex, i.e., _group 10_.

## Decreasing failover time with HSRPv2
When we're using sub-second hello timers, Cisco recommends that we use _HSRPv2_. To switch the existing configuration to HSRPv2, we just use the command `standby version 2` on all participating routers:
```
sw2(config-if)#standby ver 2
*Jan  5 10:56:33.335: %HSRP-5-STATECHANGE: GigabitEthernet0/0 Grp 10 state Active -> Init
*Jan  5 10:56:54.824: %HSRP-5-STATECHANGE: GigabitEthernet0/0 Grp 10 state Standby -> Active

sw3(config-if)#standby ver 2
*Jan  5 10:56:14.318: %HSRP-5-STATECHANGE: GigabitEthernet0/0 Grp 10 state Active -> Init
*Jan  5 10:56:40.670: %HSRP-5-STATECHANGE: GigabitEthernet0/0 Grp 10 state Speak -> Standby
```

Now we move on to reducing the hello and hold timers for faster switch-overs. Let's say we want our hello timer to be `200ms`, and let's set the hold timer which must be more than `600ms`, to `900ms`:
```
sw2(config-if)#standby 10 timers ?
  <1-254>  Hello interval in seconds
  msec     Specify hello interval in milliseconds

sw2(config-if)#standby 10 timers ms 200 ?
  <1-255>  Hold time in seconds
  msec     Specify hold time in milliseconds

sw2(config-if)#standby 10 timers ms 200 ms 900

sw3(config-if)#standby 10 time ms 200 ms 900
```

For HSRPv2, the MAC address has changed:
```
sw3#sh standby
GigabitEthernet0/0 - Group 10 (version 2)
  State is Standby
    9 state changes, last state change 00:06:08
  Virtual IP address is 10.1.1.1
  Active virtual MAC address is 0000.0c9f.f00a (MAC Not In Use)
    Local virtual MAC address is 0000.0c9f.f00a (v2 default)
  Hello time 200 msec, hold time 900 msec
    Next hello sent in 0.192 secs
  Preemption enabled
  Active router is 10.1.1.2, priority 110 (expires in 0.880 sec)
    MAC address is 0c88.a91f.0200
  Standby router is local
  Priority 100 (default 100)
  Group name is "hsrp-Gi0/0-10" (default)
```
We can see the default MAC address is now `0000.0c9f.f00a` where `0000.0c` is still the vendor code, which remains unchanged, the next part `9f.f`
tells us that it's a HSRPv2 MAC address and finally, we have the last 3 instead of 2 bits to store the group number, which in this case is `00a`, i.e., 10 in decimal. This also means that we can have more HSRP groups in HSRPv2.

Another difference between HSRPv1 and v2 is that v1 uses the _all-routers_ multi-cast group of `224.0.0.2` while HSRPv2 uses `224.0.0.102`. Finally, HSRPv2 also supports IPv6, which v1 doesn't support.

The failover time now is much faster:
```
PC-1> trace 1.1.1.1
trace to 1.1.1.1, 8 hops max, press Ctrl+C to stop
 1   10.1.1.2   9.916 ms  20.834 ms  19.344 ms
 2   *172.16.0.2   14.881 ms (ICMP type:3, code:3, Destination port unreachable)

PC-1> ping 1.1.1.1 -i 500 -t
84 bytes from 1.1.1.1 icmp_seq=1 ttl=254 time=17.354 ms
84 bytes from 1.1.1.1 icmp_seq=2 ttl=254 time=18.849 ms
84 bytes from 1.1.1.1 icmp_seq=3 ttl=254 time=12.399 ms
84 bytes from 1.1.1.1 icmp_seq=4 ttl=254 time=48.615 ms
84 bytes from 1.1.1.1 icmp_seq=5 ttl=254 time=12.892 ms
84 bytes from 1.1.1.1 icmp_seq=6 ttl=254 time=10.940 ms
84 bytes from 1.1.1.1 icmp_seq=7 ttl=254 time=12.400 ms
1.1.1.1 icmp_seq=8 timeout
84 bytes from 1.1.1.1 icmp_seq=9 ttl=254 time=18.352 ms
84 bytes from 1.1.1.1 icmp_seq=10 ttl=254 time=24.306 ms
84 bytes from 1.1.1.1 icmp_seq=11 ttl=254 time=36.705 ms
84 bytes from 1.1.1.1 icmp_seq=12 ttl=254 time=13.882 ms
84 bytes from 1.1.1.1 icmp_seq=13 ttl=254 time=15.876 ms

PC-1> trace 1.1.1.1         
trace to 1.1.1.1, 8 hops max, press Ctrl+C to stop
 1   10.1.1.3   11.893 ms  21.818 ms  16.865 ms
 2   *172.16.0.6   13.891 ms (ICMP type:3, code:3, Destination port unreachable)
```
We can see that we only lost 1 ping packet. This is due to the very low hello and hold timers - something we have to be careful about in real networks. If a network is un-realiable or is congested, the failovers will be frequent and un-predictable, and hence we must apporpriately adjust them.

## Interface Tracking Configuration
We want to ensure that if the link between sw2 and the internet fails, we still switchover to sw3 as the active. For this, we have to turn on interface tracking on interface **sw2 g0/1** that leads to the internet and ensure that if the WAN link on sw2 fails, the priority of the **sw2 g0/0** port goes down by 20, i.e., reach _90_, less than the default priority of _100_ on **sw3 g0/0** to make it the active router. We can do this with the `standby <HSRP-Group-num> track <interface ID> <dec Value>` command, which in this case would be `standby 10 Gi 0/1 20`. However, in IOSv 15.2, this isn't available, so, we first have to attach the interface to a tracking object and then track it:
```
sw2(config)#track 1 int Gi 0/1 ip routing
sw2(config-track)#int g0/0
sw2(config-if)#standby 10 track 1 dec 20
```

We can now check our priority before and after shutting down the interface:
```
sw2(config)#do sh stand br
                     P indicates configured to preempt.
                     |
Interface   Grp  Pri P State   Active          Standby         Virtual IP
Gi0/0       10   110 P Active  local           10.1.1.3        10.1.1.1
sw2(config)#int g0/1
sw2(config-if)#shut
*Jan  5 11:38:58.527: %TRACK-6-STATE: 1 interface Gi0/1 ip routing Up -> Down
*Jan  5 11:38:58.771: %HSRP-5-STATECHANGE: GigabitEthernet0/0 Grp 10 state Active -> Speak
*Jan  5 11:38:59.811: %HSRP-5-STATECHANGE: GigabitEthernet0/0 Grp 10 state Speak -> Standby
*Jan  5 11:39:00.490: %LINK-5-CHANGED: Interface GigabitEthernet0/1, changed state to administratively down
*Jan  5 11:39:01.502: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/1, changed state to down
sw2(config-if)#do sh stand br
                     P indicates configured to preempt.
                     |
Interface   Grp  Pri P State   Active          Standby         Virtual IP
Gi0/0       10   90  P Standby 10.1.1.3        local           10.1.1.1
```
We can see that after the WAN link shutdown, the priority was decreased by 20 and then the backup router was switched to being the active router and vice versa.

# Quality of Service (_QoS_)
# Fundamentals of _QoS_
With Quality of Service settings, we can treat different types of traffic differently. For example, we can let voice traffic pass with the maximum priority, We can set a maximum bandwidth for gaming, a minimum bandwidth for our important applications, etc. In today's modern networks, there's primarily three types of traffic: voice, data and video. If we let all three pass through the network uncontrolled, then we might face intermittent periods of congestion. The set of technologies that can help us control this traffic is collectively called **Quality of Service**. QoS is _managed-unfairness_, where we give preferential treatment to certain traffic types. There are broadly three categories of QoS:
* **IntServ (_Integrated Services_)** - The QoS mechanism that gives us _IntServ_ is called **Resource reSerVation Protocol (_RSVP_)**. This is a very strict QoS, also called *hard QoS*. In this, we create a reservation between a couple of routers and guarantee that an application has a section of the bandwidth dedicated for it and we don't let anything use that bandwidth until the _application gives it back_, even if the application is _idling_ in terms of network activity.
* **DiffServ (_Differentiated Services_)** - The QoS category used most for voice and video traffic over our networks. It's less strict than RSPV and hence, is called _soft QoS_. Here we get to differentiate between different types of traffic, and set minimum and maximum speed limits, priority of transfer, etc. and this is the QoS category we'll mainly focus on.
* **Best Effort** - Doesn't really do any preferential treatment on traffic type - but simply uses **First In First Out (_FIFO_)** algorithm to forward packets out of the queue in the same order in which they arrived and is thus, not strict at all!

## Common QoS Mechanisms
Some of the common QoS mechanisms between all categories of QoS are:
* **Classification and Marking** - Classification is the process of identifying the type of data contained within a packet and _marking_ involves going into the packet and altering bytes in the layer-2 or layer-3 header to define its priority level. If marking is done early on in the flow of the packet through the network, the subsequent switches/routers won't have to re-evaluate the packet to find out what kind of data is contained within it, and directly forward/drop the packet as and when needed.
* **Queuing** - Classification and marking itself doesn't change the way the data is handled. We need a system to evaluate the marking and take a decision on the basis of it. _Queuing_ is a QoS mechanism that determines how packets are stored and transmitted from the queue of a router/switch during network congestion. Interfaces on networking devices have a **buffer/queue** that it uses to temporarily store data that it can't yet transmit/forward. Such a case can be experienced when, for example, we have a 1GigE connection at the ingress interface of the router for the local LAN, but the egress WAN port is a T1 line with _1.544Mbps_ bandwidth. Data flows in a lot faster than it can be sent out via the WAN, and hence, the router has to _queue the packets_ by storing them in the _buffer_ till the bandwidth demand on the WAN interface dies down and the packets in the buffer can be transmitted. There are several Queuing algorithms - some like the _best effort_ algorithm sends everything out in the same order they arrived, but some prioritize the _latency-sensitive_ packets such as VoIP/Video packets and let them pass through the queue first. In such cases, we may have a separate queue for voice/data and another for other traffic. Thus, even when the normal buffer is full and packets have to be discarded, the voice/data buffer will have enough space for the rest of the packets and thus won't be discarded.
* **Congestion Avoidance** - This is a QoS mechanism like **Random Early Detection (_RED_)** that tries to stop the queue from filling up till it's capacity by randomly discarding packets when the queue depth increases. When the network is congested, and the buffers overflow, data is lost since many packets are discarded. Further, TCP traffic slows down since TCP reduces its window size when packets are lost. An industry standard solution to reduce congestion is *RED* of which Cisco has it's own proprietary version called **Weighted Random Early Detection (_WRED_)**. As the queue depth increases, RED/WRED starts discarding packet more aggressively in proportion to the queue depth, based on pre-defined thresholds. RED sacrifices the perforamce of a few applications by discarding their packets so that they send less traffic and the entire network doesn't suffer. In Cisco's WRED, packets with lower priority markings can be dropped more aggressively.
* **Policing and Shaping** - The policing and shaping mechanisms can limit the amount of bandwidth available to specific classes of traffic.  While _policing_ and _shaping_ are similar, _policing_ is more strict, with the default implementation of many _policing algorithms_ configured to throw away excess traffic when an application tries to use more than its allocated share of the bandwidth. Shaping is relatively _milder_ since if an application exceeds the **Comitted Information Rate (_CIR_)**, the excess packets are stored in a queue to be sent out when the bandwidth demand of the network tapers down.
* **Link Efficiency** - These are QoS mechanisms made to use the limited WAN bandwidth most efficiently. Techniques include **RTP Header Compression (_cRTP_)** and **Link Fragmentation and Interleaving (_LFI_)**. Voice and Video traffic use the **Realtime Transport Protocol (_RTP_)** and the header can be as large as `40B`. In such cases, compression can bring down the size of the header to `2-4B`. This particular method is actually caching since the routers at either end of the link can cache the redundant information among the voice packets' headers such as source and destination IP, source and destination UDP port number, RTP payload type, etc., thus reducing the amount of data that needs to be transferred. The routers store the headers locally and identify which inbound packet belongs to which header by their *Session Context ID (CID)*. Another link efficiency mechanism is LFI. We may have giant data packets clogging up the WAN link while smaller, high priority packets may be waiting for a chance to be transmitted. In such cases, we break down the giant data packets into smaller fragments and shuffle the high priorty smaller packets between them so that they can leave through the WAN interface sooner.

These QoS mechanisms can be implemented both at a router or switch. If our network is congested 24x7, the only permanent solution would be to buy extra bandwidth, but QoS can help us out during peak hour congestion when our networks only get congested for relatively short periods of time when traffic volume is high.

# Traffic Markings
Marking traffic saves the other routers/switches through which the packet will flow from re-analysing the packet to determine what kind of data it contains. Instead, they can just look up the marking and make their forwarding/dropping decisions based on the markings alone. We can have markings at both layer 2 and layer 3.

## Layer 2 Class of Service (_CoS_) Markings
The CoS marking in the layer 2 frame is a 3 bit value, which gives us a total of _2^3=8_ possible markings. Thus, the CoS marking can have any value between 0-7, but Cisco forbids us from using the values _6 or 7 (110-111)_, since they're for network use, leaving _0 (000) to 5 (101)_ for marking production traffic. _Cisco IP phones_ automatically mark voice packets with CoS value of _5_. Traffic can be marked with CoS values over both IEEE 802.1Q trunks as well as ISL trunks, though in production, we typically only use _.1q_ trunks.

In the case of 802.1Q frames, we have 4 bytes called the **Tag Control Information (_TCI_)** bytes. The first 3 bits in these 4 bytes are called the **Priority** field, and this is where the CoS markings are stored. The next 1 bit is called the **Canonical Format Indicator (_CFI_)** and it tells us whether the following bits, indicating the VLAN conform to the standards of an Ethernet frame or not. For Ethernet, CFI is always _0_ and _1_ for networks like token ring LANs. Finally, the next 12 bits (`3B`) are the VLAN indicator (for _4096_ possible VLANs) . In the case of ISL frames, there's a VLAN field, and within that field we use 3 bits to indicate our CoS.

It is also possible to mark a CoS marking in the layer 2 header coming from a PC through a **Network Interface Card (_NIC_)**, if the NIC supports **802.1p** priority markings. In this case, the NIC adds the 4B that the .1q frames have, so that it can provide the priority in the first 3 of the 16bits added. However, the final 12bits for the VLAN indicator are `0x0` (all zeroes) for .1p frames since they don't belong to any VLAN.

The problem with layer 2 markings is that they get re-written with every router hop and hence, all these bits of information are lost the moment the frame hits a router. When a frame crosses a router, the destination and source MAC addresses get re-written, and in a similar manner, the CoS bits get re-written to `000` when crossing a router. However, it's possible to have layer 3 markings as well that _do_ survive router hops.

## Layer 3 Type of Service (_ToS_) for IPv4 and Traffic Class for IPv6 Markings
The ToS markings are stored in the IP header. In the case of IPv4 it's called the **Type of Service (_ToS_)** byte and in case of IPv6 it's the **Traffic Class** byte. In it's present iteration, this field is also called the **DiffServ** or the *DS* field. In the ToS bytes, the first 3 bits are called the **IP Precedence** and are just like the CoS bits. They range from _000 to 111_ and like CoS, the values _6 and 7_ are reserved for network use. This gives us 6 levels of priority. However, in the case of certain network designs, we want more granular control of the priority, in which case we can use the next 3 bits as well as the first 3, in which case the first 6 bits of the ToS byte is called the **Differentiated Services Code Point (_DSCP_)**. This gives us _2^6=64_ possible values between _0 to 63_. However, this is too many values to have standard priority levels. Hence, the **Internet Engineering Task Force (_IETF_)** Standards body chose 21 among the 64 and gave them names called **Per Hop Behaviours (_PHB_s)**. Each of the 21 PHBs are in a particular category:
- **Default** - The default per-hop behaviour has a value of `00 0000` or `0x0`.
- **Expedited Forwarding (_EF_)** - This is for our high-priority, latency sensitive traffic such as voice/video packets. This has a value of `46`, `0b101110` in binary or `0x2E` in hex. Cisco IP phones not only set the CoS to `5` in the layer 2 header but also set the DSCP to `46` in the layer 3 header. The great part is since in binary the left most 3 bits `101` equate to 5, this value is still high priority for routers that only know about IP precedence. The last binary bit is **always 0** for any of the values selected by IETF.
- **Class Selector** - Class selector is made to be backwards compatible with IP precedence _speaking_ routers. Hence, only the IP Precedence bits are _set_ in these while the remaining 3 bits of DSCP are set to `0`. We don't have a CS0 since that's equal to the _default_ DSCP value. The possible values of class selectors are:
    * _CS1_ - `001 000` in binary, equal to `08` in decimal and `0x08` in hex, equal to IP precedence of `1`.
    * _CS2_ - `010 000` in binary, equal to `16` in decimal and `0x10` in hex, equal to IP precedence of `2`.
    * _CS3_ - `011 000` in binary, equal to `24` in decimal and `0x18` in hex, equal to IP precedence of `3`.
    * _CS4_ - `100 000` in binary, equal to `32` in decimal and `0x20` in hex, equal to IP precedence of `4`.
    * _CS5_ - `101 000` in binary, equal to `40` in decimal and `0x28` in hex, equal to IP precedence of `5`.
    * _CS6_ - `110 000` in binary, equal to `48` in decimal and `0x30` in hex, equal to IP precedence of `6`.
    * _CS7_ - `111 000` in binary, equal to `56` in decimal and `0x38` in hex, equal to IP precedence of `7`.
- **Assured Forwarding** - We have 12 possible *assured forwarding values*. The are written in the format: `AFxy` where `x`, the first digit, is the _IP precedence equivalent value_. For example, if we use a PHB of `AF21`, and the packet passes a router that only understands IP precedence, it'll look at the first 3 bits of AF21 (`0110 001`) and see that it's IP precedence value is `2`. Hence, all `AF2*` PHBs are called class 2 AF PHBs. The next number, `y` in `AFxy` is the **drop probability**, which is used by _WRED (Weighted Random Early Detection)_ to choose which packet to drop in the case of a network congestion. Any of the AFs in the high drop probability columns will be dropped before a single packet from medium drop probability and any of the medium drop probability packets will be dropped before the router has to drop a single one of the low drop probability packets.
```
Class #     Low Drop Probability    Medium Drop Probability     High Drop Probability
========    ====================    =======================     =====================
Class 1     AF11(10) - 001 01 0     AF12(12) - 001 10 0         AF13(14) - 001 11 0
Class 2     AF21(18) - 010 01 0     AF22(20) - 010 10 0         AF23(22) - 010 11 0
Class 3     AF31(26) - 011 01 0     AF32(28) - 011 10 0         AF33(30) - 011 11 0
Class 4     AF41(34) - 100 01 0     AF42(36) - 100 10 0         AF43(38) - 100 11 0
```

The formatting of the `AFxy` is such that the first 3 bits of the binary represent `x` and the next 2 bits represent `y`, and since IETF chose all these values to end in `0`, the last bit will always be `0`. Hence, we have `AF21` where `x = 2 = 010` and `y = 1 = 01` and finally, the **LSB (Least Significant Bit)** of _0_. Thus, AF21 in binary is `010 10 0` = _2^4+2^2 = 16 + 4 = 18_ in decimal.

We're going to assign a _default (0)_ PHB to our best-effort traffic. For our voice and other low-latency needs, we'll assign a Expedited Forwarding (_EF_) PHB of `46` due to its high priority. For the rest, such as our video or other data types, we'll use a class selector or a assured forwarding PHB.

### Assured Forwarding Value Practice Examples
- _Find the decimal equivalent for PHB **AF41**_ - AF41: 4 = `0b100`, 1 = `0b01`, LSB = `0`. So, AF41 = `0b 100 010` = `34` in decimal.
- _Find the PHB with the decimal equivalent **40**_ - `40` in decimal is `0b 101 00 0`. `0b101` is `5` and `0b00` is `0`. Since the last 3 bits are `0`, this must be a Class selector. Since the first 3 bits equate to 2, the PHB is _CS5_.

### Drop probabilities for different Assured Forwarding Per Hop Behaviours and RED/WRED
Interfaces have a buffer of a finite size where it stores packets of a certain priority when it can't transmit it due to limited bandwidth. When this queue/buffer overflows, there's data loss and uncontrolled slowdown of TCP streams, etc. This is where industry standard algorithms like RED come in. Let us consider the figure below, where we have a buffer that's capable of storing, say 64 packets with 24 packets being the minimum and 48 packets being the maximum thresholds.

After there are 24 packets in the queue, we're going to introduce the _possibility_ of randomly and occasionally throwing away some traffic. The probability of discarding traffic will get greater and greater as we approach the maximum threshold of 48 packets. After that, we'll definitely be throwing away traffic, i.e., after there are already 48 packets in the buffer, we'll throw away all traffic. Cisco _improved_ RED with **Weighted RED (_WRED_)** where we also consider the traffic's markings. All default, EF, class selector and AF PHBs have default RED profiles in Cisco's IOS, i.e., each have their own min and max thresholds and factors that define the probability of discard for each type of packet. The graph below shows the probability of discard for some of the AFs with respect to the queue depth:

In the graph above, let's consider we have a 25 packet min threshold for high-drop probability for the `AFx3`s, i.e., _AF13, AF23, AF33 and AF43_. Similarly, we have a `30` packet min threshold for `AFx2` and a `35` packet threshold for `AFx1` PHBs. Once we reach a max packet threshold of 100 on any queue (when probability of discard is _25%_), we'll start discarding all packets on that queue. There is a way, however, to prevent the aggressive discarding of the traffic, by using the final 2 bits of the layer 3 header.

## Explicit Congestion Notification (_ECN_)
The 7th and 8th bits of the _ToS_ byte are called the **ECN-Capable Transport (_ECT_)** bit and the **Congestion Experienced (_CE_)** bit. These two bits are used to notify the router at the far end that this router's getting congested and if they don't slow down, this router will have to start dropping packets. For this to work, first of all, the routers at both ends of the link need to be capable of ECN. These two bits are set on the basis of the following criteria:
```
Bit Combo   Meaning
=========   ====================================================================
00          Router doesn't have ECN functionality.
01/10       Router is capable of ECN, but isn't congested right now.          
11          Router is ECN capable and is currently congested.
```

Thus, if the routers can't use ECN, they set the ECT and CE bits to `00`. If they aren't congested right now, but can send congestion notifications to the far end, they use `01` or `10`. If they are currently congested, however, the bits are set to `11`, which informs the router at the far end to slow down while sending data to prevent dropping packets.

# Trusting Devices
Several devices are able to provide their own priority markings, such as a Cisco IP phone or IP camera, but we might not want to trust the markings from a PC, all of which plug into a switch. We may also have marking coming in from an enterprise cloud. Cisco's Catalyst switches have the ability to trust devices based on device identity. **Cisco Discovery Protocol (_CDP_)** lets Cisco's routers and switches know about the other _CDP-speaking_ devices connected to it, and thus know about the device identity. Some switches even have the ability to get the CoS value and then re-mark it to the corresponding DSCP value so that it can survive router hops.

Cisco IP phones show up as `SEPxyz...` under the `show cdp neighbors` command, where SEP stands for _Selsius Ethernet Phone_, a company Cisco acquired while first getting into the telephony business. Before we can ask the switch to trust the CoS markings coming from the IP phone, we need to turn on the global QoS settings:
```
sw1(config)#mls qos
```
Just by turning on the global QoS feature, we get the ability to mark layer 2 CoS values to Layer 3 ToS values. The mapping can be seen with:
```
sw1#show mls qos maps cos-dscp
   Cos-dscp map:
        cos:   0    1   2   3   4   5   6   7
     ----------------------------------------
       dscp:   0    8  16  24  32  40  48  56
```

Let us say we have a Cisco IP phone connected to interface `fa0/3`. We can ask the switch to trust the CoS value, but only if it comes from a Cisco IP phone. For this we have to first tell the switch which value to trust: CoS or DSCP. Then, we define which devices we'll trust. We do this by:
```
sw1(config)#int fa 0/3
sw1(config-if)#mls qos trust cos
sw1(config-if)#mls qos trust device cisco-phone
```
Now the CoS markings will only be trusted if they're coming from the IP phone, and not even if they come from a PC _daisy-chained_ to the IP phone so that the ethernet cable carries both voice and data VLANs.

# Prioritizing Traffic Types
When there's a speed mismatch between the ingress and the WAN ports for traffic leaving the network, for example, a GigE port for the ingress and a Serial port for the egress, we're going to need to store the incoming packets before sending them out via the WAN due to the speed mismatch. Thus, certain traffic will be allowed to leave sooner than the rest, which is where Queuing algorithms come into play. One such algorithm is **Class-Based Weighted Fair Queuing (_CBWFQ_)**. In this, we have a default class that includes all kinds of traffic, called _class-default_. This'll include any kind of traffic that we don't categorize. For this class, we can turn on **Weighted Fair Queuing (_WFQ_)** to treat all the packets in this class fairly. For the traffic that we _do care enough to make a special class about_, we also have a _default class_. Cisco recommends that we create no more than 11 special classes. This brings the total possible classes to _11 + 1(default) = 12_.

Let us consider that we have a class called _Bulk-Data_ for telnet/FTP etc traffic that aren't mission critical. Using CBWFQ, we set up the minimum bandwidth allocations, and hence, if we assign 1Mbps of bandwidth to Bulk Data, the device going to make sure that **at least 1Mbps** of bandwidth is available for the members of this class, and if more bandwidth is available, it can be given to the class. If we have another class for _critical-data_, we can assign a minimum bandwidth of 3Mbps as well. If there's a Network Control class of traffic, we can guarantee that it gets 1Mbps even during the heaviest congestion. We could also have a separate class for call signalling, which gets 1Mbps bandwidth. This is the way CBWFQ works - by categorizing traffic early on and then populate the different classes with individual traffic flows. Finally, we allocate the desired bandwidth to each class and guarantee the minimum bandwidth available to each one of the them when they need it.

## Low Latency Queuing (_LLQ_)
The CBWFQ method, however, doesn't work well with _latency-sensitive data_  like voice or video, for which we have to add a priority queue. We're configuring it so that during the times of congestion, the priority queue can have up to a certain (Say 3Mbps) bandwidth for the traffic and we'll never let it get larger than the bandwidth assigned to it, since we have to put a speed limit on the priority queue so that it doesn't starve the other queues. When we add a priority queue to _CBWFQ_, it's called **Low Latency Queuing (_LLQ_)**. The caveat with LLQ is that if we need to prioritize both voice and video, they won't go into two separate pririoty queues, but into a single queue, and will have to share the bandwidth for the priority queue.

# Shaping vs Policing
There are two types of traffic conditioners: policing and shaping. The purpose of a traffic conditioner is to set a maximum bandwidth for a class of traffic, i.e., a maximum speed for the class. The issue with this is that interfaces can't suddenly alter their speeds, i.e., once configured, both interfaces at either end of the links have to receive and transmit at the same speed, and thus, it's not possible for them to slow down/change their speed, due to the fact that it's a _clocked interface_, and must transmit at the configured line speed.

As such, the interfaces must transmit at the target speed on average. This means that if a 100Mbps link has to operate at a target speed of 50Mbps due to congestion, it has to transmit for 50% of the time and then wait before transmitting again. Thus, the interface transmits at line rate and then stops so that the device with the ingress interface at the receiving end has time to clear out its buffers by sending out the data through its WAN interface.

Policing is typically used on our _higher speed interfaces_ while shaping is used on _lower speed interfaces_. In the case of both shaping and policing, we divide the seconds into several intervals of the same length. Let us consider that the timing interval in this case is 1/8th of a second = 125ms. There are a few terms that need to be defined:
* **Comitted Information Rate (_CIR_)** - The CIR is the **average** speed over a period of *1 second*.  `CIR = Bc/Tc`. The CIR is used for both policing and shaping policies.
* **Commited Burst (_Bc_)** - Number of **bits** *(for shaping)* or **Bytes** *(for policing)* that are deposited in the token bucket during a timing interval.
* **Timing Interval (_Tc_)** - The interval at which tokens are deposited in the token bucket.

Thus *Bc* is the number of bits for shaping or bytes for policing sent out during a timing interval and the Tc is the length of each timing interval. So, if we want a CIR of 64Kbps, and the Tc is 1/8th of a second, the value of Bc is 8,000. This would mean that we'd have to send out 8000 bits every 125ms to transmit at the CIR of 64Kbps. Cisco uses the imagery of a bucket to collect tokens of size Bc that gets filled every timing interval. Now, if our line rate is 128Kbps, then we'd end up sending data at double the CIR if our speed isn't controlled. To fix this, we use policing/shaping.

Our Bc defines the number of bits we can send out every interval for transmission via the egress interface. Hence, we set the size of Bc such that we transmit for 50% of each interval and then wait for our own token bucket of size Bc to get replenished, which happens at the beginning of the next interval. Thus, we send all 8000 bits in our bucket then wait 1/250th of a second for our bucket to get filled at the start of the next interval again. So on a total, we'll be sending 8000 bits 8 times = 64,000 bits over 1 second = 64Kbps.

# QoS Configuration Example
The procedure to configure quality of service via the command line is a 3-step process called the **Modular Quality of Service Command-line Interface [_Modular QoS CLI_] (_MQC_)** :
- **Class-map** - We start out by defining a bunch of _class-maps_. Each class-map is a definition for a particular class of traffic. Thus, we can put email in a class map, web-traffic in another class-map, and voice traffic in another class-map etc. Cisco states that we should define no more than 11 class-maps for a policy-map.
- **Policy-map** - In this step, we define what we're going to do with a particular class of traffic. We have several options, like marking the traffic, configure Class Based Weighted Fair Queuing CBWFQ or Low Latency Queuing (LLQ), or configure WRED, RTD header compression, etc. Now, we can apply the policy thus created.
- **Service-policy** - Finally, we use the `service-policy` command to apply the policy-map to an interface in the inbound or outbound direction.

## Class-Map Config
We start by configuring a class-map with the `class-map` command in the global configuration mode:
```
HQ(config)#class-map ?
  WORD       class-map name
  match-all  Logical-AND all matching statements under this classmap
  match-any  Logical-OR all matching statements under this classmap
  type       Configure CPL Class Map
```
We may choose to have all the provided conditions match with a boolean _AND_ or select any statement that matches on the basis of boolean _OR_.

Let us consider we're creating a class-map for email. Since it's not possible for a packet to simultaneously be a Microsoft Exchange and IMAP and POP3 packet, we'll use the `match-any` clause:
```
HQ(config)#class-map match-any EMAIL
HQ(config-cmap)#match ?
  access-group         Access group
  any                  Any packets
  application          Application to match
  cac                  Call Admission Control
  class-map            Class map
  cos                  IEEE 802.1Q/ISL class of service/user priority values
  destination-address  Destination address
  discard-class        Discard behavior identifier
  dscp                 Match DSCP in IPv4 and IPv6 packets
  fr-de                Match on Frame-relay DE bit
  fr-dlci              Match on fr-dlci
  input-interface      Select an input interface to match
  ip                   IP specific values
  metadata             Metadata to match
  mpls                 Multi Protocol Label Switching specific values
  not                  Negate this match result
  packet               Layer 3 Packet length
  precedence           Match Precedence in IPv4 and IPv6 packets
  protocol             Protocol
  qos-group            Qos-group
  security-group       Security group
  service              Service Instance to match
  source-address       Source address
  vlan                 VLANs to match
```
We can see there are several criteria on the basis of which we can refine the traffic for the class-map. We'll be using `protocol` since it'll allow the system to use **Network Based Application Recognition (_NBAR_)**, which can even look at layer 7 information in the packet to determine the protocol, by performing a *deep packet inspection*. We'll match packets for MS Exchange:
```
HQ(config-cmap)#match protocol exchange
```
The first time we enter this command, it'll take a little time for the command prompt to appear again, since the router has to check if IP CEF is turned on because NBAR needs it for its operation. Now we'll also add the SMTP, POP3 and IMAP protocols:
```
HQ(config-cmap)#match proto smtp
HQ(config-cmap)#match proto imap
HQ(config-cmap)#match proto pop3
```

We'll create another class-map for web traffic:
```
HQ(config-cmap)#class-map match-any WEB
HQ(config-cmap)#match proto http
HQ(config-cmap)#match proto secure-http
```

Finally, we'll create one that has a single protocol - for torrent traffic - which means we don't need to specify `match-any` or `match-all`. If we don't specify either, the default is **match-all**. We'd also like to create a class-map for voice so that we can prioritize it. It uses RTP but the Real Time Protocol is also used by video chat software. So, we'd like to specify RTP audio:
```
HQ(config-cmap)#class-map DOWNLOADS
HQ(config-cmap)#match proto bittorrent
HQ(config-cmap)#class-map VOICE
HQ(config-cmap)#match proto rtp ?
  audio             Match voice packets
  in-app-hierarchy  Match protocol in transport hierarchy
  payload-type      Match an explicit PT
  potentially       Match protocol, and all potentiall traffic
  video             Match video packets
  <cr>

HQ(config-cmap)#match proto rtp audio
```

Now we can see the existing class-maps using the `show class-map` command:
```
HQ#sh class-map
 Class Map match-any class-default (id 0)
   Match any

 Class Map match-all DOWNLOADS (id 3)
   Match protocol bittorrent

 Class Map match-any EMAIL (id 1)
   Match protocol exchange
   Match protocol smtp
   Match protocol imap
   Match protocol pop3

 Class Map match-any WEB (id 2)
   Match protocol http
   Match protocol secure-http

 Class Map match-all VOICE (id 4)
   Match protocol rtp audio
```

## Policy-Map Config
First we name our policy map and enter it's configuration mode:
```
HQ(config)#policy-map BW_CONT
HQ(config-pmap)#?
Policy-map configuration commands:
  class        policy criteria
  description  Policy-Map description
  exit         Exit from policy-map configuration mode
  no           Negate or set default values of a command
```
We can see that there are not many options here. To define what policy we'd like to apply to the class-map, we have to enter the class configuration mode within the policy map (_pmap-c_). Let us set the policy for email first:
```
HQ(config-pmap)#class EMAIL
HQ(config-pmap-c)#?
Policy-map class configuration commands:
  admit            Admit the request for
  bandwidth        Bandwidth
  compression      Activate Compression
  drop             Drop all packets
  exit             Exit from class action configuration mode
  fair-queue       Enable Flow-based Fair Queuing in this Class
  flow             Flow subcommands
  log              Log IPv4 and ARP packets
  measure          Measure
  netflow-sampler  NetFlow action
  no               Negate or set default values of a command
  police           Police
  priority         Strict Scheduling Priority for this Class
  queue-limit      Queue Max Threshold for Tail Drop
  random-detect    Enable Random Early Detection as drop policy
  service-policy   Configure QoS Service Policy
  set              Set QoS values
  shape            Traffic Shaping
```
We can enable all class-based QoS mechanisms like policing/shaping/queuing, etc here:

### Marking
First we'll begin by setting our DiffServ PHB for the class, by assigning a DSCP marking to it:
```
HQ(config-pmap-c)#set dscp ?
  <0-63>     Differentiated services codepoint value
  af11       Match packets with AF11 dscp (001010)
  af12       Match packets with AF12 dscp (001100)
  af13       Match packets with AF13 dscp (001110)
  af21       Match packets with AF21 dscp (010010)
  af22       Match packets with AF22 dscp (010100)
  af23       Match packets with AF23 dscp (010110)
  af31       Match packets with AF31 dscp (011010)
  af32       Match packets with AF32 dscp (011100)
  af33       Match packets with AF33 dscp (011110)
  af41       Match packets with AF41 dscp (100010)
  af42       Match packets with AF42 dscp (100100)
  af43       Match packets with AF43 dscp (100110)
  cos        Set packet DSCP from L2 COS
  cs1        Match packets with CS1(precedence 1) dscp (001000)
  cs2        Match packets with CS2(precedence 2) dscp (010000)
  cs3        Match packets with CS3(precedence 3) dscp (011000)
  cs4        Match packets with CS4(precedence 4) dscp (100000)
  cs5        Match packets with CS5(precedence 5) dscp (101000)
  cs6        Match packets with CS6(precedence 6) dscp (110000)
  cs7        Match packets with CS7(precedence 7) dscp (111000)
  default    Match packets with default dscp (000000)
  ef         Match packets with EF dscp (101110)
  qos-group  Set packet dscp from QoS Group.
  tunnel     set tunnel packet dscp
```
We can specify either the PHB name or the decimal value for the DSCP:
```
HQ(config-pmap-c)#set dscp af11
```

### Class Based Weighted Fair Queuing with Bandwidth
We can turn on CBWFQ or LLQ with the `bandwidth` command. Here we want to use Class Based Weighted Fair Queuing:
```
HQ(config-pmap-c)#bandwidth ?
  <1-2000000>  Kilo Bits per second
  percent      % of total Bandwidth
  remaining    percent/ratio of the remaining bandwidth

HQ(config-pmap-c)#bandwidth 10000
```
We just instructed the router to allocate at least 10,000Kbps = 10Mbps bandwidth for emails. If more is required, and is avialable, then it'll be allocated. Let us allocate the same for web-traffic:
```
HQ(config-pmap-c)#class WEB
HQ(config-pmap-c)#bandwidth 10000
```

### Congestion Avoidance with WRED and ECN
We can turn on WRED to drop packets based on several criteria. Here, we want to randomly drop packets on the basis of DSCP:
```
HQ(config-pmap-c)#random-detect ?
  atm-clp-based                   Enable atm-clp-based WRED as drop policy
  clp                             parameters for each clp value
  cos                             parameters for each cos value
  cos-based                       Enable cos-class-based WRED as drop policy
  discard-class                   parameters for each discard-class value
  discard-class-based             Enable discard-class-based WRED as drop
                                  policy
  dscp                            parameters for each dscp value
  dscp-based                      Enable dscp-based WRED as drop policy
  ecn                             explicit congestion notification
  exponential-weighting-constant  weight for mean queue depth calculation
  precedence                      parameters for each precedence value
  precedence-based                Enable precedence-based WRED as drop policy
  <cr>

HQ(config-pmap-c)#random-detect dscp-based
```
We can also turn on Explicit Congestion Notifications (ECN) that ask the sender to slow down using:
```
HQ(config-pmap-c)#random-detect ecn
```

### Policing and Shaping
We want to police our torrent traffic such that any packet that exceeds the 1Mbps rate is discarded. For this, we use:
```
HQ(config-pmap-c)#police 1m ?
  <1000-512000000>  Burst bytes
  bc                Conform burst
  conform-action    action when rate is less than conform burst
  pir               Peak Information Rate
  <cr>

HQ(config-pmap-c)#police 1m
HQ(config-pmap-c-police)#
```
We had an option to define the conformity action - whether to allow that traffic to pass or block, but since we chose to use the _default_ action, any packet exceeding the 1Mbps bandwidth will be dropped.

### Low Latency Queuing with Priority
The idea behind a low-latency queuing is to allocate it to a **priority queue** with a maximum bandwidth upto which we will allow it to consume. This is to ensure that even during network congestion, when the priority queue will be getting its data sent first, we won't have it starving the other classes of their bandwidth. We can assign the _VOICE_ class to a priority queue and set the limit using:
```
HQ(config-pmap-c-police)#class VOICE
HQ(config-pmap-c)#priority ?   
  <1-2000000>  Kilo Bits per second
  level        Multi-Level Priority Queue
  percent      % of total bandwidth
HQ(config-pmap-c)#priority 1000
```
We just ensured that the low latency packets will be passed first as long as their flow remains below 1Mbps, i.e., we set a maximum bandwidth of 1Mbps to the low latency priority queue.

### Compression
RTP compression depends upon the type of interface we use. Since we're using GigabitEthernet interfaces, it won't be accpeted, but for some slower speed interfaces, this can be applied. To turn on RTP compression, we use:
```
HQ(config-pmap-c)#compression header ip ?
  rtp  configure rtp header compression
  tcp  configure tcp header compression
  <cr>

  HQ(config-pmap-c)#compression header ip rtp
```

Finally, we can check our policy-maps using:
```
HQ(config)#do sh policy-map
  Policy Map BW_CONT
    Class EMAIL
      set dscp af11
      bandwidth 10000 (kbps)
    Class WEB
      bandwidth 10000 (kbps)
       wred, exponential weight 9
      random-detect ecn

      dscp    min-threshold    max-threshold    mark-probablity
      ----------------------------------------------------------
      default (0)   -                -                1/10
    Class DOWNLOADS
     police cir 1000000 bc 31250
       conform-action transmit
       exceed-action drop
    Class VOICE
      priority 1000 (kbps)
```

## Applying policy to interface with service-policy
We can apply a policy to an interface in an inbound/outbound direction. Whether we can apply it in our preferred direction depends upon the configuration of the policy map itself. For example, shaping or queuing can't be set up in the inbound direction on an interface. To apply our policy to the interface **Gi0/0**  in the outbound direction, we use:
```
HQ(config)#int g0/0
HQ(config-if)#service-policy output BW_CONT
```

To see the policies that have been applied to a particular interface, we use:
```
HQ#sh policy-map interface g0/0
 GigabitEthernet0/0

  Service-policy output: BW_CONT

    queue stats for all priority classes:
      Queueing
      queue limit 64 packets
      (queue depth/total drops/no-buffer drops) 0/0/0
      (pkts output/bytes output) 0/0

    Class-map: EMAIL (match-any)  
      0 packets, 0 bytes
      5 minute offered rate 0000 bps, drop rate 0000 bps
      Match: protocol exchange
        0 packets, 0 bytes
        5 minute rate 0 bps
      Match: protocol smtp
        0 packets, 0 bytes
        5 minute rate 0 bps
      Match: protocol imap
        0 packets, 0 bytes
        5 minute rate 0 bps
      Match: protocol pop3
        0 packets, 0 bytes
        5 minute rate 0 bps
      Queueing
      queue limit 64 packets
      (queue depth/total drops/no-buffer drops) 0/0/0
      (pkts output/bytes output) 0/0
      QoS Set
        dscp af11
          Packets marked 0
      bandwidth 10000 kbps

    Class-map: WEB (match-any)  
      0 packets, 0 bytes
      5 minute offered rate 0000 bps, drop rate 0000 bps
      Match: protocol http
        0 packets, 0 bytes
        5 minute rate 0 bps
      Match: protocol secure-http
        0 packets, 0 bytes
        5 minute rate 0 bps
      Queueing
      queue limit 64 packets
      (queue depth/total drops/no-buffer drops) 0/0/0
      (pkts output/bytes output) 0/0
      bandwidth 10000 kbps
        Exp-weight-constant: 9 (1/512)
        Mean queue depth: 0 packets
        dscp       Transmitted    ECN       Random drop      Tail drop          Minimum        Maximum     Mark
                pkts/bytes     marked        pkts/bytes       pkts/bytes          thresh         thresh     prob


    Class-map: DOWNLOADS (match-all)  
      0 packets, 0 bytes
      5 minute offered rate 0000 bps, drop rate 0000 bps
      Match: protocol bittorrent
      police:
          cir 1000000 bps, bc 31250 bytes
        conformed 0 packets, 0 bytes; actions:
          transmit
        exceeded 0 packets, 0 bytes; actions:
          drop
        conformed 0000 bps, exceeded 0000 bps

    Class-map: VOICE (match-all)  
      0 packets, 0 bytes
      5 minute offered rate 0000 bps, drop rate 0000 bps
      Match: protocol rtp audio
      Priority: 1000 kbps, burst bytes 25000, b/w exceed drops: 0


    Class-map: class-default (match-any)  
      12 packets, 1310 bytes
      5 minute offered rate 0000 bps, drop rate 0000 bps
      Match: any

      queue limit 64 packets
      (queue depth/total drops/no-buffer drops) 0/0/0
      (pkts output/bytes output) 12/1310
```
This shows us the combined output of both the `show class-map` and `show policy-map` commands, along with the usage statistics for each class, like packet and byte counts.

# Cloud Resources
# Cloud Computing Fundamentals
Traditionally all servers and networking gear was hosted at the enterprise premises or a data-center, but recently there has been a trend of migrating to cloud service providers where storage, computing resources like memory and processing power, databases and services like email are handled by the cloud service provider and the equipment to support all this is physically hosted at the service provider's premises. This is called _cloud computing_. This takes the _headache_ of server provisioning, maintenance and repair to the cloud provider. There are primarily three types of clouds:
* **Public Clouds** - These are the services that interact with publicly accessible networks like the internet or with other public clouds.
* **Private Clouds** - Here, the provided services are only accessible by and interact with other members of the private cloud, i.e., devices within a company.
* **Hybrid Clouds** - This is a collection of services some of which interact with a public cloud and some which interact with a private cloud.

Typical cloud services include:
* **Infrastructure as a Service (_IaaS_)** - This is a service where the service providers allow companies to rent virtualized servers that run specific applications. Instead of paying for the hardware, the companies rent it on an _as needed_ basis, thus offering quick provisioning and scalability of services.
* **Platform as a Service (_PaaS_)** - PaaS offers the developers in a company a platform (servers, infrastructure and operating system and other required software) on which they can deploy their own code, primarily of use to application programmers. This again is highly scalable and offers the opportunity to deploy quickly.
* **Software as a Service (_SaaS_)** - Here the cloud provider directly provides all the software and the infrastructure needed to run that software and store its data for the company. The software is typically licensed and hosted by the cloud service provider and the users connect to the software and use it via a web browser.
* **Network as a Service (NaaS)** - In this scenario, the cloud provider makes network resources such as VPNs, elastic bandwidth, and internet connectivity available to the customer.

# Accessing Cloud Services
With the cloud provider taking over the infrastructure responsibilities, a new problem arises. How does an enterprise connect to the cloud provider which houses a majority its corporate computing infrastructure? An option would be through the internet. This would however, pose a huge security threat since our data will traverse an untrusted network which opens us up for _man-in-the-middle_ attacks, etc. Another issue would be the Quality of Service (QoS) - when our data traverses the internet, there's no guarantee that our ISP will provide us a reliable QoS for all our services.

A pro of this would be that we could connect very quickly since the company will already ahve a connection to the internet and there's no hassle of obtaining a connection from a private WAN provider. Another pro is that when changing cloud providers, we don't have to change our out-going connection since we're connecting to the internet. Another method would be to still use the internet, but have our data flow through a secure, encrypted VPN tunnel. This'll mitigate some security concerns such as _man-in-the-middle_ attacks, but QoS will still suffer.

An alternative would be to engage a private WAN provider. Then we could use a technology such as MPLS or Metro Ethernet to connect to our cloud services provider. The pros of this method is that we get the security that we desire and they'll also take care of the QoS issues, but this will take longer and more effort to set up. Further, if we want to change cloud provider, we'll have to get another private WAN connection to that new cloud provider.

A much better alternative is **Intercloud Exchange** or _cloud-of-clouds_ which lets an enterprise easily connect to several cloud providers. Thus, the company needs only connect to the one intercloud exchange, which will then connect us to our cloud provider. At the time of changing cloud providers, all we need to do is to ask our intercloud exchange to switch us over to the new provider. This gives us the security, QoS and no change to the the outgoing link, but it'll still take a bit of time to connect to the intercloud exchange as compared to the internet.

# Virtual Services
Let us consider the scenario below. We are connected to the cloud provider where all our servers are hosted in VMs. This is very beneficial since if we need to quickly increase our resources, the cloud provider can provision the resources and we merely need to spin up a couple of extra VMs. In case the servers are identical, the cloud provider may be running some **Virtual Server Load Balancer (_vSLB_)** that distributes the load to the VMs. However, the cloud provider's router, vSLB or any other equipment won't be configured by us, and if we need a little more control over the data that flows in and out of our network, we need to have equipment in the chain to our VMs. However, the cloud provider won't let us install our own hardware in the racks of their own data-centers. So, we require virtual network gear.

For security, Cisco provides software firewalls called **_Adaptive Security Virtual Appliances (ASAv)_** that lets us do almost anything that a physical firewall would let us do, but runs inside a VM. Similarly, if we need routers, we have Cisco's **CSR1000V** which is a *software-only* virtual Router. It runs a version of Cisco's IOS called the IOS-XE. Again, this lets us do almost anything a phsycial router would. For example, let's say we want our VMs to source the time via NTP from our router, in which case we can use the virtual router running inside a VM.

# Securing Network Devices
# Advanced Switch Security
# Non-Default Native VLAN
Cisco always suggests that instead of a monolithic model of security, we have several layers of security. Just one of the many layers is *security best practices for security Cisco's Catalyst Switches*. A native VLAN is a VLAN on a 802.1Q trunk whose frames are not tagged. In the Layer 2 header, there's 4 bytes that can identify which VLAN the frame is a member of.

## VLAN hopping with double-tagging
By default, the VLAN 1 on a Cisco switch is the native VLAN for all trunks and by default all switchports belong to VLAN 1 unless configured otherwise. This mean that if an attacker gains access to a port on VLAN 1 then he can launch a **VLAN hopping attack**, where the attacker is able to attack a device in another subnet without crossing a router. 802.1ad (**QinQ or Stacked VLAN**) which extended 802.1Q trunks allow for _double-tagging_ so that ISPs can use their own VLAN tags with their own 802.1Q header for internal switching, called Service Provider tag or _S-Tag_, while simultaneously maintaining customer's original VLAN tags, called _C-tag_, with a separate 802.1Q header. This is needed especially in Metro Ethernet networks where the VLAN information of the customer might need to be maintained.

In a VLAN hopping attack, the attacker fills in the S-tag with their original VLAN ID and the C-tag with the VLAN id of the destination subnet. If the trunk port is configured on the native VLAN of the trunk, then the first switch will remove the S-Tag and send the frame, _untagged_ to the second switch. The seconds switch now sees the _fake_ value in the C-tag and sends it into the targeted VLAN which it's not meant to access. This is a useful method for Denial of Service (DoS) attacks as they don't need any replies from the server to reach the attacker.

To mitigate this, we have to ensure that all non-used ports are in a separate, non-used VLAN and further, change the native VLAN on all switches to a non-default value - any value but VLAN 1 since the attacker might guess it. We should also ensure that no production traffic flows through a native VLAN port. Finally, we can turn on the forced tagging of native VLAN on all switches using `vlan dot1q tag native`.

## VLAN hopping by switch spoofing
Since switches don't by default need any authentication to form trunk ports, and since by default all VLANs are allowed on all trunks, an attacker may send DTP frames to a switch that's set to dynamic _desirable/dynamic auto_ trunk modes and thus form a trunk, which would then allow them to listen to the traffic on all VLANs. To mitigate this, all switchports that are not meant to form trunks or all switchports that aren't in a secured room should be hardcoded to form an access port and not a dynamic port.

# 802.1x Network Authentication
The traditional way to secure resources on the network is to secure the resource itself. For example, if we have a server in the network, we'd want to protect it with a user id and a password. However, if the server's OS has a vulnerability that the attacker knows about, then the attacker might find a way to circumvent the security features of the server. Hence, we have **IEEE 802.1x** that makes the users authenticate and prove that they are who they say they are before granting them access to resources on the network. It can be used in both wired and wireless environments. Let us consider the topology below where a laptop is connected to a server with a switch connecting the two. Here, the laptop is called the _supplicant_ which asks the switch, which is the _Authenticator_ to grant access to the network. The valid credentials are stored in the *Authentication Server* which in this case is the server. Typically, this might be a **Remote Authentication Dial-In User Service (_RADIUS_) Server**, which is a type of a **AAA Server***, which confirms that the supplicant has provided a valid _username-password_ combination.

When a supplicant first connects to a switchport, the authenticator, i.e., the switch sends it a _challenge_. The supplicant then responds with a _challenge response_, which is typically a _username-password_ combination which is then passed on to the authentication server which verifies that the credentials are valid. The only reason the supplicant can speak to the authentication server is because 802.1x makes an exception where the supplicant can only talk to the auth server using the necessary ports on that server. Thus, if we're connecting to the authentication server which is a RADIUS server, we'll only be able to talk to the authentication server on the port used by RADIUS, and everything else on the network is going to be blocked. Once the credentials have been validated by the authentication server, it sends an *authorization* to the authenticator, i.e., the switch to let the laptop join the network.

## 802.1x Encryption
Now that the new host is authenticated, we can also perform encryption using 802.1x, which uses some variant (or _method_) of the **Extensible Authentication Protocol (_EAP_)**, which defines how authentication is done between the supplicant and the authenticator. EAP can encrypt the communication between the switch and the authenticator. While sending the authorization to the switch, the auth server can provide keys to encrypt traffic between itself and the host to the authenticator, thus encrypting traffic. This will prevent eavesdropping and _man-in-the-middle_ attacks.

# DHCP Snooping
DHCP servers work using the **DORA** process, where the client first sends out a *Discover* request to see which DHCP server is available on the network, to which the DHCP server responds with a *Offer*, stating the identity of the server. At this point, the client sends a *Request* for the information it needs to connect to the network and finally, the server responds with an *Acknowledgement* with the requested details containing the IP address, the DNS details, etc. Let us consider the topology below: the DHCP server is on the same subnet as the laptop. Even if it weren't we could just go the the gateway router of the laptop and there use the `ip helper-address <IPaddr>` to provide the IP address of the DHCP server on another subnet and the DHCP discover broadcasts would be sent to it.

If a malicious agent puts a rogue DHCP server in the network, perhaps plugs it in to the same switch the laptop's connected to, it can intercept the DHCP broadcast and respond with the offer _faster_ than the corporate DHCP server. Our laptop would use the offer it gets first, and hence use the malicious agent's device as the default gateway and allow the intruder's device to intercept all the traffic to the actual server.

To prevent this from happening, Cisco Catalyst switches have a feature called DHCP snooping where we can mark the switchports as either trusted or untrusted and then reject all DHCP packets coming from a DHCP server connected to a port in an untrusted state. In addition to protection from DHCP snooping, this also protects the clients on the switch from getting responses from rogue DHCP servers that were accidentally left _on_ when the clients were reconfigured.

## DHCP Snooping Configuration
Consider the topology below. We have a genuine and a rogue DHCP server connected to the same switch. Thus, when the client requests an IP address, it can get an address from either `192.168.1.0/24` network connected to the genuine DHCP server or `192.168.2.0/24` rogue DHCP server:
```
Client> ip dhcp
DDORA IP 192.168.1.51/24 GW 192.168.1.1

Client> ip dhcp -r
DORA IP 192.168.2.51/24 GW 192.168.2.1
```
To prevent this, we'll enable DHCP snooping on the switch, _sw1_.

We start off by first globally enabling DHCP snooping from the configuration mode. However, simply globally turning it on won't enable DHCP snooping in any of our VLANs. We also have to enable it on VLAN1, where all our switchports are located.
```
sw1(config)#ip dhcp snooping
sw1(config)#ip dhcp snooping vlan 1
```
This sets all the ports in VLAN 1 in an **untrusted** state, which means any and all DHCP offers will be rejected by the switch. In this condition, our client won't even be able to get an IP from the genuine DHCP server:
```
Client> ip dhcp
DDD
Can't find dhcp server
```
To fix this, we need to we need to trust the interface in terms of DHCP snooping.

We first go into interface config and then use the `ip dhcp snooping trust` command:
```
sw1(config)#int e0/0
sw1(config-if)#ip dhcp snooping trust
```

At this point, we'll see that the DHCP requests from the clients still fail even though the DHCP server's port is trusted. This is because of a _zero value in **giaddr** field_ due to enabling of **DHCP Informatin Option/Option 82**. The Option 82 feature is used in Metro Ethernets or large enterprise deployment to denote where the client is physically attached when the DHCP server is separated from the client by one or more DHCP relay agents. The DHCP packets contain a field called _giaddr_ which the relay is supposed to fill to specify information about the switch-port from which the packet originates. The DHCP server can then use the information in Option 82 to select a _sub-pool_ from the pool of IP addresses based on that information. The issue is, by default Cisco IOS switches are configured to send a _zero giaddr_ field in the option 82 information and Cisco IOS routers are set to reject any packet with zero giaddr field. So, even though the router receives a DHCP discovery message, it doesn't respond:
```
DHCP#debug ip dhcp server packet
DHCP server packet debugging is on.
*Jan  9 10:17:50.919: DHCPD: inconsistent relay information.
*Jan  9 10:17:50.921: DHCPD: relay information option exists, but giaddr is zero.
```

To solve this, we have two options:
* We can ask the DHCP server to trust the packets with _zero giaddr field_ with `ip dhcp relay inform trust-all` in the global configuration mode OR `ip dhcp relay inform trusted` in the interface configuration mode.
* We can ask the switch not to insert the option 82 information all together with the `no ip dhcp snooping information option` in global config mode.

In this case, since we don't want to disable option 82, we'll ask the DHCP server to trust the packet. This however will mean that this'll have to be done on all DHCP servers in an environment where we have multiple DHCP servers (perhaps for different VLANs) on different routers. So, we go to the DHCP server and use:
```
DHCP(config)#ip dhcp relay inform trust-all
```
In order to test our DHCP snooping, we also do this on the intruder:
```
Rogue(config)#ip dhcp relay inform trust-all
```

Now when we try to get an IP address, the right DHCP server will be the one that's trusted by the switch:
```
Client> ip dhcp
DDORA IP 192.168.1.52/24 GW 192.168.1.1
```

We can also see that the offer packet from the intruder is rejected:
```
sw1#sh ip dhcp snooping statistics
 Packets Forwarded                                     = 2
 Packets Dropped                                       = 12
 Packets Dropped From untrusted ports                  = 12

sw1#sh ip dhcp snooping statistics detail
 Packets Processed by DHCP Snooping                    = 14
 Packets Dropped Because
   IDB not known                                       = 0
   Queue full                                          = 0
   Interface is in errdisabled                         = 0
   Rate limit exceeded                                 = 0
   Received on untrusted ports                         = 12
   Nonzero giaddr                                      = 0
   Source mac not equal to chaddr                      = 0
   No binding entry                                    = 0
   Insertion of opt82 fail                             = 0
   Unknown packet                                      = 0
   Interface Down                                      = 0
   Unknown output interface                            = 0
   Misdirected Packets                                 = 0
   Packets with Invalid Size                           = 0
   Packets with Invalid Option                         = 0
```

## Preventing DoS attacks on DHCP Servers
The rogue server can now start a Denial of Service attack on the legitimate DHCP server by flooding it with DHCP discover requests. Hence, we should rate-limit the DHCP traffic on it's connected interface and in fact, all untrusted interfaces to a maximum number of packets per second:
```
sw1(config)#int g0/0
sw1(config-if)#ip dhcp snoop limit rate 100
sw1(config-if)#int ran g0/2-3
sw1(config-if-range)#ip dhcp snoop lim rate 100
```

## Checking DHCP Snooping Configuration
We can check the current DHCP snooping configuration using the `show ip dhcp snooping` command:
```
sw1#sh ip dhcp snooping
Switch DHCP snooping is enabled
Switch DHCP gleaning is disabled
DHCP snooping is configured on following VLANs:
1
DHCP snooping is operational on following VLANs:
1
DHCP snooping is configured on the following L3 Interfaces:

Insertion of option 82 is enabled
   circuit-id default format: vlan-mod-port
   remote-id: 0c27.bb00.9f00 (MAC)
Option 82 on untrusted port is not allowed
Verification of hwaddr field is enabled
Verification of giaddr field is enabled
DHCP snooping trust/rate is configured on the following Interfaces:

Interface                  Trusted    Allow option    Rate limit (pps)
-----------------------    -------    ------------    ----------------   
GigabitEthernet0/0         no         no              100       
  Custom circuit-ids:
GigabitEthernet0/1         yes        yes             unlimited
  Custom circuit-ids:
GigabitEthernet0/2         no         no              100       
  Custom circuit-ids:
GigabitEthernet0/3         no         no              100       
  Custom circuit-ids:
```
Here, we can see that DHCP snooping is up and operational on VLAN1, and that option 82 is enabled which means that the VLAN information and the MAC address of the client are sent to the DHCP server for evaluation during the discovery phase to help ensure a proper sub-pool of IP (if configured) is assigned to it. we can also see the rate-limits on the untrusted ports.

# Authentication, Authorization and Accounting (_AAA_)
**Authentication** involves proving we are who we claim to be. In the case of networks, this may mean proving we have access to the network by providing a username-password combo. Once the identity is validate, the authenticating systems bestows upon the user a set of privileges that allows the user to use the system in a certain way, which is called **Authorization**. **Accounting** keeps a record of the activity of the user on the network.

The authorizer is a router/switch to which we connect to be connected to the rest of the network, which is also called the **Network Access Server**. The AAA server might itself be running TACACS+ or RADIUS, etc, and it might be configured to let a Network Administrator connect to the router/switch itself. This is especially needed in an enterprise network where it's not possible to keep local copies of login credentials for every administrator on every device!

Some of the features of TACACS+ are:
* TACACS+ stands for **Terminal Access Controller Access Control System+**
* It can run on a variety of Cisco gear, such as switches, routers and ASA firewalls.
* Developed by Cisco, but is now an open standard.
* Not every vendor uses it despite it being open standard. Still popular in _all-Cisco_ networks.
* Sends Layer 4 segments using TCP.
* Authentication, Authorization and Accounting all run as separate processes.
* **Two-way** challenge and response make it a bit more secure than RADIUS.
* TACACS+ encrypts the entire packet.

Some of the features of RADIUS are:
* RADIUS is now an industry-standard, supported by most vendors.
* Popular in a mixed vendor environment.
* Sends Layer 4 segments using UDP.
* Authentication, Authorization and Accounting are all combined in the same process.
* One way authentication where only the client authenticates with the server.
* It encrypts only the password.
* Better at Accounting functions than TACACS+

## RADIUS/TACACS+ Network Access Server (Client) Setup
 Here we want to configure a switch to authenticate with a RADIUS server, and if that server isn't available, we want to failover to a local username database. We'll be configuring this on a Cisco Catalyst switch.

To enable AAA, we first give the command `aaa new-model` in the global configuration mode. Now, to enable a RADIUS server, we use the command `radius-server <IPaddress>` or for a TACACS+ server, it becomes `tacacs-server <IPaddress>`:
```
sw1#conf t
sw1(config)#radius-server 10.10.10.10
sw1(config)#tacacs-server 20.20.20.20
```

In case of larger networks such as enterprise networks, we might have to define a group of RADIUS/TACACS+ servers using:
```
sw1(config)#aaa group server radius R-GROUP
sw1(config-sg-radius)#server 10.10.10.10
```

## Failover
When the RADIUS/TACACS+ server isn't available for authentication, we can still failover to local authentication. For this, we must first have a local username and password:
```
sw1(config)#username somu secret cisco
```

Now when we authenticate

## Using RADIUS for Authentication
Now to actually setup RADIUS for the authentication, we use:
```
sw1(config)#aaa authentication login default group R-GROUP local
```
The list provided is the **method list** which is a list of authentication procedures. Here, the list begins from the word _default_ which asks the switch to use the default method list for authentication. Finally, if the RADIUS authentication server is not available, i.e., `10.10.10.10` doesn't respond appropriately or just doesn't respond at all, we'll be falling back to local login database, which is why we use the `local` keyword at the end.

If the auth server isn't available during login, the switch will try to get the response from the server for several seconds, and when it can't, it'll finally use the local database and let us log in if our credentials are also stored locally.

# Access Control Lists (_ACL_)
Let us consider the topology below, where both PC-A and PC-B are connected to a network which leads to a server. We only want PC-A to have access to the server, but not PC-B. This is something we can achieve with **Access Control Lists (_ACL_)**. An ACL contains a bunch of entries, each of which state that a certain type of traffic will be allowed/permitted or denied. So, at the router, we could apply an ACL that allows PC-A's IP to come in to the router but not PC-B's IP. An ACL can be applied either in the inbound or outbound direction, and they're processed in a **top-down** manner.

Thus, thus, if we have an entry barring any traffic from PC-A and PC-B's network, but later down the list, we have another rule that only allows PC-A, we'll still not be able to access the server from PC-A because a rule above has already blocked access. As such, we _must have more specific rules at the top_. So, in this case, we'd first have a rule to permit PC-A's IP and then a rule further down the list that denies all traffic from PC-A's subnet that PC-B also lives in. There is also an **implicit deny any** statement at the bottom of _every ACL_. This does the job of blocking all traffic, which means even though we don't have to _explicitly_ state it, any traffic that's not accounted for in the ACL gets denied. So, if we have an ACL stating _block PC-B_, it'll block everything since the list will also have an implicit _deny any_ clause, and we haven't explicitly permitted anything!

We can have two types of ACLs:
- **Standard ACL** - In standard ACLs, we can _filter_ the traffic only on the basis of source IP addresses.
- **Extended ACL** - In extended ACLs, we can permit/deny traffic based on both source and destination IP addresses.

# Standard ACL
In a standard Access Control List, we are able to permit/deny traffic on the basis of the source IP only. This may be a single host or an entire subnet, specified with a **wildcard mask**. In the topology below, we want PC-A to have access to both server A and B, but block PC-B from accessing either. Thus, we can create an ACL at the router to allow traffic from PC-A and with the implicit deny at the end, the rest will be achieved automatically. Each ACL has a number associated with it and standard ACLs must have a number between *1 and 99*.  Access control lists are defined with the `access-list` command in global configuration mode. To only allow PC-A to access both servers, we use:
```
Router(config)#access-list 1 permit host 10.1.1.101
```
The implicit deny any statement, at the bottom of our list, that we _don't have to type_ would be: `access-list 1 deny any`.

Now that we have the list ready, we need to apply it to an interface in either an inbound or outbound direction. In this case, we want to apply it to the interface **R1 Gi0/0**. So, we use the `ip access-group` command with the list number and the direction:
```
R1(config)#int g0/0
R1(config-if)#ip access-group 1 in
```
This applies our ACL. So, now we're able to ping Server A and B from PC-A but not PC-B:
```
PC-A> ping 192.168.1.2 -c 3
192.168.1.2 icmp_seq=1 timeout
192.168.1.2 icmp_seq=2 timeout
84 bytes from 192.168.1.2 icmp_seq=3 ttl=63 time=4.346 ms
84 bytes from 192.168.1.2 icmp_seq=4 ttl=63 time=6.300 ms
84 bytes from 192.168.1.2 icmp_seq=5 ttl=63 time=3.768 ms

PC-A> ping 192.168.1.3       
192.168.1.3 icmp_seq=1 timeout
192.168.1.3 icmp_seq=2 timeout
84 bytes from 192.168.1.3 icmp_seq=3 ttl=63 time=3.880 ms
84 bytes from 192.168.1.3 icmp_seq=4 ttl=63 time=2.760 ms
84 bytes from 192.168.1.3 icmp_seq=5 ttl=63 time=4.729 ms

PC-B> ping 192.168.1.2 -c 3
*10.1.1.1 icmp_seq=1 ttl=255 time=3.945 ms (ICMP type:3, code:13, Communication administratively prohibited)
*10.1.1.1 icmp_seq=2 ttl=255 time=3.284 ms (ICMP type:3, code:13, Communication administratively prohibited)
*10.1.1.1 icmp_seq=3 ttl=255 time=3.842 ms (ICMP type:3, code:13, Communication administratively prohibited)

PC-B> ping 192.168.1.3 -c 3
*10.1.1.1 icmp_seq=1 ttl=255 time=3.865 ms (ICMP type:3, code:13, Communication administratively prohibited)
*10.1.1.1 icmp_seq=2 ttl=255 time=3.855 ms (ICMP type:3, code:13, Communication administratively prohibited)
*10.1.1.1 icmp_seq=3 ttl=255 time=3.857 ms (ICMP type:3, code:13, Communication administratively prohibited)
```

There are actually extended number ranges for ACLs, and there can be several types of lists, even based on MAC addresses! They're listed below:
```
R1(config)#access-list ?
  <1-99>            IP standard access list
  <100-199>         IP extended access list
  <1100-1199>       Extended 48-bit MAC address access list
  <1300-1999>       IP standard access list (expanded range)
  <200-299>         Protocol type-code access list
  <2000-2699>       IP extended access list (expanded range)
  <2700-2799>       MPLS access list
  <300-399>         DECnet access list
  <700-799>         48-bit MAC address access list
  compiled          Enable IP access-list compilation
  dynamic-extended  Extend the dynamic ACL absolute timer
  rate-limit        Simple rate-limit specific access list
```

We can see/verify the current ACLs using the `show access-lists` command:
```
R1#sh access-li  
Standard IP access list 1
    10 permit 10.1.1.101 (13 matches)
```

# Numbered Extended ACLs
