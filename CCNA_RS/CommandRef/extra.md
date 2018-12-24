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
PVC Statistics for interface Serial2/0 (Frame Relay DTE)

              Active     Inactive      Deleted       Static
  Local          0            0            0            0
  Switched       0            0            0            0
  Unused         2            0            0            0

DLCI = 203, DLCI USAGE = UNUSED, PVC STATUS = ACTIVE, INTERFACE = Serial2/0

  input pkts 0             output pkts 0            in bytes 0
  out bytes 0              dropped pkts 0           in pkts dropped 0
  out pkts dropped 0                out bytes dropped 0
  in FECN pkts 0           in BECN pkts 0           out FECN pkts 0
  out BECN pkts 0          in DE pkts 0             out DE pkts 0
  out bcast pkts 0         out bcast bytes 0
  5 minute input rate 0 bits/sec, 0 packets/sec
  5 minute output rate 0 bits/sec, 0 packets/sec
  pvc create time 00:00:28, last time pvc status changed 00:00:28

DLCI = 204, DLCI USAGE = UNUSED, PVC STATUS = ACTIVE, INTERFACE = Serial2/0

  input pkts 0             output pkts 0            in bytes 0
  out bytes 0              dropped pkts 0           in pkts dropped 0
  out pkts dropped 0                out bytes dropped 0
  in FECN pkts 0           in BECN pkts 0           out FECN pkts 0
  out BECN pkts 0          in DE pkts 0             out DE pkts 0
  out bcast pkts 0         out bcast bytes 0
  5 minute input rate 0 bits/sec, 0 packets/sec
  5 minute output rate 0 bits/sec, 0 packets/sec
  pvc create time 00:00:28, last time pvc status changed 00:00:28
```
We see that the frame-relay knows about the DLCIs `203` and `204` configured for R1 on the frame-relay switch. We also see that both PVCs have a status of `ACTIVE` which indicates that the connection between both routers on either side of the frame relay cloud is okay, and also that we're exchanging LMI information between our router and the service provider's frame relay switch. Some of the possible PVC statuses are:
```
PVC Status  Meaning
=========== ==============================================================================================================================================
Active      Connection is okay between our router and the far-end router
Inactive    Connection between our router and SP's frame relay switch is okay, but not the connection between the SP's router and the far-end router.
Deleted     Connection is not okay between our router and the SP's frame relay switch.
```

To see which IP addresses are reachable over the available DLCIs, we use `show frame-relay map` command:
