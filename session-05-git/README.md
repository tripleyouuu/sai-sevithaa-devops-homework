# Session 5 — Git

Demoed in a scratch repo, not this homework repo's own history.

## Task 1 — `git commit -a -m` vs `git commit -m`

```
$ git commit -m "update without -a"
no changes added to commit (use "git add" and/or "git commit -a")

$ git status --short
 M file1.txt

$ git commit -a -m "update with -a"
[main 619f026] update with -a
 1 file changed, 1 insertion(+)

$ git log --oneline
619f026 update with -a
c522ce7 initial commit
```

`-m` alone only commits what's already staged. `file1.txt` had unstaged changes, so the first commit did nothing. `-a -m` auto-stages changes to already-tracked files before committing, in one step.

## Task 2 — Cherry-pick

```
$ git log --oneline
e6016ad third commit on main
619f026 update with -a
c522ce7 initial commit

$ git checkout -b feature-branch
$ git log --oneline
f103009 feature: important fix to cherry-pick
12a1367 feature: extend feature.txt
1350cae feature: add feature.txt
...

$ git checkout main
$ git cherry-pick 1350cae
[main cae00b3] feature: add feature.txt

$ git log --oneline
cae00b3 feature: add feature.txt
e6016ad third commit on main
...

$ cat feature.txt
feature-a
```

`feature.txt` is now on `main` with the content from the cherry-picked commit, without merging all of `feature-branch`.

### Bonus: a cherry-pick conflict

Picking a later commit before the one that creates the file conflicts, since `main` has nothing to modify yet:

```
$ git cherry-pick f103009
CONFLICT (modify/delete): feature.txt deleted in HEAD and modified in f103009
error: could not apply f103009... feature: important fix to cherry-pick
```

Aborted with `git cherry-pick --abort` and re-picked in the right order — cherry-pick applies one commit's diff, not its history, so order matters.
