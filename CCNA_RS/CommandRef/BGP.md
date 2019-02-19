# BGP
* In BGP, since it's a path vector protocol, the neighbours need to be configured manually, and won't be discovered automatically like EIGRP or OSPF.
* A TCP session is established between sessions.
* BGP Advertises:
	- **Network prefix and length**: together called **NLRI (_Network Layer Reachability Information_)**.
	- **Path Attributes**: A collection of info/attributes about the network used for path selection.
* BGP's metric is AS-hops - for same number of AS hops.
* BGP doesn't consider bandwidth in metric calculation.
* Neighbours need not be adjacent - they can be several hops away.
* In neighbour config, we need to mention both mention neighbour's IP address and AS number of the remote AS in which the neighbour resides.
* If the remote AS is the same AS as this router, then it's iBGP - otherwise eBGP.
* Other than neighbor, the network also needs to be specified - and these will be the network(s) advertised
* We provide the network subnet mask instead of the wildcard mask in the neighbor command.
* BGP has its own routing table other than the IP routing table of the router.

## BGP Path selection criteria
Some of the BGP path selection criteria are:
* Weight - locally significant - higher preferred.
* Local preference - locally significant - higher preferred.
* AS_PATH length - number of AS's in the AS_PATH attribute - lower preferred.
* Origin type - How the path was injected in BGP: (in order of preference)
	- I = IGP
	- E = EGP
	- ?  = Incomplete info
* Paths - eBGP preferred over iBGP
* Age - Oldest BGP route is preferred
* Router ID - Route received from lowest RID preferred. - *tie breaker*.
* Neighbour IP - Route received from neighbour with lowest IP preferred. - *tie breaker*.

### BGP States
The possible BGP states in the output of the `sh ip bgp summary` are:
```
State				Meaning
==================	====================================================================
Idle: No peering	Router is looking for a neighbour but hasn't found it yet.
Idle(admin)			The neighbourship has been administratively shut down.
Connect				TCP 3-way handshake completed and session started.
OpenSent/Active		An open message was sent to try and establish peering.
OpenConfirm			Router received a reply to the open message.
Established			Routers have established a BGP peering session; BGP is working.
```

## BGP Data-Structures
BGP has a couple of tables:
* **BGP Neighbour table** - contains Neighbour's IP address, AS number and state of relationship
* **BGP Table/Routing Info Base (RIB)** - Contains all routes known to BGP and some of them end up in the IP routing table.

Some Reasons why a route in BGP RIB may not end up in the routing table are:
* A route with a lesser AD is available, perhaps a static route or a directly connected route.
* Next hop address isn't reachable.

## BGP Message types
There are 4 types of BGP messages:
- Open message
- Keepalive
- Update
- Notification

### Neighbourship formation
* Initially, BGP state is idle.
* R1 initiates a TCP session with R2, causing both to go in a **connect** state.
* R1 will then send an **open message** to R2, in which it sends various info about itself. This causes them to go in a **OpenSent/Active** state.
* R2 will then reply to R1's open message with an Open message of its own, which causes both to transition to a **OpenConfirm** state.
* Both routers will now send a *keepalive* to one another, to signify that they're still up and active, and finally, BGP peering will transition to **Established**.
* If a keepalive isn't received, that router will send out a notification and transition back to the idle state.

### Open message contents
The Open message that the routers send one another contains:
* BGP version (*=4 currently*).
* Local AS number
* Hold time
* Router ID
* Optional parameters.

The **keepalive** message is just a message header that keeps the hold timer from expiring.

The **Update messages** sent by BGP contain information such as:
- withdrawn routes
- path attributes
- NLRI/advertisements.

**Notification/Error Message** - messages generated when there's an error. For example, when a keepalive isn't received, the BGP peer will send out a notification via a notification message, containing the:
- Error code
- Error sub-code
- Information about the error.

## Config Cheat Sheet
### Commands
Start BGP on router					`R1(config)#router bgp 65001	! 65001 = AS number`
Set Router ID Statically			`R1(config-router)#bgp router-id 1.1.1.1`
Configuring a neighbour				`R1(config-router)#neighbor 172.16.1.2 remote-as 65002`
Advertising a network 				`R1(config-router)#network 17.1.1.0 mask 255.255.255.0`
Advertising a network with next hop	`R1(config-router)#network 17.1.1.0 mask 255.255.255.0 next-hop-self`
Show AS number and BGP state		`R1#sh ip bgp summary`
Show BGP neighbours/BGP version		`R1#sh ip bgp neighbors		!Also shows iBGP or eBGP`
Show ongoing TCP sessions			`R4#sh tcp brief`

