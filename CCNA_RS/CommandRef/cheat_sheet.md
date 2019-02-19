# Cheat Sheet
## Protocols
### Routing protocols
```
Proto			AD		Multicast IP			Metric					Cost Ref			Hello 		Dead	Algo
=============	=====	====================	===================		==================	========	=======	============
RIP				120		224.0.0.9	FF02::9		Hops (0-15; 16=inf)		# of Hops			---			---		Bellman-Ford
OSPF			110		224.0.0.5/6	FF02::2		B/W						100Mbps/Int speed.	10/30s		40/120s	Dijkstra SPF
EIGRP			90		224.0.0.10	FF02::A		256*(K1*BWm + K3*del)	10^7/BWm			5/60s		15/180s	DUAL
```

### Non-Routing protocols
```
Proto			Multicast IP			Port		Hello 		Dead
=============	====================	=========	========	=======
HSRP			224.0.0.2	---			1985 (UDP)	3s
HSRPv2			224.0.0.102	FF02::66	2029 (UDP)	3s
STP				
```

## Timers
### RIP
Update 			= 30s
Flush - x4 		= 240s
Holddown - x6	= 180s

**_Holddown timers_** can be used to avoid the formation of loops. Holddown timer immediately starts when the router is informed that attached link is down. Till this time, router ignores all updates of down route unless it receives an update from the router of that downed link. During the timer, If the down link is reachable again, routing table can be updated.

### OSPF
```
Timer				Broadcast	NBMA	P2P		MultiP2P
======				=========	======	======	========
Hello				10s			30s		10s		40s
Dead x4				40s			120s	30s		120s
--------------------------------------------------------
DR/BDR				Yes			Yes		No		No
Static Neighbour	No			Yes		No		No
```

### EIGRP
```
Timer		Ethernet/LAN	Frame-Relay
======		============	===========
Hello		5s				60s
Hold x3		15s				180s
```
* Timers don't have to match between neighbours in EIGRP.
* Hold time states how long the neighbour should wait before declaring this router as *dead*.


## RIP
**Split Horizon** - A rule that states a router may not advertise a route back to the neighbor from which it was learned
**Route Poisoning** - When a network becomes unreachable, an update with an infinite metric (16) is generated to explicitly advertise the route as unreachable.
**Poison Reverse** - A router advertises a network as unreachable through the interface on which it was learned.

**Config**
```
! Enable RIPv2 IPv4 routing
router rip
    version 2
    ! Disable RIPv2 automatic summarization
    no auto-summary
    ! Designate RIPv2 interfaces by network
    network <network>
    ! Identify unicast-only neighbors
    neighbor <IP-address>
    ! Designate passive interfaces
    passive-interface {interface| default}

show ip[v6] protocols
show ip[v6] rip database
show ip[v6] route rip
debug ip rip { database | events }
debug ipv6 rip [interface]
```

## OSPF
Multicast IP `224.0.0.5` is used to reach all routers by OSPF while `224.0.0.6` can reach all DR/BDRs.

**Adjacency states**
* Down
* Init - Sends hello msg
* 2 way - received hello msg from router with itself marked as neighbour, replies with a hello message with the source router as neighbour.
* Ex-start - Holds DR/BDR election for non-point-to-point and non-multipoint broadcast networks and NBMA.
* Exchange - Holds primary/secondary election and they exchange LSAs within DD packets. Routers check if they have all the LSAs that their neighbour has.
* Loading -	Routers that are missing an LSA send LSRs to neighbour, which reply with LSUs. Routers update their LSDs.
* Full - Adjacency formation complete.

**DR/BDR Election**
* DR/BDR selected upon priority and router id.
* Priority = 0 to 255, 1 = default; 0 = not participating
* Router ID = highest loopback ip addr; failing it, highest normal IP addr.

**Network Type**
Ethernet = Broadcast
Frame-Relay sub-interfaces = P2P
FR Physical interfaces/ML Sub-interface = NBMA

