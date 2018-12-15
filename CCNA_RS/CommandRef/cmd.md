# RIP
## To turn on RIP :

router rip
    version 2
    network 172.16.0.0
    network 192.168.1.0

Since we haven't specified that we're using classless addresses, RIPv2 still uses classful addressing
Hence, we set the network address `172.16.0.0` for the `172.16.1.1/30` network
Even if we were to write `network 172.16.1.0`, it'd still round it off to `172.16.0.0` due to classful network masks.

Here, `network 172.16.0.0` means _Let any interface using `172.16.0.0` address space use the RIPv2 protocol to advertise routes_.
Thus it allows `s0/1` with IP address `172.16.1.2` to participate in RIP, but since nothing else is configured yet, it doesn't advertise anything on it.

Now, we have the `network 192.168.1.0` which lets any interface in the **Class C** range participate in RIPv2.
So, `s1/1` with IP address `192.168.1.1` is allowed to participate in RIPv2.

## Auto-summarization
By default RIPv2 configures *summary-routes* automatically. This means the `10.1.1.0/24` network on **R1 g0/0** and `10.2.2.0/24` network on **R3 g0/1** are both clubbed in the classful network of `10.0.0.0/8` .

## Advertisements
The above config has the effect:
* On `s0/1`:
    - Advertises the `192.168.1.0` network
* On `s1/1`:
    - Advertises the `172.16.0.0` network

---

So, now R2 summarizes the network `10.1.1.0/24` on **R1 g0/0** and `10.2.2.0/24` on **R2 g0/0** into a single classful network `10.0.0.0/8`. The problem is the former is available through R1 and the latter through R2, and thus, there's no single path to the **Class A 10.0.0.0/8** network. Thus, when we have **dis-contiguous subnets** we might face this problem with auto-summary, that can be fixed by turning auto-summary off.

```
R2(config)#router rip
R2(config-router)#no auto-summary
```

To immediately trigger an update and not wait for the _full update_, we can use the `clear ip route *` command.

# DHCP Theory
There are four steps in getting a DHCP assigned IP.
* **D** - Discover
* **O** - Offer
* **R** - Request
* **A** - Acknowledgement

## Discover
The host sends a DHCP Discover broadcast message to search for a DHCP server in the LAN/VLAN. If the DHCP server is outside the LAN/VLAN then the broadcast won't reach it. So, the host normally won't get an IP address or the config, but this can be solved by configuring the router as a _DHCP Relay Agent_.

### DHCP Relay Agent
A **DHCP Relay Agent** is a router that's been configured to forward _DHCP Discover messages_ to a specific IP/network.

## Offer
When the **Discover** message reaches a DHCP server, it replies with a **Offer** that basically states to the host that it's a DHCP server and the client should send requests to its IP address to have an IP assigned.

## Request
Now that the host knows about the DHCP server, it sends a request to get the IP address info, i.e., an IP address, the gateway IP and the DNS server's address.

## Acknowledgement
Finally, the server responds to the DHCP request with the queried details in an **Acknowledgement**, which the host uses to set up its network configuration.  

# IP Helper Address
The scenario where there's a centralized DHCP server that's handing out IPs on one subnet but the clients are in another subnet is very common. This is critical because the discover message from the host can't exit the subnet to reach the DHCP server without configuration of a DHCP Relay agent.

To have a Cisco router interface get its IP address via DHCP, we use the command `ip address dhcp`.
This is what we do for cable/DSL modems in our homes.

Let us consider our host is connected to a router on the interface **R1 g0/0** with the IP address `10.1.1.1/24`. R1 is connected to the DHCP server through `172.16.1.1/24`. Now we have to ask the router, **R1** to forward DHCP discover broadcasts to the server available at `172.16.1.2`. To forward DHCP broadcast (as well as a few other types of broadcast, such as _BOOTP_), on the ingress interface from the client on R1, we use:
```
R1(config-if)ip helper-address 172.16.1.2
```
Now, whenever the router R1 encounters a DHCP Discover message on **R1 g0/0**, incoming from the client, it'll forward it to the DHCP server available at `172.16.1.2`.

### Bouncing an interface
The act of bouncing an interface is to shut it down and then bring it back up. Once the help IP has been set, we can bounce the interface to cuase it to send out a DHCP broadcast.

# Configuring a Router as a DHCP server
## Excluded addresses
To exclude address ranges we use the `ip dhcp excluded-addresses` command, followed by the range.
```
ip dhcp excluded-addresses 10.1.1.1     10.1.1.100
ip dhcp excluded-addresses 10.1.1.200   10.1.1.254
```

