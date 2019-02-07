1. View how we're connected to the switch           `show line`
2. Enter privileged mode                            `enable`
3. Exit privileged mode                             `disable`
4. Enter line configuration mode                    `conf t`
5. Exit current configuration mode                  `exit`
6. Exit all configuration mode                      `end`
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
10. Show running configuration                  `sh run`
11. Ping an IP                                  `ping 192.168.0.1`
12. See which input transports are allowed      `sh line vty 0`
13. Allow telnet and SSH as transport
```
sw1(config)#line vty 0 6
sw1(config-line)#transport input telnet ssh
```
14. Login via telnet                            `sw2>telnet 192.168.1.11`
15. Show history buffer                         `sh history`
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
20. Show device version                         `sh ver`
21. View running configuration                  `sh run`
22. View saved configuration                    `sh start`
23. Setting device hostname                     `sw(config)#hostname sw1`
24. Setting enable password                     `sw1(config)#enable password cisco`
25. Setting enable encrypted hash               `sw1(config)#enable secret somu`
26. Setting exec timeout                        `sw1(config-line)#exec-timeout 5 30`
27. Setting sync logging                        `sw1(config-line)#logg syn`
28. Setting terminal length                     `sw1(config-line)#len 36`
29. Encrypting passwords                            `sw1(config)#service password-encryption`
30. Creating user with privilege level              `sw1(config)#username somu privilege 15 password cisco`
31. Creating user with hash                         `sw1(config)#username somu privilege 15 algorithm-type scrypt secret cisco`
32. Removing user                                   `sw1(config)#no username somu`
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
34. Disabling Auto Negotiation					`no negotiation auto`
35. Specifying speed                            `sw1(config-if)#speed 100`
36. Specifying duplex                           `sw1(config-if)#duplex full`
37. Save configuration							`copy run start` OR `wr`


## Swtich specific
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




### VTP
1. Set VTP mode to server       `sw1(config)#vtp mode server`
2. Set VTP mode to client       `sw1(config)#vtp mode client`
3. Set VTP domain name          `sw1(config)#vtp domain VTPDEMO`
4. Set VTP password             `sw1(config)#vtp password S3cret`
5. Check VTP Status             `sw1#sh vtp status`
6. Reset VTP CRN            
```
sw1(config)#vtp mode transparent
sw1(config)#vtp mode server
```