### OSPF Config
```
R2(config)#router ospf 1
R2(config-router)#network 2.2.2.2 0.0.0.0 area 1
R2(config-router)#network 192.168.0.0 0.0.0.3 area 0
R2(config-router)#network 192.168.0.4 0.0.0.3 area 0  
```
Show which dynamic routing protocol is being used   `R2#sh ip proto`
Show all routes in the IP routing table             `R2#sh ip route`

Show interfaces participating in OSPF               `R2#sh ip ospf int br`
Show OSPF neighbours                                `R2#show ip ospf neighbor`
View OSPF's Link State Database                     `R2#sh ip ospf database`
Show OSPF interface details for interface           `R1#sh ip ospf int g0/1`
Show OSPF network type/timers						`R1#sh ip ospf int`

Include an interface in OSPF directly               `R2(config-if)#ip ospf 1 area 1`
Change OSPF reference bandwidths (Mbps; def=100)    `R2(config-router)#auto-cost reference-bandwidth 100000`
Change OSPF interface cost                          `R2(config-if)#ip ospf cost 100`
Change OSPF network type for interface              `R2(config-if)#ip ospf network non-broadcast`

### OSPFv3 Config
```
R1(config)#ipv6 router ospf 1
R1(config-rtr)#router-id 1.1.1.1
R1(config)#int e0/0
R1(config-if)#ipv6 ospf 1 area 0
R1(config-if)#int e0/1
R1(config-if)#ipv6 ospf 1 area 0

R1#sh ipv6 int br
R1#sh ipv6 route
R2#sh ipv6 ospf nei
R2#sh ipv6 ospf int
R2#sh ipv6 proto
R2#sh ipv6 cef

```

## EIGRP
Criteria for Metric calculation
* Min Bandwidth (default)
* Load
* Interface Delay (default)
* Reliability
* MTU (*tie-breaker*)
```
Metric = [(K1 * BWm + (K2 * BWm/(256 - Load) + K3 * Delay) + K5/(K4 + Reliability)] * 256
where, bw= 10^7/ minimum path bandwidth in kbps,
delay= interface delay in μsecs / 10
default K1 = 1, K2 = 0, K3 = 1, K4 = 0, K5 = 0

Metric (Reduced/Default) = [(10,000,000/Min Bandwidth) + (Sum of interface delays/10)] * 256
```
*K-Values need to match at either end of the link for neighbourship to be maintained*.

**Reported Distance** - The metric for a route advertised by a neighbor
**Feasible Distance** - The distance advertised by a neighbor plus the cost to get to that neighbor
_External EIGRP AD = 170 ; Summary EIGRP AD = 5_

**Successor Route** - Current best route known to EIGRP
**Feasible Successor Route** - A route that meets the feasibility condition.
**Feasibility condition** - The RD of the FSR must be less than the FD of the current successor route (SR).
Load balancing can be done between only successor and (one or more) feasible successor routes via _variance_.

### EIGRP Config
```
R1(config)#router eigrp 1
R1(config-router)#network 192.168.1.1 0.0.0.255
R1(config-router)#network 192.168.2.0 0.0.0.255
```
Show all EIGRP interfaces				`sh ip eigrp interfaces`
Show all EIGRP neighbours				`sh ip eigrp neighbors`
Show EIGRP routes						`sh ip eigrp topology`
Show all routes EIGRP knows about		`sh ip eigrp topology all-links`	This also shows (FD/RD).
Show EIGRP timers for an interface		`sh ip eigrp int detail`

Change max paths for load balancing		`R1(config-router)#maximum-paths 32`
Load balancing (Variance) formula:
```
Max FSR for load-balancing route: FD(FSR) <= variance * FD(SR)
Thus, Variance (int value) = ceil(FD(max FSR for load-balancing)/FD(SR))
```
Setting vaiance							`R1(config-router)#variance 2`