These address ranges can now be used for static IP assignments.

## DHCP Address pools
These are ranges of IP that are available to be assigned to the devices that request for dynamic IP addresses. Just like excluded ranges, there can be multiple DHCP address pools. The three critical pieces of information for each pool are:
* IP address range (Network and Subnet Mask)
* Gateway's IP
* DNS Server's IP

These can be defined using:
```
ip dhcp pool PC
    network 10.1.1.0 255.255.255.0
    default-router 10.1.1.1
    dns-server 192.168.1.1
```

While setting this up, we can also use the **slash notation for a subnet mask**, which doesn't happen for interface IPs.
To show the existing DHCP pools, we use:
```
DHCP#sh ip dhcp pool

Pool PC :
 Utilization mark (high/low)    : 100 / 0
 Subnet size (first/next)       : 0 / 0
 Total addresses                : 254
 Leased addresses               : 3
 Pending event                  : none
 1 subnet is currently in the pool :
 Current index        IP address range                    Leased addresses
 10.1.1.104           10.1.1.1         - 10.1.1.254        3
```
To show existing DHCP leases, we use:
```
DHCP#sh ip dhcp binding
Bindings from all pools not associated with VRF:
IP address          Client-ID/              Lease expiration        Type
                    Hardware address/
                    User name
10.1.1.101          0100.5079.6668.00       Dec 14 2018 01:03 PM    Automatic
10.1.1.102          0100.5079.6668.01       Dec 14 2018 01:04 PM    Automatic
10.1.1.103          0100.5079.6668.02       Dec 14 2018 01:04 PM    Automatic
```

# Network Address Translation (NAT)
Given that we've exhausted IPv4 addresses, it's impossible to connect all the devices on the planet to the internet with unique IPv4 addresses. But we have non-publicly routable RFC-1918 private address ranges, with which we can assign addresses in an organization. The problem with this is that since they're only unique within the organization, they're not publicly routable, and thus, the servers out on the internet can't respond to them.

To solve this problem, we use network address translation which enables us to convert private IP range addresses to publicly-routable IP range from a pool of IP addresses given to us by our ISP. Thus, we can both handle the IPv4 address exhaustion while also getting increased security since the external network doesn't get to know about the internal IP address.

## NAT Operation
Let us consider the client with the IP `10.1.1.1` wants to communicate with a server out on the internet with the IP address `203.0.113.1`. The gateway router has an IP of `10.1.1.100`. Now, when the packet reaches R1, it has the *Source IP* of `10.1.1.1` and a *Destination IP* of `203.0.113.1`. Now, if R1 has a public IP address pool of `192.0.2.101 - 192.0.2.199`, it may choose to map **outside address** `192.0.2.101` to the internal (**inside address**) of `10.1.1.1`. This will be stored in it's **Network Address Translation Table (_NAT Table_)**. The packet will then be sent to `203.0.113.1` with a source IP of `192.0.2.101` which is publicly routable and the server can respond to.

Then when the server at `203.0.113.1` responds to the query sent from `192.0.2.101`, R1 sends the packet from the internet to the host that originally requested it, which is obtained again from the **NAT table** and in this case is `10.1.1.1`. Similarly, if `10.1.1.2` is assigned a public IP of `192.0.2.102`, the NAT table will look like:

```
Inside + Local IP   Inside + Global IP
=================   ==================
10.1.1.1            192.0.2.101
10.1.1.2            192.0.2.102
```
The non-publicly routable and inside IP addresses here are called **Inside Local addresses** because they're inside out network and the publicly routable and inside addresses are called **Inside Global IP** addresses, because even though they're inside our network, they're publicly routable, i.e., global addresses.

It's also possible to have _Outside local_ addresses, but that's not commonly used and requires DNS modifications.

## Port Address Translation (PAT)
Many times, especially on home networks, the users don't have the luxury of multiple static global IP addresses. In such cases, the router WAN interface on the router gets the global IP and can also map specific ports to internal local IP addresses to have the data flow to multiple devices using a single external global IP. The PAT enabled router does this by paying attention to the port numbers on the router to which the internal devices communicate. Thus multiple internal IP addresses share a single pulicly routable IP address.

The combination of an IP address and a port number is called a **socket**. Thus, even though the IP address might not be unique while the data flows from the external server, the destination socket is always unique. The edge router will still use the same external IP to send data for multiple internal device, but will use unique port numbers to differentiate them, thus creating unique sockets for each for the server(s) to respond to. The Port Address Translation table will look like:

```
Inside + Local IP   Inside + Global IP
=================   ==================
10.1.1.1:1025       192.0.2.100:1025
10.1.1.2:1050       192.0.2.100:1050
```

