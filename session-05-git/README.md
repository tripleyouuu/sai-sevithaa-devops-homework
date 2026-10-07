# Session 5: Git — commit -a -m and Cherry-Pick

Demonstrated in a scratch repo (not this homework repo's own history, to keep
that history clean). Full command transcript below.

## Task 1: `git commit -a -m` vs `git commit -m`

```
$ git commit -m "update without -a"
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   file1.txt

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

**Difference:** `git commit -m "msg"` only commits what's already staged with
`git add`. Since `file1.txt` had unstaged modifications, the first commit did
nothing. `git commit -a -m "msg"` automatically stages all changes to
**already-tracked** files (modified or deleted, not new/untracked files)
before committing — so the second command succeeded in one step.

## Task 2: Cherry-Pick

```
$ git log --oneline (main, before branching)
e6016ad third commit on main
619f026 update with -a
c522ce7 initial commit

$ git checkout -b feature-branch

$ git log --oneline (feature-branch)
f103009 feature: important fix to cherry-pick
12a1367 feature: extend feature.txt
1350cae feature: add feature.txt
e6016ad third commit on main
619f026 update with -a
c522ce7 initial commit
```

Back on `main`, cherry-picking the commit that first introduces `feature.txt`:

```
$ git checkout main

$ git cherry-pick 1350cae
[main cae00b3] feature: add feature.txt
 Date: Wed Oct 7 21:03:41 2026 +0800
 1 file changed, 1 insertion(+)
 create mode 100644 feature.txt

$ git log --oneline
cae00b3 feature: add feature.txt
e6016ad third commit on main
619f026 update with -a
c522ce7 initial commit

$ cat feature.txt
feature-a
```

`feature.txt` is now present on `main` with the content from the cherry-picked
commit, confirming the change made it across branches without merging the
whole `feature-branch`.

### Bonus: what a cherry-pick conflict looks like

Picking a *later* feature-branch commit (one that modifies `feature.txt`)
before the commit that creates the file produces a real conflict, since `main`
has no `feature.txt` to modify yet:

```
$ git cherry-pick f103009
CONFLICT (modify/delete): feature.txt deleted in HEAD and modified in f103009
(feature: important fix to cherry-pick). Version f103009 of feature.txt left
in tree.
error: could not apply f103009... feature: important fix to cherry-pick
```

Resolved with `git cherry-pick --abort` and re-picked in the correct order —
a reminder that cherry-pick applies a single commit's *diff*, not its full
file history, so picking commits out of dependency order can conflict.
