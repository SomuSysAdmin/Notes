# BGP
## BGP Fundamentals

## Config Cheat Sheet
* In BGP, since it's a path vector protocol, the neighbours need to be configured manually, and won't be discovered automatically like EIGRP or OSPF.
* In neighbour config, we need to mention both mention neighbour's IP address and AS number of the remote AS in which the neighbour resides.
* If the remote AS is the same AS as this router, then it's iBGP - otherwise eBGP.
* Other than neighbor, the network also needs to be specified - and these will be the network(s) advertised
* We provide the network subnet mask instead of the wildcard mask in the neighbor command.
* BGP has its own routing table other than the IP routing table of the router.

### Commands
Start BGP on router					`R1(config)#router bgp 65001	! 65001 = AS number`
Configuring a neighbour				`R1(config-router)#neighbor 172.16.1.2 remote-as 65002`
Advertising a network 				`R1(config-router)#network 17.1.1.0 mask 255.255.255.0`
Show AS number and BGP state		`R1#sh ip bgp summary`
Show BGP neighbours/BGP version		`R1#sh ip bgp neighbors`

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
So, both the `8.8.8.0/24` and the `17.1.1.0/24` networks were learnt via iBGP, demonstrated by the `*>i`.

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
