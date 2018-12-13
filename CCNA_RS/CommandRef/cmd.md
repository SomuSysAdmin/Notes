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
Many times, especially on home networks, the users don't have the luxury of multiple static global IP addresses. In such cases, the router WAN interface on the router gets the global IP and can also map specific ports to internal local IP addresses to have the data flow to multiple devices using a single external global IP. The PAT enabled router does this by paying attention to the port numbers on the router to which the internal devices communicate.

The combination of an IP address and a port number is called a **socket**. Thus, even though the IP address might not be unique while the data flows from the external server, the destination socket is always unique. 
