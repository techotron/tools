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

### DNS Issues
- DNS settings in **/etc/resolve.conf** (this could be maintained by a script but it will usually specify this as a comment if so)
- Hosts file in **/etc/hosts**

- Use `dig` to return query information:
  - `dig sre-resources.esnow.uk`: return a query on the host
  - `dig @8.8.8.8 sre-resources.esnow.uk`: send query to specified nameserver
  - `dig +short sre-resources.esnow.uk`: only return the IP of the specified host

- Flush DNS cache: 
  - The OS will store a couple of caches, client will refer to one cache, local DNS resolver will refer to it's own cache. 
  - The local resolver will usually be **systemd-resolved**, **dnsmasq** or **bind**. You can use `lsof` to check for commands associated with port 53: `lsof -i :53 -S`
  - Flush **ststemd-resolved** cache: `sudo systemd-resolve --flush-caches` or `sudo resolvectl flush-caches`
  - Flush **dnsmasq** cache: ``

### Security
TODO
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
TODO

#### CPU Saturation
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

### Networking
TODO
- Displaying the routing table: `ip route list`
- Display the arp table: `ip neighbour show`

iptables (nat)
ss
sar
nmap
tcpdump


#### `curl`

#### `wget`

### Disk

### Processes


### SSH