### EIGRP IPv6 Config
* next hop is link-local address
* Uses IPv6 auth
* no auto-summarization
* neighbours don't need to be on same subnet
* Multicast addr of `FF02::A`
* Manually add interfaces with `ipv6 eigrp <ASN>`
```
R1(config)#ipv6 unicast-routing
R1(config)#ipv6 cef
R1(config)#ipv6 router eigrp 1
R1(config-rtr)#int e0/0
R1(config-if)#ipv6 eigrp 1
R1(config-if)#int s1/0
R1(config-if)#ipv6 eigrp 1
R1(config-rtr)#eigrp router-id 4.4.4.4

sh ipv6 proto
sh ipv6 route eigrp
sh ipv6 eigrp int
sh ipv6 eigrp int detail	! Shows hello and hold timers
sh ipv6 eigrp neighbor
sh ipv6 eigrp topo
sh ipv6 eigrp topo all
```

### AD Values
```
    Route Source 			Default Distance Values
    =====================	=======================
*	Connected interface 	0
*	Static route 			1
    EIGRP summary route 	5
*	External BGP 			20
*	Internal EIGRP 			90
    IGRP 					100
*	OSPF 					110
    IS-IS 					115
*	RIP					 	120
    EGP 					140
    On Demand Routing (ODR) 160
*	External EIGRP 			170
*	Internal BGP 			200
*	Unknown* 				255	! Router discards these routes
```

## HSRP
HSRP uses virtual MAC address 0000.0C07.ACxy, where xy is the HSRP group number in hexadecimal based on the respective interface.
HSPRv2 uses virtual MAC addr  0005.73A0.0000 through 0005.73A0.0FFF.

**HSRP States**
* **Init** - The state of an HSRP interface after coming back up or after an interface configuration change.
* **Listen** - The interface now knows the _virtual IP address_ and is listening for hello messages.
* **Speak** - The interface now sends out hello messages to participate in the **Active/Standby router election**.
* **Standby** - The router on which the interface is located is now acting as the backup/standby router after losing the election, but is next in line to become the active router if the incumbent active router fails. It still sends out hello messages.
* **Active** - The HSRP state of an interface that's actively forwarding packets for the Virtual IP and MAC addresses. This too has to send out hello messages to let the backup router know it's still alive and hence ask it to stay on _stand-by_.

### HSRP Config
```
sw2(config)#int e0/0
sw2(config-if)#standby 10 ip 10.1.1.1
sw2(config-if)#standby 10 priority 110
sw2(config-if)#standby 10 preempt

sw3(config)#int e0/0
sw3(config-if)#standby 10 ip 10.1.1.1
sw3(config-if)#standby 10 preempt

sw3#sh standby brief
sw3#sh standby 										! 	More detailed info
sw3#sh standby g0/0

sw2(config-if)#standby ver 2						!	Switching to HSRPv2
sw2(config-if)#standby 10 timers ms 200 ms 900		!	HSRPv2 Hello interval and hold time
sw3(config-if)#standby ver 2
sw3(config-if)#standby 10 time ms 200 ms 900

! Interface Tracking
sw2(config)#track 1 int Gi 0/1 ip routing
OR
sw2(config-track)#int g0/0
sw2(config-if)#standby 10 track 1 dec 20
```

### GLBP Config
```
sw2(config)#int g0/0
sw2(config-if)#glbp 10 ip 10.1.1.1
sw2(config-if)#glbp 10 priority 110
sw2(config-if)#glbp 10 weighting 5
sw2(config-if)#glbp 10 load-balancing weighted
sw2(config-if)#glbp 10 authentication md5 key-string cisco123
```

* Virtual MAC addresses are assigned by the **Active Virtual Gateway (_AVG_)**.
* Virtual MAC address is in the format : `0007.B40X.xxyy`, Xxx is the 10-bit wide GLBP group number (hence only the 2 LSBs from X are used for the group number), and yy is a different number for each router (01, 02, 03, or 04).
* There can be 1024 GLBP groups per interface and 4 AVFs per group.

## Access Control Lists (_ACL_)
We can have two types of ACLs:
- **Standard ACL** - In standard ACLs, we can _filter_ the traffic only on the basis of source IP addresses.
- **Extended ACL** - In extended ACLs, we can permit/deny traffic based on both source and destination IP addresses. Extended ACLs can have a number in the range _100-199_, and can of course have both a source and a destination IP address. They also have the ability to specify the protocols in the ACL itself.

