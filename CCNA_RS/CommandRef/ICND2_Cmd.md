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
