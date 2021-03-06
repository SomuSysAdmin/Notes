<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [CCNA Command Cheat Sheet](#ccna-command-cheat-sheet)
  - [General Device Config](#general-device-config)
  - [L2 Swtich specific](#l2-swtich-specific)
    - [VLANs](#vlans)
    - [Trunking](#trunking)
    - [Troubleshooting](#troubleshooting)
    - [Switch Security](#switch-security)
    - [Voice VLANs](#voice-vlans)
    - [VTP](#vtp)
    - [STP](#stp)
      - [PVST+](#pvst)
      - [RPVST+](#rpvst)
    - [EtherChannel](#etherchannel)
      - [L2 EtherChannel](#l2-etherchannel)
      - [L3 EtherChannel](#l3-etherchannel)
  - [Router/L3 Switch Specific](#routerl3-switch-specific)
    - [Routing Fundamentals](#routing-fundamentals)
      - [IPv4 Static Routing](#ipv4-static-routing)
      - [IPv6 Static Routing](#ipv6-static-routing)
    - [CEF, ARP and Passive Interfaces](#cef-arp-and-passive-interfaces)
    - [RIPv2](#ripv2)
    - [DHCP](#dhcp)
    - [NAT](#nat)
      - [Static NAT](#static-nat)
      - [Dynamic NAT with IP pool](#dynamic-nat-with-ip-pool)
      - [Port Address Translation (PAT)/NAT Overloading](#port-address-translation-patnat-overloading)
  - [Services and troubleshooting](#services-and-troubleshooting)
    - [NTP](#ntp)
      - [NTP Server Config](#ntp-server-config)
      - [NTP Client configuration](#ntp-client-configuration)
    - [CDP](#cdp)
    - [LLDP](#lldp)
    - [Boot Options and File System](#boot-options-and-file-system)
      - [Password Reset](#password-reset)
      - [Troubleshooting and debugging](#troubleshooting-and-debugging)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# CCNA Command Cheat Sheet
## General Device Config
1. View how we're connected to the device           `sw1>show line`
2. Enter privileged mode                            `sw1>enable`
3. Exit privileged mode                             `sw1>disable`
4. Enter line configuration mode                    `sw1>conf t`
5. Exit current configuration mode                  `sw1>exit`
6. Exit all configuration mode                      `sw1>end`
7. Enter interface config mode
```
sw1#conf t
sw1(config)#int g0/0
```
8. Setting line password for console
```
sw1(config-line)#password cisco
sw1(config-line)#login
```
9. Setting line password for vty lines
```
sw1(config)#line vty 0 5
sw1(config-line)#password cisco
sw1(config-line)#login
```
10. Show running configuration                  `sw1>sh run`
11. Ping an IP                                  `sw1>ping 192.168.0.1`
12. See which input transports are allowed      `sw1>sh line vty 0`
13. Allow telnet and SSH as transport
```
sw1(config)#line vty 0 6
sw1(config-line)#transport input telnet ssh
```
14. Login via telnet                            `sw1>telnet 192.168.1.11`
15. Show history buffer                         `sw1>sh history`
16. Change history buffer size
```
sw1(config)#line vty 0 6
sw1(config-line)#history size 50
```
17. See interface IP assignment and line status `sw1#sh ip int brief`
18. Enabling SSH access:
* Create SSH user, password and domain name.
* Generate key files
* Choose SSH version
* Use local user database
```
sw1(config)#username cisco password cisco
sw1(config)#ip domain-name somuvmnet.com
sw1(config)#crypto key generate rsa
sw1(config)#ip ssh version 2
sw1(config)#line vty 0 6
sw1(config-line)#transport input ssh
sw1(config-line)#login local
```

19. Login with SSH                              `sw2#ssh -l cisco 192.168.1.11`
20. Show device version                         `sw1>sh ver`
21. View running configuration                  `sw1>sh run`
22. View saved configuration                    `sw1>sh start`
23. Setting device hostname                     `sw(config)#hostname sw1`
24. Setting enable password                     `sw1(config)#enable password cisco`
25. Setting enable encrypted hash               `sw1(config)#enable secret somu`
26. Setting exec timeout                        `sw1(config-line)#exec-timeout 5 30`
27. Setting sync logging                        `sw1(config-line)#logg syn`
28. Setting terminal length                     `sw1(config-line)#len 36`
29. Encrypting passwords                        `sw1(config)#service password-encryption`
30. Creating user with privilege level          `sw1(config)#username somu privilege 15 password cisco`
31. Creating user with hash                     `sw1(config)#username somu privilege 15 algorithm-type scrypt secret cisco`
32. Removing user                               `sw1(config)#no username somu`
33. Creating banner
```
sw1(config)#banner login `
Enter TEXT message. End with the character '`'.
+-------------------------+
| sw1 :
[ Swtich 1 ] +------------>
| Authorized Access Only! +--------------->
+-------------------------+
`
```
34. Disabling Auto Negotiation					`sw1(config-if)#no negotiation auto`
35. Specifying speed                            `sw1(config-if)#speed 100`
36. Specifying duplex                           `sw1(config-if)#duplex full`
37. Save configuration							`sw1(config)#copy run start` OR `sw1(config)#wr`


## L2/L3 Swtich specific
38. Show CAM table                              `sw1#sh mac address-table`
39. Show CAM table aging info                   `sw1#show mac address-table aging-time`
40. Add static MAC address to sw                `sw1(config)#mac address-table static a820.6332.0087 vlan 1 interface gi 0/3`
41. Adding switch management IP
```
sw1(config-if)#ip add 192.168.1.11 255.255.255.0
sw1(config-if)#no shutdown
```
42. Adding switch default gateway               `sw1(config)#ip default-gateway 192.168.1.1`

### VLANs
43. Show existing VLANs							`sw1#sh vlans`
44. Creating a new VLAN
```
sw1(config)#vlan 100
sw1(config-vlan)#name ACCT
```
45. Deleting a VLAN								`sw1(config)#no vlan 100`
46. Assigning a port to a VLAN					
```
sw1(config)#int gi0/0
sw1(config-if)#switchport access vlan 100
```

### Trunking
47. Show existing trunks						`sw1# sh int trunk`
48. Setting trunk encapsulation					`sw1(config-if)#switchport trunk encapsulation dot1q`
49. Changing trunk's native VLAN				`sw1(config-if)#switchport trunk native vlan 100`
50. Changing trunk mode to on					`sw1(config-if)#switchport mode trunk`
51. Changing trunk mode to dynamic desirable	`sw1(config-if)#switchport mode dyn des`
52. VLAN Pruning/Allowing only certain VLANs on trunk
```
sw1(config-if)#sw tr allowed vlan 1,100
sw1(config-if)#sw tr allowed vlan except 300
```

### Troubleshooting
53. Clearing MAC table 							`sw1#clear arp-cache`
54. Show interface status/details				`sw1#sh int g0/0`

### Switch Security
55. Enabling port security
```
sw1(config-if)#sw mo access
sw1(config-if)#sw port-sec
```
56. Setting max MAC addrs allowed on a port		`sw1(config-if)#sw port-sec max 2`
57. Setting MAC addrs allowed on a port			`sw1(config-if)#sw port-sec mac-address 0001.0a1b.0010`
58. Sticky MAC addrs							`sw1(config-if)#sw port-sec mac-address sticky`
59. Port Security Violation
* Protect mode - Drop packets from restricted MAC addrs
* Restrict mode - Drop packets from restricted MAC addrs and increase **security violation counter**
* Shutdown mode - Shut down the port on encountering a packet from restricted MAC addrs
```
sw1(config-if)#sw port-sec violation ?
  protect 	Security violation protect mode
  restrict 	Security violation restrict mode
  shutdown 	Security violation shutdown mode
```
60. Find out if interface is shut down due to port-sec violation
```
sw1#sh int g0/1
GigabitEthernet0/1 is down, line protocol is down (err-disabled)
```
61. Port-sec violation recovery - fix issue and then bounce port
```
sw1(config-if)#shut
sw1(config-if)#no shut
```
62. Automatically bring port back up after port-sec violation
```
sw1(config)#errdisable recovery cause psecure-violation
sw1(config)#errdisable recovery interval 30
```
63. Show security violation counter (in restrict mode)		`sw1#sh port-sec`
64. Show MAC addrs allowed on a port						`sw1#sh port-sec addr`
65. Show port-sec details for an interface					`sw1#sh port-sec int g0/1`

### Voice VLANs
66. Setting single Access VLAN for both data and voice with .1p markings for QoS:
```
sw1(config-if)#switchport mode access
sw1(config-if)#switchport access vlan 300
sw1(config-if)#switchport voice vlan dot1p
```
67. Setting Multi-Access VLAN for CDP:
```
sw1(config-if)#switchport mode access
sw1(config-if)#switchport access vlan 300
sw1(config-if)#switchport voice vlan 400
```
68. Dot1q trunk for LLDP and CDP:
* Set port to trunk mode and data VLAN as native
* Designate voice VLAN
* Prune unnecessary VLANs
```
sw1(config-if)#switchport trunk encapsulation dot1q
sw1(config-if)#switchport mode trunk
sw1(config-if)#switchport trunk native vlan 300
sw1(config-if)#switchport voice vlan 400
sw1(config-if)#switchport trunk allowed vlan 300,400
```
69. Get switch port trunk and voice VLAN details:
```
sw1#sh int g0/1 switchport
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

### L3 Switch IP Routing
#### Router on a Stick
We have a switch configuration such as below, such that two devices on two VLANs are connected to the switch, and a trunk port leads to the router.
```
sw#sh int status

Port      Name               Status       Vlan       Duplex  Speed Type
Gi0/0                        connected    trunk      a-full   auto RJ45
Gi0/1                        connected    10         a-full   auto RJ45
Gi0/2                        connected    20         a-full   auto RJ45
Gi0/3                        connected    1          a-full   auto RJ45
```

We have to configure the Router's end of the trunk with logical sub-interfaces with each sub-interface belonging to a different VLAN:
```
R1(config)#int g0/0.1
R1(config-subif)#encapsulation dot1q 10
R1(config-subif)#ip addr 192.168.1.1 255.255.255.0
R1(config-subif)#int g0/0.2
R1(config-subif)#encap dot 20
R1(config-subif)#ip addr 172.16.1.1 255.255.255.0
R1(config-subif)#int g0/0
R1(config-if)#no shut
```

Show VLANs on a router/L3-Switch:           `R1#show vlans`

#### SVIs and routed ports
Steps to enable routing on L3 switches:
* Create an SVI for each subnet/VLAN
* Turn on `ip routing`
* Convert port leading to router to a routed port and assign an IP
```
sw1(config)#int vlan 10
sw1(config-if)#ip addr 192.168.1.1 255.255.255.0
sw1(config-if)#no shut
sw1(config-if)#int vlan 20
sw1(config-if)#ip addr 172.16.1.1 255.255.255.0
sw1(config-if)#no shut
sw1(config-if)#exit
sw1(config)#ip routing
```

## Router Specific
Assigning IPv4 Address to interface
```
r2(config)#int g0/3
r2(config-if)#ip addr 172.16.5.1 255.255.255.0
r2(config-if)#no shut
```
Viewing IP Address assignments	`r2#sh ip int br`
Assigning IPv6 Link-local Address to interface
```
r2(config)#ipv6 unicast-routing
r2(config)#int g0/3
r2(config-if)#ipv6 enable
```
Assigning IPv6 Global unicast address to interface
```
r2(config)#ipv6 unicast-routing
r2(config)#int g0/3
r2(config-if)#ipv6 address 2000::4/64
```
View IPv6 Address assignments	`r2#sh ipv6 int br`

### Routing Fundamentals
#### IPv4 Static Routing
Show existing routes			`R1#sh ip route`
Static routing with exit interface (Serial links ONLY!)
```
R1(config)#ip route 198.51.100.0 255.255.255.0 gi0/0
```
Static routing with next hop IP
```
R1(config)#ip route 203.0.113.0 255.255.255.0 10.0.0.6
```
Static host routing (/32 subnet mask) with permanent effect (doesn't get removed from routing table even if interface goes down)
```
R1(config)#ip route 203.0.113.100 255.255.255.255 10.0.0.2 permanent
```
Static default route/gateway of last resort configuration
```
BR1(config)#ip route 0.0.0.0 0.0.0.0 10.0.0.1
```
Floating static route (or backup route) configuration (AD=125>120, which is AD for RIPv2)
```
R1(config)#ip route 203.0.113.0 255.255.255.0 10.0.0.6 125
```

#### IPv6 Static Routing
Show existing routes			`R1#sh ipv6 route`
IPv6 Static routing with exit interface (Serial links ONLY!)
```
R1(config)#ipv6 route 2004::/64 g0/2 2002::2
```
IPv6 Static routing with next hop IP
```
R1(config)#ipv6 route 2005::/64 2003::2
```
IPv6 Routing with Link local interface
```
R1(config)#ipv6 route 2004::/64 g0/2 FE80::EC1:8FFF:FEC5:C701
```
IPv6 Static host routing (/128 subnet mask)
```
R1(config)#ipv6 route 2004::100/128 2002::2
```
IPv6 Static default route/gateway of last resort configuration
```
BR1(config)#ipv6 route ::/0 s1/0
```
Floating IPv6 Static route (or backup route) configuration (AD=125>120, which is AD for RIPv2)
```
R1(config)#ipv6 route 2006::/64 2002::2 125
```

### CEF, ARP and Passive Interfaces
Show L3 Forwarding Info Base (FIB)		`R1#sh ip cef`
Show L2 Adjacency table 				`R1#sh adjacency`
Show ARP cache							`R1#sh ip arp`
Define a passive interface				`R1(config-router)#passive-interface Gi0/0`
Define all interfaces as passive and then define exceptions
```
R1(config-router)#passive-interface default
R1(config-router)#no passive-interface Gi0/0
```

### RIPv2
Turn on RIPv2
```
R1(config)#router rip
R1(config-router)#version 2
R1(config-router)#network 172.16.0.0
R1(config-router)#network 192.168.1.0
```
Turn off RIPv2 Auto-summarization					`R2(config-router)#no auto-summary`
Trigger immediate update in RIPv2					`R2#clear ip route *`

### DHCP
Configure Router's interface to get IP via DHCP 	`R1(config-if)ip address dhcp`
Configure router as DHCP relay agent				`R1(config-if)ip helper-address 172.16.1.2`
DHCP configuration
```
R1(config)#ip dhcp excluded-addresses 10.1.1.1     10.1.1.100
R1(config)#ip dhcp excluded-addresses 10.1.1.200   10.1.1.254
R1(config)#ip dhcp pool PC
R1(config-dhcp)#network 10.1.1.0 255.255.255.0
R1(config-dhcp)#default-router 10.1.1.1
R1(config-dhcp)#dns-server 192.168.1.1
```

Show existing DHCP pools							`DHCP#sh ip dhcp pool`
Show existing DHCP leases							`DHCP#sh ip dhcp binding`

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

### OSPFv2
We have to start OPSF with a process ID and also every OSPF instance must have a backbone area (area 0):
```
R2(config)#router ospf 1
R2(config-router)#network 2.2.2.2 0.0.0.0 area 1
R2(config-router)#network 192.168.0.0 0.0.0.3 area 0
R2(config-router)#network 192.168.0.4 0.0.0.3 area 0  
```
Include an interface in OSPF directly               `R2(config-if)#ip ospf 1 area 1`
Show which dynamic routing protocol is being used   `R2#sh ip proto`
Show all routes in the IP routing table             `R2#sh ip route`
Show interfaces participating in OSPF               `R2#sh ip ospf int br`
Show OSPF neighbours                                `R2#show ip ospf neighbor`
View OSPF's Link State Database                     `R2#sh ip ospf database`
Show OSPF interface details for interface           `R1#sh ip ospf int g0/1`

Change OSPF reference bandwidths (Mbps; def=100)    `R2(config-router)#auto-cost reference-bandwidth 100000`
Change OSPF interface cost                          `R2(config-if)#ip ospf cost 100`
Change OSPF network type for interface              `R2(config-if)#ip ospf network ethernet`


## Services and troubleshooting
### NTP
#### NTP Server Config
Setting time manually on the router and using it as the NTP server:
```
NTP#clock set 10:02:00 15 Dec 2018
NTP(config)#clock timezone IST 5 30
NTP(config)#ntp master 5	! Stratum num - only needed for manual time configs
NTP(config)#int loopback 1
NTP(config-if)#ip addr 1.1.1.1 255.255.255.255
```

Configuring a local NTP master clock:
````
R1(config)#ntp server 1.1.1.1
R1(config)#clock timezone IST 5 30
R1(config)#int loopback 1
R1(config-if)#ip addr 2.2.2.2 255.255.255.255
````

#### NTP Client configuration
```
R1(config)#ntp server 1.1.1.1
R1(config)#clock timezone IST 5 30
```
Using a local server:
```
R2(config)#ntp server 2.2.2.2
R2(config)#clock timezone EST -5
R2(config)#clock summer-time EDT recurring
```

Show current date and time				`R2#show clock`
Show NTP servers configured				`R2#show ntp associations`
Show NTP Status							`R1#sh ntp status`

### CDP
CDP multicast advertisement address = 	`01-00-0c-cc-cc-cc`
Show CDP Neighbourship info				`sw2#sh cdp neighbors`
Show Detailed CDP info					`sw2#sh cdp neighbors detail`
Get CDP info about a single neighbour	`sw2#sh cdp entry sw3`
Show CDP settings on the device			`sw2#sh cdp`
Show CDP Interface details				`sw2#sh cdp int g0/1`
Change CDP Config/Timers				`sw2(config)#cdp ?`
Turning CDP off and on
```
sw2(config)#no cdp run
sw2(config)#cdp run
```
Turn off CDP on a single interface		`sw2(config-if)#no cdp enable`

### LLDP
Start LLDP                              `sw2(config)#lldp run`
Show LLDP details                       `sw2#sh lldp`
Stop transmitting LLDP on an interface, for either transmission or reception:
```
sw2(config-if)#no lldp transmit
sw2(config-if)#no lldp receive
```

Select which information should be sent/received via LLDP:
```
sw2(config)#lldp tlv-select ?
  4-wire-power-management  Cisco 4-wire Power via MDI TLV
  mac-phy-cfg              IEEE 802.3 MAC/Phy Configuration/status TLV
  management-address       Management Address TLV
  port-description         Port Description TLV
  port-vlan                Port VLAN ID TLV
  power-management         IEEE 802.3 DTE Power via MDI TLV
  system-capabilities      System Capabilities TLV
  system-description       System Description TLV
  system-name              System Name TLV
```

Show LLDP neighbours                    `sw2#sh lldp neighbors`
Show LLDP neighbour details             `sw2#sh lldp neighbors detail`

### Boot Options and File System
The config register can be set to boot the router in a specific mode, the LSB of which may be:
* 0x0                 Boot in ROM Monitor Mode
* 0x1                 Boot to first flash image
* 0x2 - 0xF           Boot to a specific flash image by getting config from NVRAM.

Boot in ROM monitor mode via config register    `R1(config)#config-register 0x2100`

Show entire file system                         `R1#show file systems`
Show the directories *recursively*              `R1#show flash:`
Show the immediate contents of Directory        `R1#dir nvram:`
Create new directory                            `R1#mkdir OUTPUT`
Change directory                                `R1#cd OUTPUT`
Show current directory                          `R1#pwd`
Delete directory                                `R1#rmdir OUTPUT`

Create file from output of a command            `R1#sh ip int br | redirect flash0:/OUTPUT/int_br`
Show file                                       `R1#more int_br`
Delete file                                     `R1#delete int_br`
Copy file                                       `R1#copy int_br outputFile`

Upgrading IOS:
```
R1#copy tftp: flash:
R1(config)#boot system flash:c3725-adventerprisek9-mz.124-15.T14.bin
R1(config)# no boot system flash:c3500-adventerprisek9-mz.122-3.T2.bin
```

#### Password Reset
The steps to reset the password are:
* Have physical access to the device to reboot it; connect to router via console
* Enter ROM monitor mode by entering the *break* sequence
* In ROM monitor mode enter the confreg command to set boot mode to **0x2142**. This will boot the router ignoring the startup config at next boot, thus bypassing the password.
* Reboot and enter privileged mode
* Overwrite running config with startup config
* Use `enable secret` to over-write the existing password
* Restore config register to `0x2102`
* Save running config to startup config and reboot

```
rommon 2 > confreg 0x2142
rommon 3 > reset

[reboot router]

Router>en
Router#copy start run
Router#conf t
Router(config)#enable secret cisco
Router(config)#config-register 0x2102
Router#copy run start
Router#reload
```

#### Troubleshooting and debugging
Ping an IP                                      `R1#ping 4.4.4.4`
Ping an IP a certain number of times            `R1#ping 4.4.4.4 repeat 99999`
Ping IP with repeat, packet size and timeout    `R1#ping 4.4.4.4 size 1500 timeout 0 repeat 99999`
Extended Ping                                   `R1#ping`
Trace route to a host                           `R1#traceroute 203.0.113.2`
Turn on terminal montitor                       `R1#terminal monitor`

Debugging a feature                             `R1#debug ip rip`
Turn off debugging                              `R1#u all`

Show CPU usage                                  `R3#show processes cpu`
Show RAM usage                                  `R3#show processes memory sorted`
