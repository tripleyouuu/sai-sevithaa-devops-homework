# Session 2: Linux Fundamentals

Tasks 1 and 4 were run directly on this machine (both are standard POSIX
commands, identical on macOS and Ubuntu). Tasks 2 and 3 need a real Linux
environment — see status below.

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

## Task 2: adduser vs useradd

Run inside a real systemd-enabled Ubuntu 22.04 container
(`geerlingguy/docker-ubuntu2204-ansible`, started `--privileged` with
cgroups mounted, since plain Docker containers have no init system and a
bare `ubuntu` image can't run `adduser`'s dependencies properly).

```
$ useradd -m testuser1
exit code: 0
testuser1:x:1000:1000::/home/testuser1:/bin/sh

$ adduser --disabled-password --gecos "" testuser2
Adding user `testuser2' ...
Adding new group `testuser2' (1001) ...
Adding new user `testuser2' (1001) with group `testuser2' ...
Creating home directory `/home/testuser2' ...
Copying files from `/etc/skel' ...
exit code: 0
testuser2:x:1001:1001:,,,:/home/testuser2:/bin/bash
```

**The difference, confirmed by the output above:**
- `useradd -m testuser1` created the user and home directory but gave it
  `/bin/sh` as its shell and didn't touch `/etc/skel` — it's a minimal,
  low-level tool that does exactly what you ask and nothing more.
- `adduser testuser2` created a matching group, copied the standard skeleton
  files from `/etc/skel` into the new home directory, and set `/bin/bash` as
  the shell — all without being asked. It's Debian/Ubuntu's friendlier Perl
  wrapper around `useradd`, which is why Ubuntu's own docs recommend it for
  interactive/manual user creation, while `useradd` is more common in
  scripts where every behavior should be explicit.

Full transcript: [`adduser_useradd_output.txt`](adduser_useradd_output.txt)

## Task 3: journalctl

Same systemd-enabled container.

```
$ journalctl --no-pager | head -15
Oct 07 13:45:59 45fabff7f0a2 kernel: Booting Linux on physical CPU 0x0000000000 [0x610f0000]
Oct 07 13:45:59 45fabff7f0a2 kernel: Linux version 6.8.0-117-generic ...
...
```

```
$ journalctl -u systemd-resolved --no-pager
Oct 07 13:45:59 45fabff7f0a2 systemd[1]: Starting Network Name Resolution...
Oct 07 13:45:59 45fabff7f0a2 systemd-resolved[40]: Positive Trust Anchors:
...
Oct 07 13:45:59 45fabff7f0a2 systemd[1]: Started Network Name Resolution.
```

`journalctl` is systemd's unified log viewer — it reads the binary journal
that `systemd-journald` writes, replacing the older plain-text
`/var/log/*.log` approach. `journalctl -u <unit>` filters to one service's
logs (useful for "why did nginx just restart"), `--since` filters by time
window, and `-p err` filters by priority level (`emerg` through `debug`) —
handy for scanning straight to failures without reading everything.

Full transcript: [`journalctl_unit_output.txt`](journalctl_unit_output.txt)

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

All 4 tasks complete.