### Criteria for maintaining BGP neighbourship:
* Neighbour must be explicitly declared with the **correct AS number**.
* All required neighbours should be advertised correctly.
* The network command uses a subnet mask and **not** a wildcard mask.
* The network command looks for a route in the IP routing table that matches the network command's route **exactly**. So, if our IP routing table has a `4.4.4.4/32` route and the loopback interface configured with `4.4.4.4/32`, but our network is for `4.4.4.0/24`, BGP still won't advertise it. Here, the loopback is a `/32` network and BGP is looking for `4.4.4.4/24`, and the mask itself must match exactly!

### Next hop self
If we have R0 connected to R1 in the above topology, when advertising the remote AS 65002's networks, R1 won't change the _next-hop_ from R2's IP of `2.2.2.2` to it's own IP `1.1.1.1`. Thus, if R0 doesn't know how to get to 2.2.2.2, it won't be able to reach the 65002 AS. To solve this, while declaring the network for BGP, we can say:
```
R1(config-router)#network 17.1.1.0 mask 255.255.255.0 next-hop-self
```
Now, on getting the advertisement, R0 will see that the next hop should be R1, and R1 will relay the packet to R2 to reach the remote AS.

### BGP Config
We configure R1 to be in AS 65001:
```
R1(config)#router bgp 65001
R1(config-router)#neighbor 172.16.1.2 remote-as 65002
R1(config-router)#network 17.1.1.0 mask 255.255.255.0
```

At this point, without even configuring R2, our BGP routing table looks like:
```
Router(config-if)#do sh ip bgp
BGP table version is 2, local router ID is 17.1.1.1
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal,
			  r RIB-failure, S Stale, m multipath, b backup-path, f RT-Filter,
			  x best-external, a additional-path, c RIB-compressed,
Origin codes: i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

	 Network          Next Hop            Metric LocPrf Weight Path
 *>  17.1.1.0/24      0.0.0.0                  0         32768 i
```
The above output has the following components:
* `*` - Indicates that the router is valid, i.e., the network is currently reachable.
* `>` - Indicates that this is the best path known to that network
* `Next hop = 0.0.0.0` tells us that the `17.1.1.0/24` network is currently being advertised by `0.0.0.0`, i.e., locally.

We can view more BGP details with the `sh ip bgp summary` command:
```
R1#sh ip bgp summary
BGP router identifier 17.1.1.1, local AS number 65001
BGP table version is 4, main routing table version 4
1 network entries using 144 bytes of memory
1 path entries using 80 bytes of memory
1/1 BGP path/bestpath attribute entries using 152 bytes of memory
0 BGP route-map cache entries using 0 bytes of memory
0 BGP filter-list cache entries using 0 bytes of memory
BGP using 376 total bytes of memory
BGP activity 1/0 prefixes, 2/1 paths, scan interval 60 secs

Neighbor        V           AS MsgRcvd MsgSent   TblVer  InQ OutQ Up/Down  State/PfxRcd
17.1.1.2        4        65001       0       0        1    0    0 never    Idle
```
We can see that the BGP neighbourship is in an idle state. This is because the neighbourship hasn't been applied at the peer - so both routers must agree to be each other's neighbours for the neighbourship/BGP peering to be established.

On R2, we configure:
```
R2(config)#router bgp 65001
R2(config-router)#neighbor 17.1.1.1 remote-as 65001
*Feb 15 09:21:08.333: %BGP-5-ADJCHANGE: neighbor 17.1.1.1 Up
R2(config-router)#network 17.1.1.0 mask 255.255.255.0
R2(config-router)#network 8.8.8.0 mask 255.255.255.0
```

Now we can check the BGP state again with:
```
R2#sh ip bgp summary
BGP router identifier 17.1.1.2, local AS number 65001
...
Neighbor        V           AS MsgRcvd MsgSent   TblVer  InQ OutQ Up/Down  State/PfxRcd
17.1.1.1        4        65001       7       8        4    0    0 00:02:47        1
```
This command can be confusing because it doesn't explicitly state if the BGP session has been established - instead it shows that **1 prefix has been received**, i.e., the neighbour has advertised a network to us. We can also see that it's been up for _2m 47s_.

Back on R1 we can see:
```
R1#sh ip bgp summary
BGP router identifier 17.1.1.1, local AS number 65001
...
Neighbor        V           AS MsgRcvd MsgSent   TblVer  InQ OutQ Up/Down  State/PfxRcd
17.1.1.2        4        65001      11      10        5    0    0 00:05:41        2
```
The two networks advertised to R1 by R2 via BGP peering are `17.1.1.0/24` and `8.8.8.0/24`.

