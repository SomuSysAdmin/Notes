# ICND1 Exercises
## VLANs
### 1. VLAN Config
A small business has an office in two floors, spread over 5 departments:
```
Floor	Dept_ID	Dept				Subnet
=======	=======	===================	===============
0		1		Reception			192.168.10.0/28
0		2		HR					192.168.20.0/24
0		3		Accounts			192.168.30.0/26
0		4		Sales				192.168.40.0/24
0		5		IT					192.168.50.0/24

1		3		Accounts			192.168.30.0/26
1		4		Sales				192.168.40.0/24
1		5		IT					192.168.50.0/24
```
Each floor has a switch connecting the two, terminating at a router in the ground floor IT department. Assign VLANs for each department corresponding to their Dept ID, which has a router as its gateway. Every department should be able to reach each other as well as the internet.
