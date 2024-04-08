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