We can see the BGP neighbourship details, as well as the BGP version being used using:
```
R1#sh ip bgp nei
BGP neighbor is 17.1.1.2,  remote AS 65001, internal link
  BGP version 4, remote router ID 17.1.1.2
  BGP state = Established, up for 00:10:32
  Last read 00:00:12, last write 00:00:15, hold time is 180, keepalive interval is 60 seconds
  Neighbor sessions:
    1 active, is not multisession capable (disabled)
  Neighbor capabilities:
    Route refresh: advertised and received(new)
    ...
```
We can also see that the BGP state is **Established** which means that our router is learning routes via the neighbour.

The BGP table now contains:
```
R1#sh ip bgp   
BGP table version is 5, local router ID is 17.1.1.1
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal,
...
     Network          Next Hop            Metric LocPrf Weight Path
 *>i 8.8.8.0/24       17.1.1.2                 0    100      0 i
 * i 17.1.1.0/24      17.1.1.2                 0    100      0 i
 *>                   0.0.0.0                  0         32768 i
```
So, both the `8.8.8.0/24` and the `17.1.1.0/24` networks were learnt via iBGP, demonstrated by the `*>i`. The value of '*i*' in the Path shows that the network is within the same AS, i.e., learnt via iBGP. In case of eBGP, the path would contain the AS number for the remote AS, followed by `i`. Thus, if we have to go through ASNs : 65004, 65003 and then 65001 to reach a network, then the path will be: `65004 65003 65001 i`.

Now we can configure an eBGP link with R3 from R2:
```
R2(config-router)#neighbor 8.8.8.2 remote-as 65002
```

We now configure R3 as:
```
R3(config)#router bgp 65002
R3(config-router)#neighbor 8.8.8.1 remot 65001
*Feb 15 09:42:02.844: %BGP-5-ADJCHANGE: neighbor 8.8.8.1 Up
R3(config-router)#neighbor 15.1.1.2 remote 65002
R3(config-router)#network 15.1.1.0 mask 255.255.255.0
R3(config-router)#network 8.8.8.0 mask 255.255.255.0
```

The BGP summary on R3 now shows us:
```
R3#sh ip bgp summary
BGP router identifier 3.3.3.3, local AS number 65002
...
Neighbor        V           AS MsgRcvd MsgSent   TblVer  InQ OutQ Up/Down  State/PfxRcd
8.8.8.1         4        65001       8       9        5    0    0 00:03:13        2
15.1.1.2        4        65002       0       0        1    0    0 never    Idle
```
We can see that we're currently peering with `8.8.8.1` but not `15.1.1.2` since BGP hasn't been configured yet on it.

We can also confirm that the relationship with 8.8.8.1 is via an eBGP peering by the `external link` in :
```
R3#sh ip bgp nei
BGP neighbor is 8.8.8.1,  remote AS 65001, external link
  BGP version 4, remote router ID 17.1.1.2
  BGP state = Established, up for 00:06:42
  ...
```

We can see which routes we learnt via BGP:
```
R3#sh ip route bgp
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
...
      17.0.0.0/24 is subnetted, 1 subnets
B        17.1.1.0 [20/0] via 8.8.8.1, 00:09:10
```

Ping and traceroute now yield:
```
R3#ping 17.1.1.1
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 17.1.1.1, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 9/10/14 ms
R3#traceroute 17.1.1.1
Type escape sequence to abort.
Tracing the route to 17.1.1.1
VRF info: (vrf in name/id, vrf out name/id)
  1 8.8.8.1 7 msec 10 msec 5 msec
  2 17.1.1.1 [AS 65001] 8 msec 8 msec 6 msec
```

Finally, we configure R4 as:
```
R4(config)#router bgp 65002
R4(config-router)#neighbor 15.1.1.1 remote 65002
*Feb 15 09:54:23.985: %BGP-5-ADJCHANGE: neighbor 15.1.1.1 Up
R4(config-router)#network 15.1.1.0 mask 255.255.255.0
```

On R4, the routes learnt via BGP will be:
```
R4#sh ip route bgp
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
       a - application route
       + - replicated route, % - next hop override, p - overrides from PfR

Gateway of last resort is not set

      8.0.0.0/24 is subnetted, 1 subnets
B        8.8.8.0 [200/0] via 15.1.1.1, 00:02:27
      17.0.0.0/24 is subnetted, 1 subnets
B        17.1.1.0 [200/0] via 8.8.8.1, 00:02:22
```

Each router in the BGP _chain_ has a TCP session established with its (directly adjacent) neighbour:
```
R4#sh tcp br
TCB       Local Address               Foreign Address             (state)
10B83578  15.1.1.2.179               15.1.1.1.31454              ESTAB
```

