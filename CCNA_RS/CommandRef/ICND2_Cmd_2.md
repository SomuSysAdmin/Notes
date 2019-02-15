<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Network Management](#network-management)
- [Network Management Protocols](#network-management-protocols)
- [Syslog Server](#syslog-server)
- [Syslog Configuration and Verification](#syslog-configuration-and-verification)
  - [Seeing logging messages and verifying config](#seeing-logging-messages-and-verifying-config)
  - [Fields in Syslog Messages](#fields-in-syslog-messages)
- [SNMP Operation](#snmp-operation)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Network Management
# Network Management Protocols
# Syslog Server
When a router/switch logs an event, it can forward these messages to an external syslog server. These may be events like an interface going down or a new neighbourship being formed over EIGRP. The various severity levels for a syslog server are:
```
Level Keyword   Level   Syslog Definition   Description                                 
=============   =====   =================   =================================           
emergencies     0       LOG_EMERG           System unstable, i.e., prone to failure     
alerts          1       LOG_ALERT           Immediate attention is needed
critical        2       LOG_CRIT            Critical conditions that need to be addressed to prevent loss of service, but not as serious as Alerts
errors          3       LOG_ERR             Error conditions that don't make the system unusable.                    
warnings        4       LOG_WARNING         Warning conditions for operations that failed to complete.                 
Notifications   5       LOG_NOTICE          Normal but significant condition like changes to a system.   
informational   6       LOG_INFO            Informational messages only about a normal system operation.        
debugging       7       LOG_DEBUG           Debugging messages which are verbose messages about the operation of the system.                  
```

Normally, level _7_ is way too verbose for logging all the time while level 0 is for emergencies. We typically want to log at something like level _4_, warnings. This of course means all previous levels, i.e., _level 0 to level 3_ are logged as well. Once configured, we get similar information on both the router's console as well as the syslog server.

# Syslog Configuration and Verification
Even before we configure the forwarding of messages to the syslog server, we can see the syslog messages while remotely logged in (via telnet/SSH) to the router/switch, by using the `terminal monitor` command in the privileged mode. To actually configure the forwarding to the syslog server , we need to use the `logging` command. We want to forward all syslog messages to an IP address, say `192.158.1.50`. We'd also like to specify the syslog level for which messages will be logged. For this we use:
```
R1(config)#logging 192.168.1.50
*Jan 19 15:01:24.380: %SYS-6-LOGGINGHOST_STARTSTOP: Logging to host 192.168.1.50 port 514 started - CLI initiated
R1(config)#logging trap ?
  <0-7>          Logging severity level
  alerts         Immediate action needed           (severity=1)
  critical       Critical conditions               (severity=2)
  debugging      Debugging messages                (severity=7)
  emergencies    System is unusable                (severity=0)
  errors         Error conditions                  (severity=3)
  informational  Informational messages            (severity=6)
  notifications  Normal but significant conditions (severity=5)
  warnings       Warning conditions                (severity=4)
  <cr>

R1(config)#logging trap notification
```

## Seeing logging messages and verifying config
We can use the `show logging` command to both verify our logging settings as well as see which messages have been logged already:
```
R1#sh logg
Syslog logging: enabled (0 messages dropped, 3 messages rate-limited, 0 flushes, 0 overruns, xml disabled, filtering disabled)
...
    Trap logging: level notifications, 37 message lines logged
        Logging to 192.168.1.50  (udp port 514, audit disabled,
              link up),
              2 message lines logged,
              0 message lines rate-limited,
              0 message lines dropped-by-MD,
              xml disabled, sequence number disabled
              filtering disabled
        Logging Source-Interface:       VRF Name:

Log Buffer (4096 bytes):

*Jan 19 15:00:33.368: %CTS-6-ENV_DATA_START_STATE: Environment Data Download in start state
*Jan 19 15:00:35.374: %LINEPROTO-5-UPDOWN: Line protocol on Interface VoIP-Null0, changed state to up
...
*Jan 19 15:01:24.380: %SYS-6-LOGGINGHOST_STARTSTOP: Logging to host 192.168.1.50 port 514 started - CLI initiated
*Jan 19 15:02:47.938: %SYS-5-CONFIG_I: Configured from console by console
```

## Fields in Syslog Messages
Syslog messages generated by Cisco devices are always in the format:
```
seq no:timestamp: %facility-severity-MNEMONIC:description
```

Each of these entities are called a _field_ in the syslog message. The different fields and their purpose are:
```
Field           Description
============    =============================================================================================================
seq no:         Syslog messages are by default stamped with a sequence number, to denote the order in which the messages were received by the server, but only if the `service sequence-numbers` command is used in the global configuration mode.
timestamp       Stamps the message with the date and time of the message or event. For this to work, we need to enable the `service timestamps log [datetime | log]` command in global configuration. formats: mm/dd hh:mm:ss or hh:mm:ss (short uptime) or d h (long uptime)
facility        A facility is the source/trigger for the syslog message (SNMP, SYS, etc). A facility can be a hardware device, a protocol, or a module of the system software.
severity        A number betwee 0 and 7 that represents the logging level.
MNEMONIC        A short, alpha-numeric code that uniquely describes the message.
description     Detailed information about the syslog event.
```

# SNMP Operation
SNMP is a protocol used to configure, monitor and receive alerts from managed network devices. The server that acts as the central point of operation for SNMP is called the **SNMP Manager**. The devices that it queries are called **SNMP Agents**, which may be a switch, a router, other servers, etc.

Inside each SNMP agent, there's a **Management Information Base (_MIB_)** which contains several **Object Identifiers(_OID_s)**. An object is a collection of variables contained within the MIB that the SNMP server can query and configure. While the SNMP manager can query these agents for the values of one or more OIDs, the agents may themselves send notifications proactively, called **SNMP Traps**, typically when certain thresholds are exceeded. An example will be a notification sent when the agent crosses a preset value of CPU/Memory utilization.

## SNMP Versions
1. SNMPv1 - Used *community strings* (like passwords) for community strings, which weren't secure.
2. SNMPv2c - Allowed a single query to retrieve more OIDs at once, thus reducing the number of queries required. Still used community strings. Still used in a lot of networks.
3. SNMPv3 - Much more secure since it supports authentication, integrity checks as well as encryption.

## SNMPv2 Configuration and Verification