## Port Mapping/Forwarding
This feature allows a router to selectively forward incoming packets based on their destination port number to a specific host inside the network. Thus if we have a UNIX server we need to connect to via telnet and a web-server on the same network, we can set up port mapping such that all incoming traffic on port 23 to the router goes to the UNIX server's internal IP on port 23 and all traffic on port 80 goes to the web-server's internal IP on port 80.

# Static NAT configuration
In the image below, since the host 10.1.1.100 doesn't have a publicly routable (global) IP, the packets from it can't cross R1 normally, since the replies wouldn't have a valid source IP out on the internet, and the servers won't know where to reply. So, we can configure **R1** to use static NAT to mark the outgoing packets with a separate **inside global** IP (_not the IP address of the WAN interface, but from a separate global IP pool_).

First we define which interface is _inside_ the network and which is _outside_ our network. In this case, **R1 Gi0/1** is inside the network and is connected to the host `10.1.1.100`, while **R1 Gi0/0** is the WAN port on the router with the IP `4.4.4.4`, provided by the ISP. We can configure the inside and outside NAT interfaces using:

```
R1(config)#int g0/1
R1(config-if)#ip nat inside
R1(config-if)#int g0/0
R1(config-if)#ip nat outside
R1(config-if)#exit
```

Now, to perform the actual static interface mapping, we need to map the internal local IP `10.1.1.100` to an internal global IP, for ex., `4.4.4.2`. We do this, and check using:
```
R1(config)#ip nat inside source static 10.1.1.100 4.4.4.2
R1(config)#do sh ip nat translations
Pro Inside global      Inside local       Outside local      Outside global
--- 4.4.4.2            10.1.1.100         ---                ---
```

Now, we can ping the server on the internet `3.3.3.3` from the local internal host `10.1.1.100`:
```
Client> ping 3.3.3.3
3.3.3.3 icmp_seq=1 timeout
3.3.3.3 icmp_seq=2 timeout
84 bytes from 3.3.3.3 icmp_seq=3 ttl=62 time=6.947 ms
84 bytes from 3.3.3.3 icmp_seq=4 ttl=62 time=9.425 ms
84 bytes from 3.3.3.3 icmp_seq=5 ttl=62 time=7.924 ms
```

We can check the translation on **R1** using:
```
R1#sh ip nat translations
Pro Inside global      Inside local       Outside local      Outside global
icmp 4.4.4.2:23005     10.1.1.100:23005   3.3.3.3:23005      3.3.3.3:23005
icmp 4.4.4.2:23261     10.1.1.100:23261   3.3.3.3:23261      3.3.3.3:23261
icmp 4.4.4.2:23517     10.1.1.100:23517   3.3.3.3:23517      3.3.3.3:23517
--- 4.4.4.2            10.1.1.100         ---                ---
```

We can also see that the protocol used was ICMP (used for _ping_).

# Dynamic NAT configuration
The method of mapping specific inside local IP addresses statically to outside global IP address doesn't scale well. Instead, we could assign a pool of outside global IP addresses that the router assigns to an inside local IP address when needed. This is called dynamic NAT. To set it up, we first need to define the inside and outside interfaces:

```
R1(config)#int g0/1
R1(config-if)#ip nat inside
R1(config-if)#int g0/0
R1(config-if)#ip nat outside
```

Now we have to define the IP addresses inside the network (inside local addresses), using **Access Control Lists (_ACL_)**. Typically ACLs are used to allow/deny traffic, but in this case, it's going to be used to recognize traffic. The hosts have to be identified with a **wild-card mask**.

```
R1(config)#access-list 1 permit 10.1.1.0 0.0.0.255
```

Once this is done, we have to define the inside global IP address pool. Here, `POOL` is the name of the address pool, `4.4.4.2` the starting IP address of the range and `4.4.4.3` the ending IP address of the range.

```
R1(config)#ip nat pool POOL 4.4.4.2 4.4.4.3 netmask 255.255.255.0
```

Now, we have an ACL that defines the inside local IPs and a pool that defines the inside Global IPs. So, we just have to tie these together. We can do so using:

```
R1(config)#ip nat inside source list 1 pool POOL
```

Now we should be able to ping the outside global server from both the clients:

```
cl1> ping 3.3.3.3
3.3.3.3 icmp_seq=1 timeout
3.3.3.3 icmp_seq=2 timeout
84 bytes from 3.3.3.3 icmp_seq=3 ttl=62 time=15.864 ms
84 bytes from 3.3.3.3 icmp_seq=4 ttl=62 time=11.414 ms
84 bytes from 3.3.3.3 icmp_seq=5 ttl=62 time=16.374 ms

cl2> ping 3.3.3.3
84 bytes from 3.3.3.3 icmp_seq=1 ttl=62 time=37.204 ms
84 bytes from 3.3.3.3 icmp_seq=2 ttl=62 time=14.384 ms
84 bytes from 3.3.3.3 icmp_seq=3 ttl=62 time=12.899 ms
84 bytes from 3.3.3.3 icmp_seq=4 ttl=62 time=12.403 ms
84 bytes from 3.3.3.3 icmp_seq=5 ttl=62 time=15.406 ms
```

Now, if we check the translations table, we can see:
```
R1#sh ip nat trans
Pro Inside global      Inside local       Outside local      Outside global
icmp 4.4.4.2:5107      10.1.1.101:5107    3.3.3.3:5107       3.3.3.3:5107
icmp 4.4.4.2:5619      10.1.1.101:5619    3.3.3.3:5619       3.3.3.3:5619
icmp 4.4.4.2:6131      10.1.1.101:6131    3.3.3.3:6131       3.3.3.3:6131
icmp 4.4.4.2:6387      10.1.1.101:6387    3.3.3.3:6387       3.3.3.3:6387
icmp 4.4.4.2:6643      10.1.1.101:6643    3.3.3.3:6643       3.3.3.3:6643
--- 4.4.4.2            10.1.1.101         ---                ---
icmp 4.4.4.3:7667      10.1.1.102:7667    3.3.3.3:7667       3.3.3.3:7667
icmp 4.4.4.3:7923      10.1.1.102:7923    3.3.3.3:7923       3.3.3.3:7923
icmp 4.4.4.3:8179      10.1.1.102:8179    3.3.3.3:8179       3.3.3.3:8179
icmp 4.4.4.3:8435      10.1.1.102:8435    3.3.3.3:8435       3.3.3.3:8435
icmp 4.4.4.3:8691      10.1.1.102:8691    3.3.3.3:8691       3.3.3.3:8691
--- 4.4.4.3            10.1.1.102         ---                ---
```

# Port Address Translatin / NAT Overloading
In some cases, especially in home networks, we may not have multiple global IPs available to form a pool. The single IP assigned to us by the ISP may be the only global IP, in which case we have to use PAT, where the IP address and the port number from the clients are used to form a unique socket to communicate with outside destination networks.

The limit to this method is the 16-bit size for the port number, thus allowing us only about 65000 flows for every inside global IP address. PAT is used when we have more inside local addresses than inside global addresses, and thus can support multiple inside global addresses.

Similar to dynamic NATing, we need to create an ACL to identify the inside addresses, after which we specify which outside interface will be used. However, if we were to stop here, only a single inside IP address would be allowed to NAT. Instead, we have to use the keyword **overload** to enable PAT.

```
R1(config)#ip nat inside source list 1 int g0/0 overload
```

After this, the NAT translation table will have a single inside global ip of `4.4.4.4`, but unique sockets. The table will look like:

```
R1#sh ip nat trans
Pro Inside global      Inside local       Outside local      Outside global
icmp 4.4.4.4:42606     10.1.1.101:42606   3.3.3.3:42606      3.3.3.3:42606
icmp 4.4.4.4:43118     10.1.1.101:43118   3.3.3.3:43118      3.3.3.3:43118
icmp 4.4.4.4:43630     10.1.1.101:43630   3.3.3.3:43630      3.3.3.3:43630
icmp 4.4.4.4:43886     10.1.1.101:43886   3.3.3.3:43886      3.3.3.3:43886
icmp 4.4.4.4:44142     10.1.1.101:44142   3.3.3.3:44142      3.3.3.3:44142
icmp 4.4.4.4:44910     10.1.1.102:44910   3.3.3.3:44910      3.3.3.3:44910
icmp 4.4.4.4:45166     10.1.1.102:45166   3.3.3.3:45166      3.3.3.3:45166
icmp 4.4.4.4:45422     10.1.1.102:45422   3.3.3.3:45422      3.3.3.3:45422
icmp 4.4.4.4:45678     10.1.1.102:45678   3.3.3.3:45678      3.3.3.3:45678
icmp 4.4.4.4:45934     10.1.1.102:45934   3.3.3.3:45934      3.3.3.3:45934
```

# NTP
**Network Time Protocol (_NTP_)** allows servers, routers, switches, etc. to synchronize their clocks. This helps us ensure that all events logged, perhaps in a syslog server, are all timestamped accurately and hence occured in the right order as displayed in the logs. This also helps us to co-relate events that occured simultaneously, like two devices failing.

