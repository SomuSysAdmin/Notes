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