### Standard ACL
```
R1(config)#access-list 1 permit host 10.1.1.101
R1(config)#int g0/0
R1(config-if)#ip access-group 1 in
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

### Numbered Extended ACLs
```
R1(config)#access-list 100 permit ip host 10.1.1.101 host 192.168.1.2			! Allow any IP traffic
R1(config)#access-list 100 permit tcp host 10.1.1.102 host 192.168.1.3 eq 80	! Allow any web-server traffic
R1(config)#int e0/0
R1(config-if)#ip access-group 100 in
```

**Verification**
```
R1#sh access-l
Extended IP access list 100
    10 permit ip host 10.1.1.101 host 192.168.1.2
    20 permit tcp host 10.1.1.102 host 192.168.1.3 eq www
R1#sh ip int e0/0 | i access list
  Outgoing access list is not set
  Inbound  access list is 100
```

### Named Extended ACLs
```
R1(config)#ip access-list extended ACC_CONT
R1(config-ext-nacl)#permit ip host 10.1.1.101 host 192.168.1.2
R1(config-ext-nacl)#permit tcp host 10.1.1.102 host 192.168.1.3 eq www
R1(config)#int e0/0
R1(config-if)#ip access-group ACC_CONT in
R1#sh ip access-lists
Extended IP access list ACC_CONT
    10 permit ip host 10.1.1.101 host 192.168.1.2
    20 permit tcp host 10.1.1.102 host 192.168.1.3 eq www
R1#sh int e0/0 | i access
R1#sh ip int e0/0 | i access list
  Outgoing access list is not set
  Inbound  access list is ACC_CONT
```

### Changing existing ACLs
```
R1(config)#ip access-list extended ACC_CONT
R1(config-ext-nacl)#15 deny ip any any
```

# ACL Considerations
The following are some of the design considerations for Access Control Lists:
* Direction an ACL will be applied in - inbound and/or outbound. The rule is that we can only have 1 ACL in each direction in each interface. So, there can be a maximum of two ACLs per interface - one in the inbound and another in the outbound direction.
* More specific Access Control Entries (ACE) towards the top of the list.
* We also have to remember that there's an _implicit deny any_ statement at the bottom of the ACL
* Standard ACL: near destination - because it just matches the source and we want to ensure that the ACL doesn't inadvertently drop packets for a destination network it's supposed to be able to access.
* Extended ACLs: near source - because if the traffic is going to be dropped, it's better to do so early and not waste network resources carrying that data.

### Extended IPv6 ACL Config
```
R1(config)#ipv6 access-list TELNET_PC-B_R2
R1(config-ipv6-acl)#permit tcp host 2002::3 host 2002::2 eq telnet

! Allowing advertisements and solicitation since IPv6 doesn't have broadcast.
R1(config-ipv6-acl)#permit icmp any any router-advertisement  
R1(config-ipv6-acl)#permit icmp any any router-solicitation

R1(config-ipv6-acl)#int e0/1
R1(config-if)#ipv6 traffic-filter TELNET_PC-B_R2 out
```

### NAT
#### Static NAT
First we define which interface is _inside_ the network and which is _outside_ our network. In this case,
**R1 Gi0/1** = LAN port ; host IP `10.1.1.100`
**R1 Gi0/0** = WAN port ; WAN IP `4.4.4.4`, provided by the ISP.
Steps for Static NAT:
* Configure the inside and outside NAT interfaces
* Map `10.1.1.100` to  `4.4.4.2`:
```
R1(config)#int g0/1
R1(config-if)#ip nat inside
R1(config-if)#int g0/0
R1(config-if)#ip nat outside
R1(config-if)#exit
R1(config)#ip nat inside source static 10.1.1.100 4.4.4.2
```

Show NAT Table and translations						`R1#sh ip nat translations`