It is also necessary since the validity of the digital certificates is heavily depedent upon time since they have expiration dates. If a Cisco router is set up to act as a Cisco Communications Manager Express router, where Cisco IP phones register, it's essential to have the right time since the phones themselves get their time from the router.

For all of these reason, we use NTP.
* It uses UDP to communicate on port 123 by default.
* Uses a **stratum level** that's acts like **AD** for routing protocols. It acts as a measure of the believability of a time source.  For example, highly accurate atomic clocks on the internet have a stratum level of **1**. If our router learns the time from it, it'll have a stratum level of _2_. If a switch learns from that router, it'll have a stratum level of _3_ and so on.
* Typically we set up NTP so that one of our devices gets the time from the internet and then acts as the NTP server for other devices on the network.

## NTP Configuration and Verification
Let us consider in the diagram, that NTP is an internet based NTP server, from which our router R1 gets the time and then shares it with the switch sw1 and router R2. First we have to set the time in NTP server since we're only pretending this is the internet based time authority. We do this using the `clock set` command:

```
NTP#clock set 10:02:00 15 Dec 2018
*Dec 15 10:02:00.001: %SYS-6-CLOCKUPDATE: System clock has been updated from 04:31:46 UTC Sat Dec 15 2018 to 10:02:00 UTC Sat Dec 15 2018, configured from console by console.
```
The default config assumes **UTC/GMT** is our time zone. To change the time zone, we have to do it from the global config mode. For this, we have to set up our own time zone with the difference in time specified. For example, we can set the timezone to IST (_UTC+5:30_) with the command:

```
NTP(config)#clock timezone IST 5 30
Dec 15 04:41:47.092: %SYS-6-CLOCKUPDATE: System clock has been updated from 04:41:47 UTC Sat Dec 15 2018 to 10:11:47 IST Sat Dec 15 2018, configured from console by console.
```

Now we can configure the router to act as the NTP master clock and specifying a stratum number (ex. _5_) - which just like ADs, have a higher priority/believability for lower numbers. _This step is only required after setting the time manually_.

```
NTP(config)#ntp master 5
```

## Loopback Interfaces
Generally, whenever we assign an IP address to a physical interface, if the interface's link goes down, so does the interface itself and the IP associated with it. What this means is, if we have an interface Gi0/0 that has a cable failure, then the interface will go down and the IP address assigned to it, for example, `192.168.0.1` will no longer be reachable. This is all well and good for connectivity management, but for protocols like NTP, it's critical that the IP address is available even when an interface's link may be lost. This is because we generally have redundant paths/links/routes through which a device is connected.

Consider the network below. It has two routers connected through two different links. If we have to telnet from R1 to R2, we can choose either of R2's interfaces. Let us assume `192.168.1.2` is our interface of choice, and not the one connected to the redundant link `192.168.2.2`. Now, if the link between **R1 Gi0/0** and **R2 Gi0/0**, i.e., the one between `192.168.1.1` and `192.168.1.2` were to go down, we'd be unable to ping `192.168.1.2` even though **R2 Gi0/1** and **R2 Gi0/1** still connect the routers.

A loopback interface is a set of special **virtual/logical interfaces that always stay up** unless we administratively shut them down. This means even in case of link failure, we don't risk losing connectivity. This is because the link will stay up and hence any dynamic routing protocol that's set to advertise the loopback network, will send an alternate path to the device in case of primary link failure. Loopback interfaces typically have a subnet mask length of 32 bits to signify they're the only device on the network and we can set up a loopback interface using:

```
NTP(config)#int loopback ?
  <0-2147483647>  Loopback interface number

NTP(config)#int loopback 1
Dec 15 05:16:40.294: %LINEPROTO-5-UPDOWN: Line protocol on Interface Loopback1, changed state to up
NTP(config-if)#ip addr 1.1.1.1 255.255.255.255
NTP(config-if)#do sh ip int br | i Loop       
Loopback1                  1.1.1.1         YES manual up                    up      
```

In the above case, if we had a loopback address, for ex., `1.1.1.1` on **R1** and `1.1.1.2` on **R2**, we could've still pinged R2 from R1 despite the link failure on Gi0/0 on R1 and R2.

## Pointing a device to a NTP Source
Let us assume that each router has it's own loopback address, with **NTP** having `1.1.1.1/32`, **R1** having `2.2.2.2/32` and **R2** having `3.3.3.3/32` as their loopback interfaces. The systems are also running RIPv2 with all routes advertised on all interfaces so that all routes, including the routes to the loopback interfaces are known by all the devices. So, we can finally point **NTP** as the NTP source for R2.

We have to first tell R1 to use `NTP` as the NTP server, and then also choose the appropriate time-zone. Let us consider that R1 follows IST.

```
R1(config)#ntp server 1.1.1.1
R1(config)#clock timezone IST 5 30
*Dec 15 06:26:19.710: %SYS-6-CLOCKUPDATE: System clock has been updated from 06:26:19 UTC Sat Dec 15 2018 to 11:56:19 IST Sat Dec 15 2018, configured from console by console.
```

Let us consider that the server **R2** follows EST, that also has daylight savings time. So, we also have to allow the router to follow DST when required. We want to point it to our local NTP server, which is **R1** on `2.2.2.2`.

```
R1(config)#ntp server 2.2.2.2
R1(config)#clock timezone EST -5
*Dec 15 06:26:19.710: %SYS-6-CLOCKUPDATE: System clock has been updated from 06:26:19 UTC Sat Dec 15 2018 to 01:29:03 EST Sat Dec 15 2018, configured from console by console.
R2(config)#clock summer-time EDT recurring
*Dec 15 06:29:03.857: %SYS-6-CLOCKUPDATE: System clock has been updated from 01:29:03 EST Sat Dec 15 2018 to 01:29:03 EST Sat Dec 15 2018, configured from console by console.
```

NTP can take several minutes in the real world to synchronize the clocks between the devices. We can now see the current device time using `show clock`:

```
R2#show clock
*01:31:30.048 EST Sat Dec 15 2018
```

We can see the NTP settings using:

```
R2#sh ntp associations

  address         ref clock       st   when   poll reach  delay  offset   disp
 ~2.2.2.2         1.1.1.1          6     20     64     0  0.000   0.000 15937.
 * sys.peer, # selected, + candidate, - outlyer, x falseticker, ~ configured
```

We can find the NTP settings of the current device using:

```
R1#sh ntp status
Clock is synchronized, stratum 6, reference is 1.1.1.1        
nominal freq is 1000.0003 Hz, actual freq is 999.5003 Hz, precision is 2**14
ntp uptime is 109600 (1/100 of seconds), resolution is 1001
reference time is DFBF20BA.C7C9596C (12:12:02.780 IST Sat Dec 15 2018)
clock offset is 127.0765 msec, root delay is 11.04 msec
root dispersion is 7976.26 msec, peer dispersion is 1938.24 msec
loopfilter state is 'CTRL' (Normal Controlled Loop), drift is 0.000499999 s/s
system poll interval is 64, last update was 147 sec ago.
```

# Network Management

# Cisco Discovery Protocol (_CDP_)
**Cisco Discovery Protocol (_CDP_)** is a Cisco proprietary Layer 2 protocol that is invaluable for monitoring and troubleshooting the network. Because of its layer 2 operation, it doesn't even need the devices to have IP addresses configured. It allows us to get information about its adjacent neighbours (i.e., directly connected devices) that speak CDP.

In the following topology, if we were to use the `show cdp neighbours` command on sw1, we'd see:
* R1
* sw2
* IP phone

But, we wouldn't see the Cisco Unified Communications Manager (CUCM) Server, even though it _does run CDP_ becuase it's not directly connected. The Laptop, however, wouldn't typically show up even if it were directly connected, since it won't have CDP running.

### MAC address Unicast, Broadcast and Multicast
We already know that the broadcast MAC address for any network/subnet will always be `FFFF.FFFF.FFFF`. However, there's a way to determine if the packet is a unicast or a multicast packet at layer 2 as well. This can be done by breaking down the first byte of the data in binary and checking if the **Least Significant Bit (_LSB_)** is _1_. If so, it's a multicast MAC address; if not, it's a unicast MAC address.

### CDP Operation
CDC sends advertisements on the multicast MAC address of `01-00-0c-cc-cc-cc`, to which the adjacent routers and switches belong. These devices can thus learn the advertisements. The CDP advertisements allows the neighbours to know in-depth information about the devices.

```
sw2#sh cdp neighbors
Capability Codes: R - Router, T - Trans Bridge, B - Source Route Bridge
                  S - Switch, H - Host, I - IGMP, r - Repeater, P - Phone,
                  D - Remote, C - CVTA, M - Two-port Mac Relay

Device ID        Local Intrfce     Holdtme    Capability  Platform  Port ID
sw1              Gig 0/0           171             R S I            Gig 0/0
sw3              Gig 0/2           177             R S I            Gig 0/2
sw3              Gig 0/1           170             R S I            Gig 0/1

Total cdp entries displayed : 3
```

