# General Networking Tools

This is an area for notes about general networking tools and utilities, with quick notes and example commands

## Basic Network Commands

- Standard network interface details: `ip addr show` and `ifconfig` (obsolete)
- Network Manager Cli: `nmcli` - shows DNS details and default route. `nmcli device show` will provide more comprehensive list 
  - List IPv4 IP address and gateway: `nmcli device show | grep 172 | egrep '^IP4.G|^IP4.A'`
- Route information: `ip route show` - this will show the default route
- Detailed route tabl: `routel`
- Show IP neighbours (ARP table): `ip n`

## DNS

- Dig (part of the `bind-utils` package for Centos)
  - Show the query/answer of a DNS request: `dig -4 www.linuxacademy.com`
  - Show the query/answer plus trace: `dig -4 www.linuxacademy.com +trace`
  
## DHCP

**Note:** commands may vary depending on *nix flavour in use but you can usually tab-complete from `/var/lib/dhc->` to find the right one. 

- DHCP request and offers are layer 2 broadcasts (similar to ARP requests) and need a DHCP client.
- DHCP server uses UDP 67 and client uses UDP 68
- Lookup the DHCP host: `cat /var/log/messages | grep "DHCPOFFER"` (or `cat /var/log/* | grep "DHCPOFFER"` if messages logs are rotating more frequently than DHCP offers).
- View lease information: `cat /var/lib/dhclient/dhclient--eth0.lease`
- View listening client: `sudo ss -luntp | grep dhclient` (switches: "listening", "udp", "numeric (don't resolve)", "tcp", "processes")

### Release IP address

- Release IPL `sudo dhclient -r`
- Restart DHCP Client: `sudo dhclient`

## Setting Static IP

- Check connection number using `nmcli`
- Run `sudo nmcli connection modify System\ ens5 ipv4.method manual ipv4.address <NEW_IP/CIDR> ipv4.gateway <GW_IP>>`. This won't change anything, need to restart the interface
- Bring interface down and up: `sudo nmcli connection down System\ ens5` and `sudo nmcli connection up System\ ens5` (can also use `systemctl restart network`)
- Add DNS server to interface properties: `sudo nmcli connection modify System\ ens5 ipv4.dns <DNS_IP>` (followed by interface restart as above)
- Change it back to DHCP: `sudo nmcli connection modify System\ ens5 ipv4.method auto ipv4.address "" ipv4.dns "" ipv4.gateway ""` (followed by interface restart as above)

### Adding additional IPs

- `sudo nmcli connection modify System\ ens5 ipv4.address <IP_ADD/CIDR>, <IP_ADD/CIDR>`. This will add 2 new IPs. They will rely upon GW/DNS settings from previous settings (whether it be DHCP or manual) in order to work. Assuming these settings are all correct, the new IPs will be pingable.
- Bring interface down and up: `sudo nmcli connection down System\ ens5` and `sudo nmcli connection up System\ ens5`

## Bonding

Assuming you have 2 cards setup already. 

- Create bond: `sudo nmcli connection add type bond con-name bond0 ifname bond0 mode active-backup ip4 <NEW_IP_ADD/CIDR`
- View newly created interface: `nmcli c`.
- Add interfaces to bond: `sudo nmcli connection add type bond-slave ifname ens5 master bond0` and `sudo nmcli connection add type bond-slave -ifname ens6 master bond0`.
- Bring the new bond-slave interfaces up: `sudo nmcli connection up bond-slave-ens5` and `sudo nmcli connection up bond-slave-ens6`
- Check the details of the bond interface: `nmcli devices show bond0` - notice that the gateway is missing.
- Add gateway to bond0 interface: `sudo nm connection modify bond0 ipv4.gateway <GW_IP>`
- Restart the bond interface: `sudo nmcli connection down bond0 && sudo nmcli connection up bond0`

## Teaming

- Need to use `teamd` so install: `yum install -y teamd bash-completion` and reload profile to enable `bash-completion`
- View network connections: `nmcli c`
- If you want to delete the connections to the interfaces using NetworkManager: `sudo nmcli connection delete Name\ of\ connection\ 1`
- Create team connection: `sudo nmcli connection add type team con-name Team0 ifname team0 team.config '{"runner":{"name": "activebackup"}, "link_watch": {"name": "ethtool"}}'
- **Note:** Check teamd's example configs: `cat /usr/share/doc/teamd-<version>/example_configs/<list_of_configs>`
- Add slave interfaces: `sudo nmcli connection add type team-slave con-name slave1 ifname eth1 master team0` and a second slave interface: `sudo nmcli connection add type team-slave con-name slave2 ifname eth2 master team0`
- Add settings to the team interface: `sudo nmcli connection modify Team0 ipv4.addresses <IP_ADD/CIDR> ipv4.gateway <GW_IP> ipv4.method manual`
- Confirm settings are expected: `nmcli connection show | grep ipv4`
- Bring slaves up, then team: `sudo nmcli con up slave1 && sudo nmcli con up slave2` and then the team interface: `sudo nmcli con up Team0`
- Check state of team interface using teamd: `teamdctl team0 state`
- If we wanted to use round robin runner, create the team interface in the same way but don't specify a team.config. Round robin is the default. Confirm this using the above `teamdctl` command. 
