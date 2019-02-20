# VRF (_Virtual Routing and Forwarding_)
VRFs carve up the existing network into separate, unconnected network at layer 3, by diving the IP routing table into separate virtual routing tables.

### VRF config
To create the VRF for two separate customers, CxA and CxB, we use:
```
Core1(config)#vrf definition vrf-CxA
Core1(config-vrf)#description VRF for Cust B
Core1(config-vrf)#address-family ipv4
Core1(config-vrf-af)#exit
Core1(config-vrf)#exit

Core1(config)#vrf definition vrf-CxB
Core1(config-vrf)#description VRF for Cust B
Core1(config-vrf)#address-family ipv4
```

We don't define the interfaces first since the moment we add an interface to a VRF, the existing configuration of that interface is erased. Now we add the interfaces:
```
Core1(config)#int g0/0
Core1(config-if)#vrf forwarding vrf-CxA
Core1(config-if)#ip addr 10.254.254.1 255.255.255.252
Core1(config-if)#no shut

Core1(config)#int g0/0
Core1(config-if)#vrf forwarding vrf-CxB
Core1(config-if)#ip addr 10.254.254.1 255.255.255.252
Core1(config-if)#no shut
```

To see the routes in each VRF, we have to specify the VRF as well:
```
Core1#sh ip route
...
      1.0.0.0/32 is subnetted, 1 subnets
C        1.1.1.1 is directly connected, Loopback0
      8.0.0.0/8 is variably subnetted, 2 subnets, 2 masks
C        8.8.8.0/24 is directly connected, GigabitEthernet0/2
L        8.8.8.1/32 is directly connected, GigabitEthernet0/2

Core1#sh ip route vrf vrf-CxA
...
      10.0.0.0/8 is variably subnetted, 2 subnets, 2 masks
C        10.254.254.0/30 is directly connected, GigabitEthernet0/0
L        10.254.254.1/32 is directly connected, GigabitEthernet0/0

Core1#sh ip route vrf vrf-CxB
...
      10.0.0.0/8 is variably subnetted, 2 subnets, 2 masks
C        10.254.254.4/30 is directly connected, GigabitEthernet0/1
L        10.254.254.5/32 is directly connected, GigabitEthernet0/1
```

To ping neighbours in a VRF, we need to mention to VRF:
```
Core1#ping 10.254.254.2
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.254.254.2, timeout is 2 seconds:
.....
Success rate is 0 percent (0/5)
Core1#ping vrf vrf-CxA 10.254.254.2
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.254.254.2, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 5/6/8 ms
```

By design, neighbours in one VRF can't ping another:
```
Core1#ping vrf vrf-CxA 10.254.254.6
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.254.254.6, timeout is 2 seconds:
.....
Success rate is 0 percent (0/5)
Core1#ping vrf vrf-CxB 10.254.254.6
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.254.254.6, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 5/6/9 ms
```