We can get even more indepth information using:

```
sw2#sh cdp neighbors detail
-------------------------
Device ID: sw1
Entry address(es):
Platform: Cisco ,  Capabilities: Router Switch IGMP
Interface: GigabitEthernet0/0,  Port ID (outgoing port): GigabitEthernet0/0
Holdtime : 139 sec

Version :
Cisco IOS Software, vios_l2 Software (vios_l2-ADVENTERPRISEK9-M), Experimental Version 15.2(20170321:233949) [mmen 101]
Copyright (c) 1986-2017 by Cisco Systems, Inc.
Compiled Wed 22-Mar-17 08:38 by mmen

advertisement version: 2
VTP Management Domain: ''
Native VLAN: 1
Duplex: full

-------------------------
Device ID: sw3
Entry address(es):
Platform: Cisco ,  Capabilities: Router Switch IGMP
Interface: GigabitEthernet0/2,  Port ID (outgoing port): GigabitEthernet0/2
Holdtime : 145 sec

Version :
Cisco IOS Software, vios_l2 Software (vios_l2-ADVENTERPRISEK9-M), Experimental Version 15.2(20170321:233949) [mmen 101]
Copyright (c) 1986-2017 by Cisco Systems, Inc.
Compiled Wed 22-Mar-17 08:38 by mmen

advertisement version: 2
VTP Management Domain: ''
Native VLAN: 1
Duplex: full

-------------------------
Device ID: sw3
Entry address(es):
Platform: Cisco ,  Capabilities: Router Switch IGMP
Interface: GigabitEthernet0/1,  Port ID (outgoing port): GigabitEthernet0/1
Holdtime : 138 sec

Version :
Cisco IOS Software, vios_l2 Software (vios_l2-ADVENTERPRISEK9-M), Experimental Version 15.2(20170321:233949) [mmen 101]
Copyright (c) 1986-2017 by Cisco Systems, Inc.
Compiled Wed 22-Mar-17 08:38 by mmen

advertisement version: 2
VTP Management Domain: ''
Native VLAN: 1
Duplex: full


Total cdp entries displayed : 3
```

To get information about just a _single_ neighbour, we use:

```
sw2#sh cdp entry sw3
-------------------------
Device ID: sw3
Entry address(es):
Platform: Cisco ,  Capabilities: Router Switch IGMP
Interface: GigabitEthernet0/2,  Port ID (outgoing port): GigabitEthernet0/2
Holdtime : 148 sec

Version :
Cisco IOS Software, vios_l2 Software (vios_l2-ADVENTERPRISEK9-M), Experimental Version 15.2(20170321:233949) [mmen 101]
Copyright (c) 1986-2017 by Cisco Systems, Inc.
Compiled Wed 22-Mar-17 08:38 by mmen

advertisement version: 2
VTP Management Domain: ''
Native VLAN: 1
Duplex: full

-------------------------
Device ID: sw3
Entry address(es):
Platform: Cisco ,  Capabilities: Router Switch IGMP
Interface: GigabitEthernet0/1,  Port ID (outgoing port): GigabitEthernet0/1
Holdtime : 148 sec

Version :
Cisco IOS Software, vios_l2 Software (vios_l2-ADVENTERPRISEK9-M), Experimental Version 15.2(20170321:233949) [mmen 101]
Copyright (c) 1986-2017 by Cisco Systems, Inc.
Compiled Wed 22-Mar-17 08:38 by mmen

advertisement version: 2
VTP Management Domain: ''
Native VLAN: 1
Duplex: full
```

The CDP settings on the machine can be checked with the `show cdp` command. The _holdtime_ is the time after which if we haven't heard back from a host, we consider them disconnected.
```
sw2#sh cdp
Global CDP information:
        Sending CDP packets every 60 seconds
        Sending a holdtime value of 180 seconds
        Sending CDPv2 advertisements is  enabled
```

We can also get the CDP settings for a single interface using:

```
sw2#sh cdp int g0/1
GigabitEthernet0/1 is up, line protocol is up
  Encapsulation ARPA
  Sending CDP packets every 60 seconds
  Holdtime is 180 seconds
```

The CDP configurations are available in global configuration mode:

```
sw2(config)#cdp ?
  advertise-v2     CDP sends version-2 advertisements
  filter-tlv-list  Apply tlv-list globally
  holdtime         Specify the holdtime (in sec) to be sent in packets
  run              Enable CDP
  timer            Specify the rate at which CDP packets are sent (in sec)
  tlv              Enable exchange of specific tlv information
  tlv-list         Configure tlv-list
```

