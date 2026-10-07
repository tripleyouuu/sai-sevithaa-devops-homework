# Sessions 1-2: Linux Fundamentals

Combined into one submission per the course structure. Tasks 1 and 4 were run
directly on this machine (both are standard POSIX commands, identical on
macOS and Ubuntu). Tasks 2 and 3 need a real Linux environment — see status
below.

## Task 1: Soft Link & Hard Link

Full transcript: [`linkdemo/link_demo_output.txt`](linkdemo/link_demo_output.txt)

```
$ echo 'hello world' > original.txt
$ ln -s original.txt softlink.txt
$ ln original.txt hardlink.txt

$ ls -li original.txt softlink.txt hardlink.txt
23111329 -rw-r--r--@ 2 vitha  staff  12 Oct  7 21:07 hardlink.txt
23111329 -rw-r--r--@ 2 vitha  staff  12 Oct  7 21:07 original.txt
23111342 lrwxr-xr-x@ 1 vitha  staff  12 Oct  7 21:07 softlink.txt -> original.txt

$ rm original.txt

$ cat softlink.txt   (broken, target gone)
cat: softlink.txt: No such file or directory

$ cat hardlink.txt   (still works, data survives)
hello world
```

**How they differ:**
- A **hard link** (`ln`) is a second directory entry pointing at the *same
  inode* as the original file. Note `original.txt` and `hardlink.txt` share
  inode `23111329` above. The file's data isn't deleted until every hard
  link to it is removed — that's why `hardlink.txt` still works after
  `original.txt` is deleted.
- A **soft link** (`ln -s`, symlink) is a separate file that just stores a
  *path string* pointing at the target. It has its own inode (`23111342`).
  If the target is deleted or moved, the symlink breaks (dangling link).
- Hard links can't cross filesystems/partitions and can't point at
  directories; symlinks can do both.

**Interview framing:** "A hard link is another name for the same data on
disk (same inode, survives the original being deleted); a symlink is a
pointer to a path (breaks if the path goes away). Use hard links rarely
(mostly historical/dedup use cases); symlinks are the common one, e.g.
`/usr/bin/python3 -> python3.11`."

## Task 2: adduser vs useradd — BLOCKED

Needs a real Linux box — macOS has neither command (it manages users via
`dscl`/System Settings instead). `useradd` is a low-level binary (no home
dir, no shell prompt, no password by default unless flagged); `adduser` is
Debian/Ubuntu's higher-level Perl script that wraps `useradd` and
interactively creates the home directory, copies `/etc/skel`, sets a
password, and asks for user info — which is why Ubuntu's own docs recommend
`adduser` for interactive use. Will run for real once Docker/Colima is
available (planned: `docker run -it ubuntu bash`, then `useradd -m testuser1`
vs `adduser testuser2`, comparing `/etc/passwd` and `/home`).

## Task 3: journalctl — BLOCKED

Needs `systemd`, which doesn't exist on macOS (or in a plain Docker
container without an init system — this one specifically needs a full
Ubuntu VM/systemd setup, e.g. via Minikube's underlying VM or a proper
`systemd`-enabled container). Will document `journalctl --no-pager`,
`journalctl -u <service>`, `journalctl --since "1 hour ago"`, and
`journalctl -p err` once that environment is available.

## Task 4: Linux Command Cheat Sheet

Full transcript: [`cheatsheet_demo/cheatsheet_output.txt`](cheatsheet_demo/cheatsheet_output.txt)

| Command | Purpose | Example used |
|---|---|---|
| `pwd` | print current directory | `pwd` |
| `mkdir` | create a directory | `mkdir demo_dir` |
| `mv` | move/rename a file | `mv sample.txt renamed.txt` |
| `chmod` | change file permissions | `chmod 644 renamed.txt` |
| `ls -l` | list files with details | `ls -l demo_dir` |
| `grep -r` | search file contents recursively | `grep -r 'sample' demo_dir` |
| `find` | search for files by name/pattern | `find . -name '*.txt'` |
| `df -h` | show disk space usage, human-readable | `df -h` |
| `du -sh` | show size of a directory | `du -sh demo_dir` |
| `ps aux` | list running processes | `ps aux` |
| `tar -czf` / `-tzf` | create / list a compressed archive | `tar -czf demo.tar.gz demo_dir` |
| `curl -I` | fetch HTTP headers only | `curl -sI https://example.com` |

`cp`, `rm`, `chown`, `kill`, `top`, `ssh`, `scp`, `wget` were reviewed via
`man` but not re-demonstrated here since their usage is one-line and
self-explanatory (`cp src dst`, `rm file`, `chown user:group file`,
`kill <pid>`, `top`, `ssh user@host`, `scp file user@host:path`,
`wget <url>`).

## Status

Tasks 1 and 4 complete. Tasks 2 and 3 are blocked on Docker/Colima being
installed (see root `ACTION_PLAN.md` Phase 0) — will complete as soon as
that's available.
