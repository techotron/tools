# Cheatsheet for troubleshooting Linux instances

## Requirements
Some of the below mentioned tools require the `sysstat` package to be installed. This can be checked with `rpm -qa | grep sysstat` or `apt -qq list sysstat`. 

## Methods
### USE (Utilisation, Saturation, Errors)
* [Brendan Gregg's blog on the USE method](https://www.brendangregg.com/usemethod.html)

#### Summary

For analysing performance issues and aims to provide a sense of direction when looking at performance issues on a server. Split resources out into components (eg for a server: CPUs, memory, disks) and for each of those, check for utilisation, saturation and errors. These are defined as:
- Utilisation: average time that the resource was busy serving work
- Saturation: the degree to which the resource has extra work which is queued
- Errors: the count of errors relating to the resource

##### Gotchas
- Be aware that metrics which are averaged over time could miss a bursty load. Eg, something which is saturating the CPU at a couple of a seconds at a time could get missed in minute long average metrics for CPU load.

##### Generic Resource List
- CPUs: sockets, cores, hardware threads (virtual CPUs)
- Memory: capacity
- Network interfaces
- Storage devices: I/O, capacity
- Controllers: storage, network cards
- Interconnects: CPUs, memory, I/O

##### Metrics
The following table outlines what metrics to look for per resource, per type:

|Resource|Type|Metric|
|---|---|---|
|CPU|Utilisation|CPU utilisation (either per-CPU or a system-wide average)|
|CPU|Saturation|run-queue length or scheduler latency|
|Memory Capacity|Utilisation|available free memory (system-wide)|
|Memory Capacity|Saturation|anonymous paging or thread swapping (maybe "page scanning" too)|
|Network Interface|Utilisation|RX/TX throughput / max bandwidth|
|Storage device I/O|Utilisation|device busy percent|
|Storage device I/O|Saturation|wait queue length|
|Storage device I/O|Errors|device errors ("soft", "hard", ...)|
|Thread Pools|Utilisation|time threads were busy processing work|
|Thread Pools|Saturation|number of requests waiting to be serviced by the threadpool|

**Note** Details on the commands to use to get this information are detailed below

##### Interpretations
**Utilisation**
- 100% is usually a sign of a bottleneck. Checking if the resource is saturated will confirm this.
- 70%+ can begin to be a problem for a couple of reasons:
  - An averaged utilisation metric which is sitting around at 70% can hide short bursts of utilisation to 100%
  - Some resources (eg disks) can't be interupted for higher priority work, therefore queuing delays (saturation) can begin to build.

**Saturation**
- Any degree of saturation can be a problem as it means things are waiting to be serviced

**Errors**
- Any errors are worth investigating

## Categories
### OS General
- OS details: `uname -a` (Kernal and distribution: `uname -srm`)
- `uptime` will provide the load (sum) averages in 1, 5 and 15 minute constants. The numbers include processes wanting to run on a CPU as well as processes blocked in uninterruptible I/O (usually disk I/O). 
They show the running thread (task) demand on the system plus waiting threads. You can also use `cat /proc/loadavg` to see these stats. If the values are higher than your CPU count, then you might have a performance problem. 
- Check CPU info: `cat /proc/cpuinfo`
- Disk space on file system (human readable numbers): `df -h`
- Size of directories (max depth of 1) with sort: `du -mh --max-depth 1 | sort -h`

#### Filtering
##### `grep|egrep`
- Match "error" (case insensitive): `grep -i error`
- Match on multiple strings, `ERROR` or `WARNING` (case sensitive): `egrep "ERROR|WARNING"`
- Match "error" or "warning" but ignore strings with `eddys`: `grep -iE "error|warning" | grep -vi "eddys"`
- Match a GUID: `egrep '[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}'`
- Match a GUID using **grep**: `grep -r -E '[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}'`
- Regex match MAC address (multiple formats as per below): 
```bash
ip neighbour show | egrep '((([0-9a-fA-F]{2})[ :-]){5}[0-9a-fA-F]{2})|(([0-9a-fA-F]){6}[:-]([0-9a-fA-F]){6})|([0-9a-fA-F]{12})'
```

MAC formats this will match:
> F3 D3 A4 C1 99 E2<br>
F3:D3:A4:C1:99:E2<br>
F3-D3-A4-C1-99-E2<br>
f3 d3 a4 c1 99 e2<br>
f3:d3:a4:c1:99:e2<br>
f3-d3-a4-c1-99-e2<br>
f3d3a4 c199e2<br>
f3d3a4:c199e2<br>
f3d3a4-c199e2<br>
f3d3a4c199e2<br>
F3D3A4C199E2

##### `awk`
- Print all columns: `awk '{print $0}' /var/log/file.log`
- Print all but the first column: `awk '{$1=""; print $0}' /var/log/file.log`
- Print all but the first 2 columns: `awk '{$1=$2=""; print $0}' /var/log/file.log`

#### `jq`
Format and filter JSON output
- Select key and output values as a table to stdout:
```bash
cat file.json | jq -r '.deployments[] | "\(.applicationName) \(.region) \(.networkConfig)"'
```
**Note:** The `-r` paramter will output the raw string (ie, no quotes, square or curly braces)

- Filter on value of key example:
```bash
aws iam list-roles | jq '.Roles[] | select(.RoleName == "my-role-name")'
```
- Filter on value of key example with "or" operator:
```bash
aws iam list-roles | jq '.Roles[] | select(.RoleName == "my-role-name" or .RoleName == "another-role-name")'
```
- Filter with "contains" operator (example from a cloudtrail log):
```bash
cat event_history.json | jq '.Records[] | select(.eventName | contains("DeleteQueue")) | select(.requestParameters.queueUrl | contains("some-queue-name"))'
```

#### Misc
**`watch`**
- Run <SOME_COMMAND> every 2 seconds and update the shell: `watch -n 2 <SOME_COMMAND>`

**`Loops`**
- A 'for loop' one liner example: `for r in one two; do echo $r; done`

**`Here String`**
- Write out to a file on the command line using a here string:

```bash
cat > file.txt << EOF
this is a multi-line
file
something else here.
EOF
```
**`Unzip and Extract`**:
- Unzip and extract a `*.tar.gz` file: `tar -xvzf file.tar.gz`
  - x (extract files)
  - v (verbose)
  - z (decompress)
  - f (specify filename)
- Replace text with `sed`:
  - Replace first instance of `string` to `replacement` to stdout: `sed 's/string/replacement/' file.txt`
  - Replace all instances of `string` to `replacement` to stdout: `sed 's/string/replacement/g' file.txt`
  - Replace instances of `string` to `replacement` **on the 3rd line** to stdout: `sed '3 s/string/replacement/' file.txt`
  - Delete 5th line in `file.txt`: `sed '5d' file.txt`
  - Delete last line in `file.txt`: `sed '$d' file.txt`
  - Delete range 3 - 7 of lines in `file.txt`: `sed '3, 7' file.txt`

**`Locating Files`**
- Find `*.log` files in **/var/**: `find /var/ -name "*.log"`
- Find `*.log` files in **/var/** (including symbolic links): `find -L /var/ -name "*.log"`
- Look for files in **/var/** which contain **error|warning**, print the path and matching lines: `find /var/ -name "*.log" -exec grep -i -E "error|warning" '{}' \; -print`
- Same as above but any of type "file": `find /var/ -type f -exec grep -i -E "error|warning" '{}' \; -print`

**`curl`**
TODO ======================================================================================================
get and post with headers
output to file 
download
**`wget`**
TODO ======================================================================================================
download to file

### Security
TODO ======================================================================================================
permissions
openssl
selinux
iptables

### Logs
Common log locations:

|Log Location|Contents|
|---|---|
|/var/log/messages|General message and system related stuff|
|/var/log/auth.log|Authenication logs|
|/var/log/kern.log|Kernel logs|
|/var/log/cron.log|Crond logs (cron job)|
|/var/log/maillog|Mail server logs|
|/var/log/qmail/|Qmail log directory (more files inside this directory)|
|/var/log/httpd/|Apache access and error logs directory|
|/var/log/lighttpd/|Lighttpd access and error logs directory|
|/var/log/nginx/|Nginx access and error logs directory|
|/var/log/apt/|Apt/apt-get command history and logs directory|
|/var/log/boot.log|System boot log|
|/var/log/mysqld.log|MySQL database server log file|
|/var/log/secure or /var/log/auth.log|Authentication log|
|/var/log/utmp or /var/log/wtmp|Login records file|
|/var/log/yum.log or /var/log/dnf.log|Yum/Dnf command log file.|

**Note** The above logs are generated by the `rsyslogd` service. 

- Display kernal ring buffer: `dmesg` (with errors, warnings or failed messages): `dmesg | grep -i -E 'error|warn|failed'`
**Note** Logs from system startup appear in the ring buffer until the syslog daemon gets a chance to startup and collect them. The contents also gets saved to /var/log/dmesg once the syslog daemon starts up.

- Docker logs: (there are a few locations depending on the distro):
  - **Ubuntu** (using systemd): `journalctl -fu docker.service`
  - **Amazon Linux**: `/var/log/docker`
  - **OSX**: `~/Library/Containers/com.docker.docker/Data/com.docker.driver.amd64-linux/log/d‌​ocker.log`
  - **Deb**: `/var/log/daemon.log`
  - **CentOS**: `/var/log/message | grep docker` or `journalctl -u docker.service`

#### `journalctl`
This is a more recent utility to view logs generated by `systemd-journald`. `systemd-journald` collects and stores logging data and creates and maintains structured, indexed journals based on logging information recieved from various sources such as Kernel log messages via kmsg. The data is stored in binary format, therefore the `journalctl` utility is required to read the logs.

- Show all logs: `journalctl`
- View all boot messages: `journalctl -b`
- View all boot messages from _previous_ boot: `journalctl -k -b -1`
- Filter by system service: `journalctl -u nginx.service`
- Filter with multiple services: `journalctl -u apache.service -u mysqld.service`
- Follow logs in realtime: `journalctl -f -u nginx.service`
- Show the last 10 log lines: `journalctl -n 10 -u nginx.service`
- Show logs since 30 mins ago: `journalctl --since "30 min ago"`
- Show logs since 1 days ago for the docker service: `journalctl --since "1 days ago" -u docker.service`
- View log by PID 1234: `journalctl _PID=1234`
- Reverse output (newest first): `journalctl -r -u docker.service`
- Show Linux Kernal messages: `journalctl -k`
- Filter with grep like syntax: `journalctl -u docker.service -g "warning|error|fail"`

**Note:** Patterns are matched as case _insensitive_ by default. Override this with `--case-sensitive`

### Load

#### General
TODO ======================================================================================================
top
htop

#### CPU
`vmstat 1` - short for virtual memory stat will print a summary of key server statistics on each line for (1) second, eg:

```bash
procs -----------memory---------- ---swap-- -----io---- --system-- -----cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 0  0      0 122008 148020 941064    0    0     3    54   54  121  4  1 95  0  0
 0  0      0 121992 148020 941088    0    0     0     0  391  975  0  0 100  0  0
 0  0      0 121992 148020 941096    0    0     0    60  391  957  0  0 100  0  0
 0  0      0 121992 148020 941096    0    0     0    56  381  936  0  0 100  0  0
 0  0      0 121992 148020 941096    0    0     0     0  360  924  0  0 100  0  0
```

Columns to check:
- **r**: Number of processes running on CPU and waiting for a turn. A value greater than CPU count is saturation.
- **free**: Free memory in kilobytes.
- **si**, **so**: Swap-ins and swap-outs. If these are not zero (ie, swap space is being used), you're out of memory.
- **us**, **sy**, **id**, **wa**, **st**: User time (application), system time (kernel), idle, wait I/O and stolen time. The system is busy if `us` + `sy` is high. A constant degree of `wa` points towards a disk bottleneck (when `id` is high because tasks are waiting for disk I/O). System time is necessary for I/O processing, an average of 20% might be worth exploring further.

---

`mpstat -P ALL 1` - prints the CPU time breakdown per CPU. Use this to check for an imbalance. A single hot CPU can be evidence of a single-threaded application. Example output: 

```bash
14:36:16     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest   %idle
14:36:17     all   14.29    0.00    3.06    0.00    0.00    0.00    0.00    0.00   82.65
14:36:17       0   14.29    0.00    3.06    0.00    0.00    0.00    0.00    0.00   82.65
```

---

`pidstat 1` - prints a rolling summary per process. The CPU column is the percentage per CPU, so a value of 380.00 would indicate the process was consuming almost 4 CPUs.

Example output:

```bash
14:38:01          PID    %usr %system  %guest    %CPU   CPU  Command
14:38:02            7    0.00    0.91    0.00    0.91     0  rcu_sched
14:38:02         2599    0.00    0.91    0.00    0.91     0  god
14:38:02         4466    0.91    0.00    0.00    0.91     0  aws

14:38:02          PID    %usr %system  %guest    %CPU   CPU  Command
14:38:03         4466    1.03    0.00    0.00    1.03     0  aws
14:38:03        30026    3.09    0.00    0.00    3.09     0  java
```


#### IO
`iostat -xz 1` - workload and performance for block devices. Columns to watch:

Example output: 

```bash
avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           3.98    0.23    0.59    0.17    0.30   94.72

Device:         rrqm/s   wrqm/s     r/s     w/s   rsec/s   wsec/s avgrq-sz avgqu-sz   await  svctm  %util
xvda              0.00     4.42    0.19    3.72     5.27   107.74    28.93     0.01    3.62   0.52   0.20
```

- **r/s**, **w/s**, **rkB/s**, **wkB/s**: The delivered reads, writes, read Kbytes and write Kbytes per second. This can be used for workload characterisation. 
- **await**: The average time for the I/O in milliseconds. This is the time that the application suffers as it includes time queued and time being serviced. Larger than average times can be an evidence of saturation.
- **avgqu-sz**: The average number of requests issued to the device. Greater than 1 typically indicates saturation. 
- **%util**: Device utilisation. The time each second that the device was doing work. Values greater than 60% typically lead to poor performance.

**Note:** If the device is a logical disk fronting many back-end disks then 100% utilisation may mean that some I/O is being processed 100% of the time so it doing necessarily indicate saturation.

High I/O isn't always an application issue. It depends if it's written to not be blocked by I/O latencies (eg by using read-ahead for reads and buffering for writes).

---

`free -m`

Example output:

```bash
             total       used       free     shared    buffers     cached
Mem:          2003       1652        350          0         95        763
-/+ buffers/cache:        793       1210
Swap:            0          0          0
```

- **buffers**: Buffer cache, used for block device I/O (in Mbytes)
- **cached**: Page cache, used by file systems (in Mbytes)

It can lead to higher disk I/O if these are near zero. 

- **-/+ buffers/cache**: Linux uses free memory for the disk caches but can reclaim it quickly if applications need it. This line is the result of the used memory, minus the sum of memory allocated to buffers and cached.

#### Network
`sar -n DEV 1` - Check network interface throughput (rxkB/s and txkB/s) as a measure of workload. Get the interface speed with `ethtool INTNAME`. With Amazon EC2 instances, check [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/general-purpose-instances.html#general-purpose-network-performance) for the performance.

Example output:

```bash
16:53:51        IFACE   rxpck/s   txpck/s    rxkB/s    txkB/s   rxcmp/s   txcmp/s  rxmcst/s
16:53:52           lo      3.06      3.06      0.19      0.19      0.00      0.00      0.00
16:53:52         eth0      2.04      2.04      0.08      0.69      0.00      0.00      0.00
```

In this example, the recieve and transmit values are pretty unburdening.

---

`sar -n TCP,ETCP 1` is a summarised view of key TCP metrics.

Example output:

```bash
11:41:54     active/s passive/s    iseg/s    oseg/s
11:41:55         0.00      0.00     11.34     12.37

11:41:54     atmptf/s  estres/s retrans/s isegerr/s   orsts/s
11:41:55         0.00      0.00      0.00      0.00      0.00
```

- **active/s**: Number of locally-initiated TCP connections per second (via connect())
- **passive/s**: Number of remotely-initiated TCP connections per second (via accept())
- **retrans/s**: Number of TCP retransmits per second

The active and passive counts are a rough indication of server load. Passive ~new accepted connections. Active ~Downstream connections. Helpful to think of passive as inbound connections and active as outbound (but not always true).

Retransmits are a sign of network or server issue. Could be unrelieable network or overloaded server dropping packets.

---

`sar -n SOCK` lists stats relating to sockets on the host

```bash
08:55:13 AM       LINUX RESTART

09:00:01 AM    totsck    tcpsck    udpsck    rawsck   ip-frag    tcp-tw
09:10:01 AM       261         9         4         0         0         0
09:20:01 AM       262         9         4         0         0         1
09:30:01 AM       259         7         4         0         0         0
09:40:01 AM       260         7         4         0         0         2
09:50:01 AM       260         7         4         0         0         2
10:00:01 AM       269        14         5         0         0     16141
10:10:01 AM       271        14         5         0         0     16156
10:20:01 AM       271        13         4         0         0     15585
10:30:01 AM       262         9         4         0         0     15842
10:40:01 AM       274        14         4         0         0     16108
10:50:01 AM       265         8         4         0         0      9065
11:00:01 AM       265         8         4         0         0         0
11:10:01 AM       265         8         4         0         0         0
11:20:01 AM       270        10         4         0         0         0
11:30:01 AM       270        10         4         0         0         0
11:40:01 AM       299        26         4         0         0     15646
11:50:01 AM       295        22         4         0         0     14960
12:00:01 PM       281        13         5         0         0     15800
12:10:01 PM       284        15         5         0         0     16384
12:20:01 PM       285        16         5         0         0     15817
12:30:01 PM       267         8         4         0         0         0
12:40:01 PM       272        10         4         0         0         0
Average:          271        12         4         0         0      7614
```

---

`ss -n -o state time-wait` will list the number of connections in a TIME_WAIT state. This can be useful if there is a build up of connections in a TIME_WAIT state. Use with `| wc -l` to get a count of the connections (although this information can already be seen with `sar -n SOCK`)

The following `ss` command will list the unique quadruplets (sport, saddress, dport, daddress). This can be helpful to confirm if the number of TIME_WAIT connections marries up with the limitations of the TCP configuration

`ss -o state time-wait -tan 'dport = :80' | awk '{print $(NF-1)" "$(NF-2)}' | sed 's/:[^ ]*//g' | sort | uniq -c`

### Networking
TODO ======================================================================================================
iptables (nat)
nmap
tcpdump

#### Sockets
Netcat (`nc`) can be used to run port scans and listen on ports to check for connectivity
- Port scan: `nc -z -v sre-resources.esnow.uk 443`
- Listen on specified port: `nc -l -p 5000`
- Ad-hoc web server: `printf ‘HTTP/1.1 200 OK\n\n%s’ “$(cat index.html)” | netcat -l -k -p 8080`
- Transfer a file (this will send the contents of a file to the specified host/port): `nc HOSTNAME PORT < file.log`
**Note:** File transfer can be used for sending log files to logstash on the fly, without using a log agent.

---

`lsof -n -a -i4 -a -P` will list open ports on the host 
- `-n`: Don't resolve IPs to hostnames
- `-a`: AND operator
- `-i4`: Match IPv4 addresses
- `-P`: Don't resolve port numbers to network files

#### Routing
- Displaying the routing table: `ip route list`
- Display the arp table: `ip neighbour show`
- Flush routing table: `ip route flush 123.123.123.123` or `ip r f 123.123.123.123`
- Prohibit traffic to IP: `ip route add prohibit 1.1.1.1`. This will result in a ping failing
- Remove route (such as the example above): `ip route del prohibit 1.1.1.1`
- These route changes will not persist a system restart (they would persist a network restart though). To create persistent routes, you'd need to add the route to `/etc/sysconfig/network-scripts/route-<INTERFACE_NAME>`.
- To create a route out through a specific interface: `ip route add 1.1.1.1 via <GW_IP> dev eth0`
- Create a route out through a specific gateway: `ip route add 1.1.1.1 via <GW_IP>`
- Create route for network: `ip route add 10.0.8.0/24 via <GW_IP>`
- Check network connection between the host. This prints network stats of the intervening routers to the hostname: `mtr HOSTNAME`
- Alternative to traceroute: `tracepath HOSTNAME`. 

#### DHCP
**Note:** commands may vary depending on *nix flavour in use but you can usually tab-complete from `/var/lib/dhc->` to find the right one. 

- DHCP request and offers are layer 2 broadcasts (similar to ARP requests) and need a DHCP client.
- DHCP server uses UDP 67 and client uses UDP 68
- Lookup the DHCP host: `cat /var/log/messages | grep "DHCPOFFER"` (or `cat /var/log/* | grep "DHCPOFFER"` if messages logs are rotating more frequently than DHCP offers).
- View lease information: `cat /var/lib/dhclient/dhclient--eth0.lease`
- View listening client: `sudo ss -luntp | grep dhclient` (switches: "listening", "udp", "numeric (don't resolve)", "tcp", "processes")
- Release IP `sudo dhclient -r`
- Restart DHCP Client: `sudo dhclient`

#### DNS
- DNS settings in **/etc/resolve.conf** (this could be maintained by a script but it will usually specify this as a comment if so)
- Hosts file in **/etc/hosts**

- Use `dig` to return query information:
  - `dig sre-resources.esnow.uk`: return a query on the host
  - `dig @8.8.8.8 sre-resources.esnow.uk`: send query to specified nameserver
  - `dig +short sre-resources.esnow.uk`: only return the IP of the specified host
  - `dig -x 12.34.56.78`: reverse DNS lookup

- Flush DNS cache: 
  - The OS will store a couple of caches, client will refer to one cache, local DNS resolver will refer to it's own cache. 
  - The local resolver will usually be **systemd-resolved**, **dnsmasq** or **bind**. You can use `lsof` to check for commands associated with port 53: `lsof -i :53 -S`
  - Flush **ststemd-resolved** cache: `sudo systemd-resolve --flush-caches` or `sudo resolvectl flush-caches`
  - Flush **dnsmasq** cache: ``
- Get list of Nameservers for a domain: `dig NS <HOSTNAME>`. You can tell if the reponse is authoritative or not by the "AUTHORITY: N" (where "N" is a number. 0 means no authority).
- Using one of the NS in the response above, you can get an authoritative resolution for a host: `dig @<NAMESERVER_FROM_ABOVE> <HOSTNAME>`. Example response:

> flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 3, ADDITIONAL: 6

**Note:** The "qr aa rd" means: "query request", "authoritative answer" and "recursion desired"
**Note:** The rest means, 1 query requested, 1 answer given, 3 authoritative nameservers and an additional 6 non-auth NS.

### Processes


### SSH