#### Dynamic NAT with IP pool
Steps for DNAT are:
* Define insidce and outside interfaces
* Define IP pool (here with IP `4.4.4.2` and `4.4.4.3`)
* Define ACL to match inside hosts (here `10.1.1.0/8`)
* Map inside local hosts (ACL) to inside global IP pool
```
R1(config)#int g0/1
R1(config-if)#ip nat inside
R1(config-if)#int g0/0
R1(config-if)#ip nat outside
R1(config)#ip nat pool DNAT_POOL 4.4.4.2 4.4.4.3 netmask 255.255.255.0
R1(config)#access-list 1 permit 10.1.1.0 0.0.0.255
R1(config)#ip nat inside source list 1 pool DNAT_POOL
```

#### Port Address Translation (PAT)/NAT Overloading
Same as DNAT, but requires the `overload` command to allow PAT
```
R1(config)#int g0/1
R1(config-if)#ip nat inside
R1(config-if)#int g0/0
R1(config-if)#ip nat outside
R1(config)#access-list 1 permit 10.1.1.0 0.0.0.255
R1(config)#ip nat inside source list 1 int g0/0 overload
```

### VTP
70. Set VTP mode to server       `sw1(config)#vtp mode server`
71. Set VTP mode to client       `sw1(config)#vtp mode client`
72. Set VTP domain name          `sw1(config)#vtp domain VTPDEMO`
73. Set VTP password             `sw1(config)#vtp password S3cret`
74. Check VTP Status             `sw1#sh vtp status`
75. Reset VTP CRN            
```
sw1(config)#vtp mode transparent
sw1(config)#vtp mode server
```

### STP
#### Timers
For STP:
Hello - 2s
Max age = 20s
Forward delay = 15s

For RSTP:
Hello = 2s
Max age = 6s

####Port States
```
Legacy ST	Rapid ST
=========	==========
Disabled	Discarding
Blocking
Listening 	
Learning	Learning
Forwarding	Forwarding
```

#### Port Roles
```
Legacy ST	Rapid ST
=========	==========
Root port	Root port
Designated	Designated
Blocking	Alternate
    Backup
```

#### PVST+
Show existing spanning trees on a VLAN          `sw1#sh spanning-tree vlan 100`
Show detailed spanning tree info on a VLAN      `w1#sh span vlan 100 detail`
Change bridge priority                          `sw1(config)#spanning-tree vlan 100 priority 41060`
Changing STP bridge parameters
```
sw1(config)#spanning-tree vlan 100 ?
  forward-time  Set the forward delay for the spanning tree
  hello-time    Set the hello interval for the spanning tree
  max-age       Set the max age interval for the spanning tree
  priority      Set the bridge priority for the spanning tree
  root          Configure switch as root
```
Change port priority                            `sw2(config-if)#spanning-tree port-priority 192`
Change port cost                                `sw3(config-if)#spanning-tree cost 3`

Setting switch as primary root bridge           `sw1(config)#spanning-tree vlan 100 root primary`
Setting switch as secondary root bridge         `sw1(config)#spanning-tree vlan 200 root secondary`

#### RPVST+
See if switch is using PVST+ or RPVST+          `sw1#sh spanning-tree summary`
Switch to RPVST+                                `sw1(config)#span mode rapid-pvst`
Chaning link type of an interface               
```
sw1(config-if)#span link-type ?
  point-to-point  Consider the interface as point-to-point
  shared          Consider the interface as shared
```
Changing interface to an edge port              `sw1(config-if)#span portfast`
Enable port fast globally                       `sw4(config)#spanning-tree portfast default`
See if portfast is active on an interface       `sw1#sh spanning-tree int g0/2 portfast`
Enable BPDUGuard on an interface                `sw1(config-if)#spanning-tree bpduguard enable`
Turn on BPDUGuard on all edge ports             `sw1(config)#spanning-tree portfast edge bpduguard default`

### EtherChannel
#### L2 EtherChannel
Steps to form an L2 EtherChannel:
* Ensure all participating ports have the same speed, duplex and VLAN assignments
* Ensure either a cross-over cable is used for the two connecting switches OR MDI-X is turned on (requires auto-speed and duplex)
```
sw2(config)#int ran g0/1-2
sw2(config-if-range)#speed auto
sw2(config-if-range)#duplex auto
sw2(config-if-range)#mdix auto
sw2(config-if-range)#channel-group 1 mode desirable
```

