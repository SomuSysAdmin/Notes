<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

  - [Frame Relays](#frame-relays)
  - [Frame relay Configuration and Verification](#frame-relay-configuration-and-verification)
    - [Inverse ARP](#inverse-arp)
    - [Frame Relay Maps](#frame-relay-maps)
    - [Frame Relay Sub-Interfaces](#frame-relay-sub-interfaces)
    - [Frame Relay Point-to-Point Sub-Interfaces](#frame-relay-point-to-point-sub-interfaces)
- [Alpine Host Setup](#alpine-host-setup)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Frame Relays
Frame relay is a layer 2 WAN technology that's a service provided by _Frame relay service providers_. It sends layer 2 frames over a **Private Virtual Circuit (_PVC_)** that are marked with **Data Link Connection Identifiers (_DLCI_s)** numbers (pronounced *del-Cs*). In modern days, it's used less given the popularity of cable modems and DSL connections - but in the past, these used to be the _go-to_ WAN technology for small-businesses, because it could provide a connection to the internet or other branch offices at a reasonable price compared to erstwhile leased lines. It uses DLCIs to form multiple Permanent Virtual Circuits (PVCs).

A **Virtual Circuit (_VC_)** is a logical connection between two endpoints. Thus, there could be multiple VCs over a single physical circuit (leading to the frame-relay service provider) when frame relay is used. A virtual circuit can be brought up on demand, in which case they're called **Switched Virtual Circuits (_SVC_s)** or have them installed permanently, called **Permanent Virtual Circuits (_PVC_)** - the latter being the case for frame-relay clouds. A **Data Link Connection Identifier (_DLCI_)** is a _locally-significant_ connection identifier. These are the **layer 2 addresses in the world of Frame-relay**. For example, in the figure below, the DLCI for the PVC to R2, R1 has a DLCI number of _102_. This however, doesn't match the DLCI of 201 on R2, because DLCIs are only relevant on the router on which they're defined.

The connections may either be _point-to-point_ or _point-to-multipoint_ connections. In a point to point connection, all the PVCs belong in their own subnet, but in case of point-to-multipoint, they all share a subnet. A major disadvantage of a frame-relay connection over a leased line is that if we lease a T1, we get the entire bandwidth (1.5Mbps) of the T1 for ourselves. However, in a frame-relay, the bandwidth has to be shared among customers. As such, a frame-relay provider has to make **Service Level Agreements (_SLA_s)** with the customer, to ensure they get a certain bandwidth and they don't get _starved out_. The bandwidth promised/guaranteed by a service provider to be made available to a customer for a certain percentage of the time in the VC is called the **Committed Information Rate (_CIR_)**.

Typically, if a customer has a T1 line (1.5Mbps) connected to his network, with a CIR of only *512Kbps*, then he can set the speed of the interface to higher than the CIR. So, when there's no congestion, some of that data will pass. However, every packet in excess of the CIR will have the **Discard Eligibility (DE)** bit set in it's Frame relay header, which indicates to the service provider's network that this frame was sent consuming a bandwidth beyond what was promised in the CIR and hence the service provider may choose to discard it in case of congestion. This can be great for TCP packets in FTP, for instance, but for real-time applications like VoIP that use UDP, we would want to ensure as little packet loss as possible.

In case of congestion, the Frame-relay service provider's equipment can ask the link that's exceeding the CIR to slow down. For example, if R1 exceeds the CIR when sending traffic to R3, when a return packet from R3 is going to R1, the service provider can mark the **Backward Explicit Congestion Notification (_BECN_)** bit in the frame's header, which'll make the transmission speed on R1 to drop. However, if R1 is merely the server providing data for R3 to download, it's possible that there's no packet flow back to R1. In such cases, if the frame-relay cloud has **Forward Explicit Congestion Notification (_FECN_)** adaption enabled, it can mark one of the frames going to R3 with the FECN bit, which causes the receiver, R3 to send a frame (_without_ any meaningful data, called a _Q.922 test frame_) back to R1, on which the frame relay can mark the BECN bit.

## Frame relay Configuration and Verification
In the topology below, we have a hub-and-spoke topology where R1 is the hub and R2 and R3 are the nodes connected to R1 via individual PVCs. Once we have IP addresses assigned to the interfaces participating in frame relay, we need to change their encapsulation to turn off HDLC and instead use the frame-relay. We do this using the `encapsulation frame-relay` command in interface configuration mode for the interface connected to the frame relay switch/cloud. We also have to set the frame-relay **_LMI_ (Local Management Interface)** type. The LMI is an interface that performs signalling between a frame relay router and a switch. Our LMI type should match up with the LMI type of the provider.

```
R1(config-if)#encapsulation frame-relay
R1(config-if)#frame-relay lmi-type ?
  cisco
  ansi
  q933a

R1(config-if)#frame-relay lmi-type ansi
```

This has to be done on all the routers connected to the frame relay switch. Once done, we've completed a _basic_ frame-relay config on the routers, and we have to map the DLCIs on each link on the frame relay switch. Finally, we can see the PVCs known to our router by `show frame-relay pvc`:
```
R1#sh frame pvc

PVC Statistics for interface Serial2/0 (Frame Relay DTE)

              Active     Inactive      Deleted       Static
  Local          2            0            0            0
  Switched       0            0            0            0
  Unused         0            0            0            0

DLCI = 102, DLCI USAGE = LOCAL, PVC STATUS = ACTIVE, INTERFACE = Serial2/0

  input pkts 1             output pkts 1            in bytes 34        
  out bytes 34             dropped pkts 0           in pkts dropped 0         
  out pkts dropped 0                out bytes dropped 0         
  in FECN pkts 0           in BECN pkts 0           out FECN pkts 0         
  out BECN pkts 0          in DE pkts 0             out DE pkts 0         
  out bcast pkts 1         out bcast bytes 34        
  5 minute input rate 0 bits/sec, 0 packets/sec
  5 minute output rate 0 bits/sec, 0 packets/sec
  pvc create time 00:00:35, last time pvc status changed 00:00:35

DLCI = 103, DLCI USAGE = LOCAL, PVC STATUS = ACTIVE, INTERFACE = Serial2/0

  input pkts 1             output pkts 1            in bytes 34        
  out bytes 34             dropped pkts 0           in pkts dropped 0         
  out pkts dropped 0                out bytes dropped 0         
  in FECN pkts 0           in BECN pkts 0           out FECN pkts 0         
  out BECN pkts 0          in DE pkts 0             out DE pkts 0         
  out bcast pkts 1         out bcast bytes 34        
  5 minute input rate 0 bits/sec, 0 packets/sec
  5 minute output rate 0 bits/sec, 0 packets/sec
  pvc create time 00:00:35, last time pvc status changed 00:00:35
```
We see that the frame-relay knows about the DLCIs `102` and `103` configured for R1 on the frame-relay switch. We also see that both PVCs have a status of `ACTIVE` which indicates that the connection between both routers on either side of the frame relay cloud is okay, and also that we're exchanging LMI information between our router and the service provider's frame relay switch.

Some of the possible PVC statuses are:
```
PVC Status  Meaning
=========== ==============================================================================================================================================
Active      Connection is okay between our router and the far-end router
Inactive    Connection between our router and SP's frame relay switch is okay, but not the connection between the SP's router and the far-end router.
Deleted     Connection is not okay between our router and the SP's frame relay switch.
```

To see which IP addresses are reachable over the available DLCIs, we use `show frame-relay map` command:
```
R1#sh frame map
Serial2/0 (up): ip 10.1.1.2 dlci 102(0x66,0x1860), dynamic,
              broadcast,, status defined, active
Serial2/0 (up): ip 10.1.1.3 dlci 103(0x67,0x1870), dynamic,
              broadcast,, status defined, active
```

### Inverse ARP
```
R1#ping 10.1.1.2
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.1.1.2, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 9/11/12 ms
R1#ping 10.1.1.3
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.1.1.3, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 11/11/12 ms
```
We can see that in the last output, the far-end DLCI's IP is known to our router. However, we didn't manually configure the IP addresses on R1. The method by which R1 finds the IP of R2 and R3 (i.e., *the IP addresses at the far end of DLCI 201 and 301*) is called **Reverse ARP**. Using ARP, we can get the layer 2 address of a layer 3 address, i.e., get the MAC address of an IP. Here, given that the layer 2 address for frame-relays is DLCI, we get the IP address.

Another important point to notice in the output is the `dynamic` keyword, because this mapping was set up dynamically, but we can also set up static mappings. The `broadcast` keyword is also important. We know that frame-relays are NBMA (Non-Broadcast Multi-Access) networks due to their nature, but we need the ability to broadcast since we need the multicast address of `224.0.0.5` for routing protocols like OSPF/EIGRP/RIP to work.

We can see from the output of R2 that it only knows about the `10.1.1.1` address and not the `10.1.1.3` address, even though it's directly connected to `10.1.1.1`:
```
R2#sh frame pvc

PVC Statistics for interface Serial2/0 (Frame Relay DTE)

              Active     Inactive      Deleted       Static
  Local          1            0            0            0
  Switched       0            0            0            0
  Unused         0            0            0            0

DLCI = 201, DLCI USAGE = LOCAL, PVC STATUS = ACTIVE, INTERFACE = Serial2/0

  input pkts 9             output pkts 6            in bytes 656       
  out bytes 554            dropped pkts 0           in pkts dropped 0         
  out pkts dropped 0                out bytes dropped 0         
  in FECN pkts 0           in BECN pkts 0           out FECN pkts 0         
  out BECN pkts 0          in DE pkts 0             out DE pkts 0         
  out bcast pkts 1         out bcast bytes 34        
  5 minute input rate 0 bits/sec, 0 packets/sec
  5 minute output rate 0 bits/sec, 0 packets/sec
  pvc create time 00:36:51, last time pvc status changed 00:36:51
R2#sh frame map
Serial2/0 (up): ip 10.1.1.1 dlci 201(0xC9,0x3090), dynamic,
              broadcast,
              CISCO, status defined, active
```
This is because of the nature of inverse ARP, which only returns the IP address of the known DLCIs, i.e., it only returns the IP address of the router at the far end of the PVC. We can demonstrate this as we can ping 10.1.1.1 from either of `10.1.1.2` or `10.1.1.3`, but not the other PVC's IP directly.
```
R2#ping 10.1.1.1
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.1.1.1, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 11/11/12 ms
R2#ping 10.1.1.3
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.1.1.3, timeout is 2 seconds:
.....
Success rate is 0 percent (0/5)

R3#ping 10.1.1.1
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.1.1.1, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 11/11/12 ms
R3#ping 10.1.1.3
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.1.1.3, timeout is 2 seconds:
.....
Success rate is 0 percent (0/5)
```

This can be solved by a couple of different ways: we _can_ add another PVC between R2 and R3, turning this into a full mesh, but the total number of links required increases exponentially with increasing number of nodes. Instead we can tell our routers how to reach an IP using _frame relay maps_.

### Frame Relay Maps
A **Frame relay map** links an IP address to a local DLCI. Thus, the router will know which PVC to use as an egress interface to reach the required IP address. Since we're using IP routing protocols like OSPF/EIGRP, we also have to include the `broadcast` keyword to support _multicast_ in the PVC's mapping.
```
R2(config-if)#frame map ip 10.1.1.3 201 broadcast
R2(config-if)#end
R2#sh frame map
Serial2/0 (up): ip 10.1.1.3 dlci 201(0xC9,0x3090), static,
              broadcast,
              CISCO, status defined, active
Serial2/0 (up): ip 10.1.1.1 dlci 201(0xC9,0x3090), dynamic,
              broadcast,
              CISCO, status defined, active

R3(config-if)#frame map ip 10.1.1.2 301
R3(config-if)#end
R3#
*Dec 24 12:21:45.340: %SYS-5-CONFIG_I: Configured from console by console
R3#sh frame map
Serial2/0 (up): ip 10.1.1.2 dlci 301(0x12D,0x48D0), static,
            broadcast,
            CISCO, status defined, active
Serial2/0 (up): ip 10.1.1.1 dlci 301(0x12D,0x48D0), dynamic,
            broadcast,
            CISCO, status defined, active
```

Now, all routers can _ping_ each other! However, there is a major issue on both R2 and R3 now. The moment we set up static mappings, inverse ARP is turned off on that interface. Thus, we can reach 10.1.1.1 since we've already inverse ARP-ed the address for the associated DLCI at R2 and R3, but the next time we boot, since inverse ARP is off, we don't be able to find the IP associated with DLCI 201 or 301. Since we can't find the IP associated with the local DLCI, we won't know how to reach 10.1.1.1 and hence, won't be able to reach the router in the other spoke either! Thus, we need to add static mapping for the hub's IP (`10.1.1.1`) on each spoke router as well.
```
R2(config-if)#frame map ip 10.1.1.1 201 broadcast
R2(config-if)#end
R2#sh frame map
Serial2/0 (up): ip 10.1.1.3 dlci 201(0xC9,0x3090), static,
              broadcast,
              CISCO, status defined, active
Serial2/0 (up): ip 10.1.1.1 dlci 201(0xC9,0x3090), static,
              broadcast,
              CISCO, status defined, active

              R3(config-if)#frame map ip 10.1.1.1 301 broadcast
              R3(config-if)#

R3(config-if)#frame map ip 10.1.1.1 301 broadcast
R3(config-if)#end
R3#sh frame map
Serial2/0 (up): ip 10.1.1.2 dlci 301(0x12D,0x48D0), static,
            broadcast,
            CISCO, status defined, active
Serial2/0 (up): ip 10.1.1.1 dlci 301(0x12D,0x48D0), static,
            broadcast,
            CISCO, status defined, active
```
We an now see that both the IP addresses are statically configured on R2 and R3. However, since we don't have static Frame-relay maps on R1, we don't need to convert the existing dynamic mapping since reverse ARP will still work at R1. However, even in this solution, the scalability is still a big problem. If we have 10 different remote sites, then all of them will have to be configured for all 9 others with static frame-relay map statements. This is where sub-interfaces can help us out.

### Frame Relay Sub-Interfaces
Sub-interfaces are used to logically divide a physical interface such that each resultant sub-interface can be assigned to a different subnet. In case of frame-relays, it can be of two types:
* Point-to-Point
* Multi-point (Point-to-Multipoint)

The difference between the two lies in the fact that a point-to-point sub-interface is associated with a single DLCI, but a multipoint sub-interface can have one or more DLCIs associated. The multi-point sub-interfaces are most useful when we have a full/partial mesh topology. when setting up a point-to-point or multipoint interface, we first have to set up the encapsulation to frame-relay and the frame relay LMI type on the parent (physical) interface, but not the IP address. So, the parent's config will look like:
```
R1(config-if)#do sh run | s Serial1/0
interface Serial1/0
 no ip address
 encapsulation frame-relay
 shutdown
 serial restart-delay 0
 frame-relay lmi-type ansi
```

### Frame Relay Point-to-Point Sub-Interfaces
Now we have to create the sub-interface and choose the type of sub-interface. In this case, we choose the `Point-to-Point` sub-interface and assign an IP to it. The two sub-interfaces _need to be in different subnets_.  Then we also have to assign a dedicated DLCI to the sub-interface:
```
R1(config)#int s1/0.1 p
R1(config-subif)#ip addr 10.1.1.1 255.255.255.0
R1(config-subif)#no shut
R1(config-subif)#frame interface-dlci 102
R1(config)#int s1/0.2 p
R1(config-subif)#ip addr 10.1.2.1 255.255.255.0
R1(config-subif)#no shut
R1(config-subif)#frame int 103        
```
It's important to note that the Point-to-Point interfaces don't accept `frame map ip` commands, since they don't have multiple PVCs and hence, multiple DLCIs to send packets on. They each get assigned a single DLCI and they forward all data to them.

Now we have to configure the interfaces on R2 and R3 as well.
```
R2(config)#int s1/0
R2(config-if)#ip addr 10.1.1.2 255.255.255.0
R2(config-if)#no shut

R3(config)#int s1/0
R3(config-if)#ip addr 10.1.2.2 255.255.255.0
R3(config-if)#no shut
```

Now we'll see that the PVCs are available on R1:
```
R1#sh frame pvc

PVC Statistics for interface Serial1/0 (Frame Relay DTE)

              Active     Inactive      Deleted       Static
  Local          2            0            0            0
  Switched       0            0            0            0
  Unused         0            0            0            0

DLCI = 102, DLCI USAGE = LOCAL, PVC STATUS = ACTIVE, INTERFACE = Serial1/0.1

  input pkts 0             output pkts 2            in bytes 0         
  out bytes 708            dropped pkts 0           in pkts dropped 0         
  out pkts dropped 0                out bytes dropped 0         
  in FECN pkts 0           in BECN pkts 0           out FECN pkts 0         
  out BECN pkts 0          in DE pkts 0             out DE pkts 0         
  out bcast pkts 2         out bcast bytes 708       
  5 minute input rate 0 bits/sec, 0 packets/sec
  5 minute output rate 0 bits/sec, 0 packets/sec
  pvc create time 00:11:15, last time pvc status changed 00:00:08

DLCI = 103, DLCI USAGE = LOCAL, PVC STATUS = ACTIVE, INTERFACE = Serial1/0.2

  input pkts 0             output pkts 2            in bytes 0         
  out bytes 708            dropped pkts 0           in pkts dropped 0         
  out pkts dropped 0                out bytes dropped 0         
  in FECN pkts 0           in BECN pkts 0           out FECN pkts 0         
  out BECN pkts 0          in DE pkts 0             out DE pkts 0         
  out bcast pkts 2         out bcast bytes 708       
  5 minute input rate 0 bits/sec, 0 packets/sec
  5 minute output rate 0 bits/sec, 0 packets/sec
  pvc create time 00:09:51, last time pvc status changed 00:00:08
R1#sh frame map
Serial1/0.1 (up): point-to-point dlci, dlci 102(0x66,0x1860), broadcast
          status defined, active
Serial1/0.2 (up): point-to-point dlci, dlci 103(0x67,0x1870), broadcast
          status defined, active
```

Also, the far-end IPs of each PVC can be pinged:
```
R1#ping 10.1.1.2
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.1.1.2, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 11/11/12 ms
R1#ping 10.1.2.2
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.1.2.2, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 11/11/12 ms
```
So, it's not at all needed to have sub-interfaces on both ends of the link. Now all we have to do to let the two spoke routers communicate is set up basic routing, either by static routes or the use of a routing protocol:
```
R2(config)#ip route 10.1.2.0 255.255.255.0 10.1.1.1        

R3(config)#ip route 10.1.1.0 255.255.255.0 10.1.1.1

R2#ping 10.1.2.2
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.1.2.2, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 20/20/21 ms

R3#ping 10.1.1.2
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.1.1.2, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 20/21/23 ms
R3#sh ip int br | e un
Interface                  IP-Address      OK? Method Status                Protocol
Serial1/0                  10.1.2.2        YES manual up                    up      
```

We _could_ just simply set up S1/0 to be the exit interface for unknown routes, i.e., the egress interface for the default-router:
```
R3(config)#no ip route 10.1.1.0 255.255.255.0
R3(config)#ip route 0.0.0.0 0.0.0.0 s1/0
%Default route without gateway, if not a point-to-point interface, may impact performance

```

# Alpine Host Setup
We need a HTTPD server, a utility like curl, telnet and a service launcher on our host.

First connect to the internet via NAT and confirm connection with a ping to google. Then, the commands to do this are:
```
apk add mini_httpd
apk add curl
apk add openrc --no-cache
apk add busybox-extras
```

We need to reboot the server now. Then, we enable the user of openrc and start the mini_httpd process:
```
touch /run/openrc/softlevel
rc-service mini_httpd start
```

We'll now configure the server with:
```
mkdir /www
chown minihttpd /www
mv /etc/mini_httpd/mini_httpd.conf /etc/mini_httpd/mini_httpd.conf.orig
vi /etc/mini_httpd/mini_httpd.conf
```

The bare-basic contents of `/etc/mini_httpd/mini_httpd.conf` are:
```
## do not leave empty lines in here!
#host=www.example.org
port=80
user=minihttpd
dir=/www
nochroot
```

Now we create the homepage for the HTTP server with:
```
vi /www/index.html
```

The contents of the index file in the HTTPD server's www directory should be:
```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <title>HTML5</title>
</head>
<body>
    Server is online
</body>
</html>
```

Finally, we start the HTTPD service and to have the HTTPD server start at boot, we add it to the default run-level:
```
rc-service mini_httpd start
rc-update add mini_httpd default
```

Now, we disconnect from the NAT cloud, erase the DHCP config and create a new config in `/etc/network/interfaces`:
```
auto eth0
iface eth0 inet static
       address 192.168.1.2
       netmask 255.255.255.0
       gateway 192.168.1.1
```
