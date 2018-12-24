## Frame Relays
Frame relay is a layer 2 WAN technology that's a service provided by _Frame relay service providers_. It sends layer 2 frames over a **Private Virtual Circuit (_PVC_)** that are marked with **Data Link Connection Identifiers (_DLCI_s)** numbers (pronounced *del-Cs*). In modern days, it's used less given the popularity of cable modems and DSL connections - but in the past, these used to be the _go-to_ WAN technology for small-businesses, because it could provide a connection to the internet or other branch offices at a reasonable price compared to erstwhile leased lines. It uses DLCIs to form multiple Permanent Virtual Circuits (PVCs).

A **Virtual Circuit (_VC_)** is a logical connection between two endpoints. Thus, there could be multitple VCs over a single physical circuit (leading to the frame-relay service provider) when frame relay is used. A virtual circuit can be brought up on demand, in which case they're called **Switched Virtual Circuits (_SVC_s)** or have them installed permanently, called **Permanent Virtual Circuits (_PVC_)** - the latter being the case for frame-relay clouds. A **Data Link Connection Identifier (_DLCI_)** is a _locally-significant_ connection identifier. These are the **layer 2 addresses in the world of Frame-relay**. For example, in the figure below, the DLCI for the PVC to R2, R1 has a DLCI number of _102_. This however, doesn't match the DLCI of 201 on R2, because DLCIs are only relevant on the router on which they're defined.

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

To see which IP addresses are reachable over the available DLCIs, we use `show frame-relay map` command