CDP can be turned off and on again, by:

```
sw2(config)#no cdp run
sw2(config)#cdp run
```

On some interfaces, we may be connected to another organization and might not want to send such indepth details about our own device. In such cases, we should turn the CDP off for that interface connecting to the 3rd party, using:

```
sw2(config-if)#no cdp enable
```

# Link Layer Discovery Protocol (_LLDP_)
LLDP (_802.1AB_) is an industry standard protocol that does a very similar job to CDP, but it's available for non-Cisco products. It lets us see information about our Layer 2 adjacent, i.e., physically connected devices. The **TLV (_Type-Length-Value_)** information contained within LLDP is more than that in CDP, thus making it more robust! Unlike CDP however, it doesn't have a fixed multicast address for advertisements. Instead, admins have to look out for the Organizationally Unique Identifier (OUI) of `01-80-c2`.

Unlike CDP, LLDP is generally not enabled by default on Cisco gear. To enable it, we use `lldp run` in global configuration mode.
Just like CDP, we can go into interface configuration modes and turn LLDP off for specific interfaces while still running it globally. To check the status of LLDP, and start it we use:

```
sw2(config)#do sh lldp
% LLDP is not enabled
sw2(config)#lldp run
sw2(config-if)#do sh lldp

Global LLDP Information:
    Status: ACTIVE
    LLDP advertisements are sent every 30 seconds
    LLDP hold time advertised is 120 seconds
    LLDP interface reinitialisation delay is 2 seconds
```

To turn off LLDP on a specific interface, we have to go into that interface's configuration mode and then choose to either turn of the transmission, receive or both for LLDP.

```
sw2(config-if)#int gi 0/1
sw2(config-if)#no lldp ?
  med-tlv-select  Selection of LLDP MED TLVs to send
  receive         Enable LLDP reception on interface
  tlv-select      Selection of LLDP TLVs to send
  transmit        Enable LLDP transmission on interface
sw2(config-if)#no lldp transmit
sw2(config-if)#no lldp receive
```

  We can also choose which parameters to advertise or not in the global config:

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

We can view the LLDP details using:

```
sw2#sh lldp neighbors
Capability codes:
    (R) Router, (B) Bridge, (T) Telephone, (C) DOCSIS Cable Device
    (W) WLAN Access Point, (P) Repeater, (S) Station, (O) Other

Device ID           Local Intf     Hold-time  Capability      Port ID
sw3                 Gi0/2          120        R               Gi0/2
sw1                 Gi0/0          120        R               Gi0/0

Total entries displayed: 2
```

To get a more detailed view, we use:

```
sw2#sh lldp neighbors detail
------------------------------------------------
Local Intf: Gi0/2
Chassis id: 0cee.ba83.0000
Port id: Gi0/2
Port Description: GigabitEthernet0/2
System Name: sw3

System Description:
Cisco IOS Software, vios_l2 Software (vios_l2-ADVENTERPRISEK9-M), Experimental Version 15.2(20170321:233949) [mmen 101]
Copyright (c) 1986-2017 by Cisco Systems, Inc.
Compiled Wed 22-Mar-17 08:38 by mmen

Time remaining: 103 seconds
System Capabilities: B,R
Enabled Capabilities: R
Management Addresses - not advertised
Auto Negotiation - not supported
Physical media capabilities - not advertised
Media Attachment Unit type - not advertised
Vlan ID: - not advertised

------------------------------------------------
Local Intf: Gi0/0
Chassis id: 0cee.ba36.5b00
Port id: Gi0/0
Port Description: GigabitEthernet0/0
System Name: sw1

System Description:
Cisco IOS Software, vios_l2 Software (vios_l2-ADVENTERPRISEK9-M), Experimental Version 15.2(20170321:233949) [mmen 101]
Copyright (c) 1986-2017 by Cisco Systems, Inc.
Compiled Wed 22-Mar-17 08:38 by mmen

Time remaining: 90 seconds
System Capabilities: B,R
Enabled Capabilities: R
Management Addresses - not advertised
Auto Negotiation - not supported
Physical media capabilities - not advertised
Media Attachment Unit type - not advertised
Vlan ID: - not advertised


Total entries displayed: 2
```

# Using CDP and LLDP to map a network
If all devices on the network are running CDP and they're interconnected and we're able to log in to each one, then we can use CDP to manually map out the entire network. This is only practical for small/medium sized networks, however, since larger networks would just have too many nodes for manual mapping. In such cases, a dedicated software to map out the network would be required.


# Device management
# Understanding a Router's Boot Sequence
