# Git

Useful commands for using git

##### Clone Repo

```bash
git clone https://github.com/my-username/my-repo.git
```

##### Create and checkout a new branch

```bash
git checkout -b "Mybranch"
```

##### Lazy add/commit/push

This will add all changed files, commit with a message and then push to the specified branch

```bash
git add -A && git commit -m "change all the 1s to 0s" && git push origin Mybranch
```

##### Update branch from latest in master

This will retain the history tracking

```bash
git checkout master    
git pull --rebase
git checkout Mybranch    
git rebase master
git push -f origin Mybranch
```