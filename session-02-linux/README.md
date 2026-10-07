# Session 2 — Linux Fundamentals

Tasks 1 and 4 ran directly on this Mac (same POSIX commands as Ubuntu). Tasks 2 and 3 needed a real Linux box, so I ran those inside a systemd-enabled Ubuntu container (`geerlingguy/docker-ubuntu2204-ansible`, `--privileged` with cgroups mounted — a plain `ubuntu` image has no init system and can't run `adduser`/`journalctl` properly).

## Task 1 — Soft link vs hard link

```
$ echo 'hello world' > original.txt
$ ln -s original.txt softlink.txt
$ ln original.txt hardlink.txt

$ ls -li original.txt softlink.txt hardlink.txt
23111329 -rw-r--r--@ 2 vitha  staff  12 Oct  7 21:07 hardlink.txt
23111329 -rw-r--r--@ 2 vitha  staff  12 Oct  7 21:07 original.txt
23111342 lrwxr-xr-x@ 1 vitha  staff  12 Oct  7 21:07 softlink.txt -> original.txt

$ rm original.txt

$ cat softlink.txt
cat: softlink.txt: No such file or directory

$ cat hardlink.txt
hello world
```

A hard link shares the same inode as the original (see `hardlink.txt` and `original.txt` both at `23111329` above), so it survives the original being deleted. A symlink is just a path pointer with its own inode — delete the target and it breaks. Hard links can't cross filesystems or point at directories; symlinks can do both.

Full transcript: [linkdemo/link_demo_output.txt](linkdemo/link_demo_output.txt)

## Task 2 — adduser vs useradd

```
$ useradd -m testuser1
testuser1:x:1000:1000::/home/testuser1:/bin/sh

$ adduser --disabled-password --gecos "" testuser2
Adding user `testuser2' ...
Adding new group `testuser2' (1001) ...
Creating home directory `/home/testuser2' ...
Copying files from `/etc/skel' ...
testuser2:x:1001:1001:,,,:/home/testuser2:/bin/bash
```

`useradd` made the user and home dir but left the shell at `/bin/sh` and skipped `/etc/skel`. `adduser` did both automatically and set `/bin/bash`. That's why Ubuntu recommends `adduser` for interactive use and `useradd` for scripts where you want every step explicit.

Full transcript: [adduser_useradd_output.txt](adduser_useradd_output.txt)

## Task 3 — journalctl

```
$ journalctl --no-pager | head -15
Oct 07 13:45:59 45fabff7f0a2 kernel: Booting Linux on physical CPU 0x0000000000 [0x610f0000]
...

$ journalctl -u systemd-resolved --no-pager
Oct 07 13:45:59 45fabff7f0a2 systemd[1]: Starting Network Name Resolution...
Oct 07 13:45:59 45fabff7f0a2 systemd-resolved[40]: Positive Trust Anchors:
...
Oct 07 13:45:59 45fabff7f0a2 systemd[1]: Started Network Name Resolution.
```

`-u <unit>` filters to one service's logs, `--since` filters by time, `-p err` filters by priority.

Full transcript: [journalctl_unit_output.txt](journalctl_unit_output.txt)

## Task 4 — Cheat sheet

Full transcript: [cheatsheet_demo/cheatsheet_output.txt](cheatsheet_demo/cheatsheet_output.txt)

| Command | Purpose |
|---|---|
| `pwd` | print current directory |
| `mkdir` | create a directory |
| `mv` | move/rename a file |
| `chmod` | change permissions |
| `ls -l` | list files with details |
| `grep -r` | search file contents recursively |
| `find` | search for files by name/pattern |
| `df -h` | disk space, human-readable |
| `du -sh` | size of a directory |
| `ps aux` | list running processes |
| `tar -czf` / `-tzf` | create / list an archive |
| `curl -I` | fetch HTTP headers only |

`cp`, `rm`, `chown`, `kill`, `top`, `ssh`, `scp`, `wget` reviewed but not demoed separately — one-liners, self-explanatory.