### BGP Peer Groups
Unlike other protocols, BGP sends updates on a individual neighbour basis. This means the CPU has to create and send updates for each neighbour. If filtering such as sending selective neighbours certain prefixe, i.e., IP prefix list, then that can increase the CPU demand even more! Thus, if we have several peers that receive the same update, we can put all of them in the same **peer group**, who will all receive the same update. We can then have the CPU create the update just once for the entire peer group, thus dramatically reducing the load on the CPU. This can be very beneficial in large networks.

Let us consider we have the following IP prefix list configured:
```
R2#sh ip prefix-list RFC1918_BLOCK
ip prefix-list RFC1918_BLOCK: 5 entries
   seq 5 deny 10.0.0.0/8 le 32
   seq 10 deny 172.16.0.0/12 le 32
   seq 15 deny 192.168.0.0/16 le 32
   seq 20 permit 0.0.0.0/0
   seq 25 permit 0.0.0.0/0 ge 8
```
We want this list to block incoming traffic with *RFC-1918 (private) addresses* from coming in from the ISP1 and ISP2 routers. Instead of applying these filters individually for BGP, we can put them in a peer group.

We have to create a new peer group in BGP configuration mode and then apply the prefix list to the peer group in the inbound direction (since we don't want RFC 1918 addresses coming in in the inbound direction):
```
R2(config)#router bgp 65001       
R2(config-router)#neighbor ROUTE-PG peer-group
R2(config-router)#neighbor ROUTE-PG prefix-list RFC1919_BLOCK in
```

Now we have to add the neighbours to the peer group:
```
R2(config-router)#neighbor 198.51.100.2 peer-group ROUTE-PG
*Feb 17 07:51:04.473: %BGP-5-NBR_RESET: Neighbor 198.51.100.2 reset (Member added to peergroup)
*Feb 17 07:51:04.488: %BGP-5-ADJCHANGE: neighbor 198.51.100.2 Down Member added to peergroup
*Feb 17 07:51:04.488: %BGP_SESSION-5-ADJCHANGE: neighbor 198.51.100.2 IPv4 Unicast topology base removed from session  Member added to peergroup
*Feb 17 07:51:05.037: %BGP-5-ADJCHANGE: neighbor 198.51.100.2 Up

R2(config-router)#neighbor 198.51.100.6 peer-group ROUTE-PG
*Feb 17 07:51:24.236: %BGP-5-NBR_RESET: Neighbor 198.51.100.6 reset (Member added to peergroup)
*Feb 17 07:51:24.248: %BGP-5-ADJCHANGE: neighbor 198.51.100.6 Down Member added to peergroup
*Feb 17 07:51:24.253: %BGP_SESSION-5-ADJCHANGE: neighbor 198.51.100.6 IPv4 Unicast topology base removed from session  Member added to peergroup
*Feb 17 07:51:24.524: %BGP-5-ADJCHANGE: neighbor 198.51.100.6 Up
```

Now route advertisements by BGP sent to both neighbours will be the same, and calculated once, since they're in the same peer group.

## Advanced BGP Concepts
### The Weight Attribute
The weight attribute of a BGP route is a cisco-specific path attribute where routes with a higher weight are preferred. It's a way for a router to prefer paths from one neighbour rather than another neighbour.

In the topology below, we have two routes leading out to the internet (*AS-65003*) where our target `9.9.9.9` resides. The one to ISP1 is a fractional T1 with **768Kbps** bandwidth while the one to ISP2 is a complete T1 with a **1.544Mbps** bandwidth. Since the link to R2 has a greater bandwidth, we would prefer to reach it via ISP1, but that's not the case right now:
```
R2#sh ip route bgp
...
	9.0.0.0/32 is subnetted, 1 subnets
B        9.9.9.9 [20/0] via 198.51.100.2, 00:03:25
...
R2#sh ip bgp
...

Network          Next Hop            Metric LocPrf Weight Path
*   9.9.9.9/32       198.51.100.6                           0 65004 65003 i
*>                   198.51.100.2                           0 65002 65003 i
```
This is because BGP doesn't use bandwidth as a metric or a factor in choosing which path to use.

To assign the weight to a route, we need to create a **route-map**:
```
R2(config)#route-map RT-WEIGHT
R2(config-route-map)#set weight 10
R2(config-route-map)#exit
```

Now we apply the route map to that particular neighbor:
```
R2(config)#router bgp 65001
R2(config-router)#neighbor 198.51.100.6 route-map RT-WEIGHT in
R2#clear ip bgp * soft
```
The last line makes the router do a *soft* reset of the peer settings on this router without dropping the existing TCP sessions.

Now we can see that our preferred route is the one being used:
```
R2#sh ip bgp
...
     Network          Next Hop            Metric LocPrf Weight Path
 *>  9.9.9.9/32       198.51.100.6                          10 65004 65003 i
 *                    198.51.100.2                           0 65002 65003 i
```
