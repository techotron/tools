(gxargs for GNU xargs on OSX)

P: 0 parallel
I: replace string
d: space as delimiter
_command to run_ (command to run)
-i is a kubectl parameter "pass stdin to the container"

"For each of "pod1", "pod2" and "pod3", run `kubectl exec podN -c app -- ls`, sequentially (not in parallel)

```
echo "pod1 pod2 pod3" | gxargs -P0 -I{} -d " " kubectl exec -i {} -c app -- ls
```


Curl sequential set of IPs from 1 - 100:
```bash
seq 1 100 | xargs -I{} curl 10.10.10.{} -w "%{remote_ip} ----> %{response_code}\n" -s -o /dev/null
```

Output:
```
10.10.10.1 ----> 200
10.10.10.2 ----> 200
10.10.10.3 ----> 200
...
```

Delete all local branches (except for "main" and "master") which are merged
```bash
git branch --merged | grep -Ev "(^\*|main|master)" | xargs git branch -d
```

CURL stats to multiple hosts, specifying a resolver
```bash
 printf "facebook\n yahoo\n google\n" | xargs -P0 -I{} curl --resolve www.{}.com:443:127.0.0.1 https://www.\{\}.com -s -o /dev/null -w "[%{url}] ==> rc:%{response_code} ta:%{time_appconnect} tt:%{time_total}\n"
```

Output:
```
[https://www.google.com] ==> rc:200 ta:0.050301 tt:0.160478
[https://www.facebook.com] ==> rc:200 ta:0.046272 tt:0.243306
[https://www.yahoo.com] ==> rc:200 ta:0.044155 tt:0.970448
```