Set EtherChannel Protocol (PAgP or LACP):
```
sw2(config-if-range)#channel-group 1 mode ?
  active     Enable LACP unconditionally
  auto       Enable PAgP only if a PAgP device is detected
  desirable  Enable PAgP unconditionally
  on         Enable Etherchannel only
  passive    Enable LACP only if a LACP device is detected
```

Convert Port-Channel/EtherChannel to dot1q trunk:
```
sw2(config)#int po1
sw2(config-if)#switchport trunk encap dot1q
sw2(config-if)#sw mode trunk
```

Show Port-Channel details               `sw2#sh int po1`

#### L3 EtherChannel
Steps for L3 EtherChannel creation:
* Create an L2 EtherChannel/port-channel
* Turn both the individual ports as well as the port channel to a **routed port**
* Assign IP and other L3 config
* Bring up the individual interfaces as well as the port channel
```
sw2(config)#int ran g0/1-2
sw2(config-if-range)#neg auto
sw2(config-if-range)#no switchport
sw2(config-if-range)#channel-group 1 mode on
sw2(config-if-range)#no shut
sw2(config-if-range)#int po1
sw2(config-if)#no switchport
sw2(config-if)#ip addr 10.1.1.1 255.255.255.252
```

Show port-channels                              `sw2#sh etherchannel summary`
Show port-channel details                       `sw2#sh etherchannel port-channel`
Turn on EtherChannel Misconfig Guard            `sw2(config)#sp eth guard misconf`

Show EtherChannel load-balancing algorithm      `sw2#sh etherchannel load`
Set EtherChannel load-balancing algorithm
```
sw2(config)#port-channel load-balance ?
  dst-ip       Dst IP Addr
  dst-mac      Dst Mac Addr
  src-dst-ip   Src XOR Dst IP Addr
  src-dst-mac  Src XOR Dst Mac Addr
  src-ip       Src IP Addr
  src-mac      Src Mac Addr
```

### PPP
Advantages of PPP:
* Authentication with PAP/CHAP
* Data Compression
* Error Checking and Correction
* Combining multiple physical interfaces into a single logical interface called a _multilink interface_.

Subprotocols for PPP:
Some of the important protocols that work in conjunction with each other and PPP to provide the functionality of PPP are:
* **Link Control Protocol (_LCP_)** - TUsed by PPP to setup, destroy or maintain the connections.
* **Network Control Protocols (_NCPs_)** - There are several different NCPs, one for each protocol used, that negotiates the configuration of that protocol. PPP can support multiple Layer 3 and 2 protocols, and each of the protocols that are encapsulated by PPP is given their own NCP to control that protocol. For ex, IPCP for IP, CDPCP for CDP.

#### PPP Auth - Password Authentication Protocol (_PAP_)
* **One way auth** - only client authenticates to server.
* **Less secure** - clear-text sent across network
```
R1(config)#int s1/0
R1(config-if)#encap ppp
R1(config)#exit
R1(config)#username papuser password pappass
R1(config)#int s1/0
R1(config-if)#ppp authentication pap

R2(config)#int s1/0
R2(config-if)#encap ppp
R2(config-if)#ppp pap sent-username papuser password pappass
```

#### PPP Auth - Challenge Handshake Authentication Protocol (_CHAP_)
* **Two way auth** - both server and client authenticate to each other.
* **More secure** - has of the password is sent on the network.
* Username is for the other router; password on both routers is same. 
```
R1(config-if)#int s1/1
R1(config-if)#encap ppp
R1(config-if)#exit
R1(config)#username R2 password chappass
R1(config)#int s1/1
R1(config-if)#ppp authentication chap

R2(config-if)#int s1/1
R2(config-if)#encap ppp
R2(config-if)#exit
R2(config)#username R1 password chappass
R2(config)#int s1/1
R2(config-if)#ppp authentication chap
```
