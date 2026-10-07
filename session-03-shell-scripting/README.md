# Session 3: Shell Scripting — System Information Script

`sysinfo.sh` prints system information, takes user input, and stores the running
process list to a file.

## What it does

- Prints the current date, hostname, and username (stored in variables)
- Prints disk usage with `df -h`
- Prompts for an output directory and file name with `read -p`
- Creates the directory with `mkdir -p`
- Creates the file with `touch`
- Writes the running process list into that file with `ps aux > file`

## Run it

```bash
chmod +x sysinfo.sh
./sysinfo.sh
```

## Output

```
$ ./sysinfo.sh
Date: Wed Oct  7 21:02:50 WITA 2026
Hostname: Vithas-MacBook-Pro.local
Username: vitha
Disk Usage:
Filesystem        Size    Used   Avail Capacity iused ifree %iused  Mounted on
/dev/disk3s1s1   926Gi    12Gi   597Gi     2%    459k  4.3G    0%   /
devfs            202Ki   202Ki     0Bi   100%     700     0  100%   /dev
/dev/disk3s6     926Gi    20Ki   597Gi     1%       0  6.3G    0%   /System/Volumes/VM
/dev/disk3s2     926Gi    10Gi   597Gi     2%    2.1k  6.3G    0%   /System/Volumes/Preboot
/dev/disk3s4     926Gi   3.2Mi   597Gi     1%      63  6.3G    0%   /System/Volumes/Update
/dev/disk1s2     550Mi   6.0Mi   530Mi     2%       1  5.4M    0%   /System/Volumes/xarts
/dev/disk1s1     550Mi   5.9Mi   530Mi     2%      42  5.4M    0%   /System/Volumes/iSCPreboot
/dev/disk1s3     550Mi   3.0Mi   530Mi     1%     105  5.4M    0%   /System/Volumes/Hardware
/dev/disk3s5     926Gi   305Gi   597Gi    34%    1.8M  6.3G    0%   /System/Volumes/Data
map auto_home      0Bi     0Bi     0Bi   100%       0     0     -   /System/Volumes/Data/home
/dev/disk4s1     1.0Gi   929Mi    93Mi    91%    3.8k  4.3G    0%   /Volumes/VS Code
Enter a name for your output directory: process_logs
Enter a name for your output file: processes.txt
Running processes saved to process_logs/processes.txt
```

`process_logs/processes.txt` contains the output of `ps aux` (875 lines). First few lines:

```
USER               PID  %CPU %MEM      VSZ    RSS   TT  STAT STARTED      TIME COMMAND
_windowserver      400  53.9  0.5 436696368 127680   ??  Ss   11:35AM  42:35.77 /System/Library/PrivateFrameworks/SkyLight.framework/Resources/WindowServer -daemon
root              1152  41.4  0.1 435359200  33840   ??  Ss   11:35AM   0:06.66 /System/Library/PrivateFrameworks/XprotectFramework.framework/Versions/A/XPCServices/XprotectService.xpc/Contents/MacOS/XprotectService
_coreaudiod        409   7.4  0.2 435307152  50128   ??  Ss   11:35AM  14:53.87 /usr/sbin/coreaudiod
vitha              697   7.4  2.1 437044608 520976   ??  S    11:35AM   8:07.63 /Applications/WhatsApp.app/Contents/MacOS/WhatsApp
```

## Note

Run on macOS, so `df`/`ps` output is BSD-flavored rather than the GNU/Linux
output you'd see on Ubuntu. The commands, flags, and script logic are
identical on Ubuntu — only column formatting differs.
