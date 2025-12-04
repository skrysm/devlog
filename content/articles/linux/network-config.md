---
title: Network Configuration for Debian, Ubuntu, Raspberry Pi OS on the Command Line
description: How to configure the network on Debian-based systems.
date: 2025-12-03
topics:
- debian
- ubuntu
- raspberry-pi
- networking
- dns
---

Unfortunately, on Debian-based systems (Debian, Ubuntu, Raspberry Pi OS), there are various ways to configure the network of the system - depending on the distro:

* ifupdown
* systemd-networkd
* NetworkManager
* netplan

For each, this article shows how to:

* Assign IP address via DHCP (for IPv4)
* Assign static IP address (including DNS)
* Connect to WiFi

As a bonus, this article also shows how to get back the old `eth0` etc. network device names.

> [!TIP]
> To check if a command is available on your machine, use `which`:
>
> ```sh
> $ which bash
> /usr/bin/bash
>
> $ which i-do-not-exist  # no output
> ```

## Basics

### Show network interfaces

To list all network interfaces, call:

```sh
ip a
```

Each interface will be listed with a status of `UP` (works) or `DOWN` (doesn't work).

### DNS

Most base/traditional software on Debian uses `/etc/resolv.conf` to determine the DNS server(s) and DNS-related settings. More modern software may decide to ignore this file and use `systemd-resolved` directly - but will fall back to `resolv.conf` if no other [DNS resolver](/dns/overview.md) is available.

Normally, this file **is automatically managed** by the DNS software on the system (like `resolvconf`, `dhcpcd`, `systemd-resolved`, ...). The DNS software either writes directly to this file, or creates a symlink to another file (`ls -l /etc/resolv.conf`).

However, in case something went wrong, you can manually edit this file:

```
nameserver 192.168.0.1
```

Alternatively, you can use a public DNS resolver like [Cloudflare's `1.1.1.1`](https://one.one.one.one/).

### Wi-Fi

Wi-Fi network devices show up as `wl...` or `wlanX` in `ip a`.

If that's the case, your Wi-Fi device is ready to be used.

If it doesn't show up, you may need to install additional firmware like `firmware-realtek` and then reboot.

## ifupdown

ifupdown is the oldest and most basic network configuration system. However, it's still used as default in Debian 13 on minimal installs.

**Is active:** `systemctl status networking`

**Packages:** `ifupdown`, `dhcpcd-base` (DHCP), `resolvconf` (DNS), `wpasupplicant` (Wi-Fi)

**Config files:** `/etc/network/interface` or `/etc/network/interfaces.d/*`

**Wi-Fi password stored in:** `/etc/wpa_supplicant/wpa_supplicant.conf`

**Reload network config:** `sudo ifdown ens18 && sudo ifup ens18`

**Wildcard support for interface names:** no (each interface must be explicitly specified)

**`systemctl` services:** `networking`, `wpa_supplicant` (Wi-Fi)

### DHCP

In `/etc/network/interface` or `/etc/network/interfaces.d/some-file`:

```
allow-hotplug ens18
iface ens18 inet dhcp
```

This assigns an IPv4 address (`inet`) to the device `ens18` via DHCP.

### Static IP Address

In `/etc/network/interface` or `/etc/network/interfaces.d/some-file`:

```
allow-hotplug ens18
iface ens18 inet static
    address 192.168.0.10
    netmask 255.255.255.0
    gateway 192.168.0.1
    dns-nameservers 192.168.0.1
    dns-search fritz.box  # optional
```

> [!NOTE]
> The `dns-` entries are not interpreted by ifupdown itself but by resolvconf.

### Side Note: `auto` vs `allow-hotplug`

You can configure interfaces both with `auto` and with `allow-hotplug`:

```
auto ens18
iface ens18 inet dhcp

allow-hotplug ens19
iface ens19 inet dhcp
```

`auto` brings up the device at boot time. If the device is not available then, your boot process will hang.

`allow-hotplug` brings up the device when it becomes available (from [`man interfaces`](https://man.cx/interfaces(5))):

> Interfaces marked "allow-hotplug" are brought up when udev detects them. This can either be during boot if the interface is already present, or at a later time, for example when plugging in a USB network card. Please note that this does not have anything to do with detecting a network cable being plugged in.

Of the two, `allow-hotplug` is recommended - unless you need network access very early during boot (for example, for nfs or smb mount in `fstab` without `nofail`).

### Wi-Fi

For Wi-Fi to work, you need the `wpa_supplicant` package:

```sh
apt install wpa_supplicant
```

Then you can create the Wi-Fi settings file (`wpa_supplicant.conf`) via:

```sh
wpa_passphrase "YOUR_SSID_HERE" > /etc/wpa_supplicant/wpa_supplicant.conf
chmod 0600 /etc/wpa_supplicant/wpa_supplicant.conf
```

This will read the Wi-Fi passphrase from the command line.

This file will look like:

```
network={
    ssid="YOUR_SSID_HERE"
    psk=4a3f2...
}
```

Next, you need to add the `wpa-conf` directive to your interface configuration:

```
allow-hotplug wlan0
iface wlan0 inet dhcp
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
```

It's recommended to use `allow-hotplug` here (instead of `auto`) so that the boot process doesn't hang if the wifi is not available.

If you get a timeout here:

* Check if the Wi-Fi network is hidden. In this case, add `scan_ssid=1` to `network={}` block in `wpa_supplicant.conf`.
* Check if the Wi-Fi network has a MAC address filter enabled.

## systemd

systemd (or more specific: systemd-networkd) is modern replacement for ifupdown. Nowadays, systemd comes preinstalled on most Debian-based distros (including Ubuntu and Raspberry Pi OS).

**Is active:** `systemctl status systemd-networkd`

**Packages:** `systemd`, `systemd-resolved` (DNS), `iwd` or `wpa_supplicant` (Wi-Fi)

**Config files:** `/etc/systemd/network/*`

**Wi-Fi password stored in:** `/var/lib/iwd/<SSID>.psk`

**Reload network config:** `sudo systemctl reload systemd-networkd`

**Wildcard support for interface names:** yes (`*`, `?`, and `[...]`)

**`systemctl` services:** `systemd-networkd`, `systemd-resolved` (DNS), `iwd` or `wpasupplicant` (Wi-Fi)

### DHCP

`/etc/systemd/network/ethernet.network`:

```ini
[Match]
Name=ens18

[Network]
DHCP=yes
```

### Static IP Address

`/etc/systemd/network/ethernet.network`:

```ini
[Match]
Name=ens18

[Network]
# In CIDR notation; /24 is subnet mask 255.255.255.0
Address=192.168.0.10/24
Gateway=192.168.0.1
DNS=192.168.0.1
Domains=fritz.box
```

> [!TIP]
> For the CIDR notation, search the internet for ["cidr calculator"](https://www.google.com/search?q=cidr+calculator).

### Wi-Fi

systemd works both with wpa-supplicant (used by ifupdown above) or iwd (iNet wireless daemon). Of the two, **iwd is recommended** for use with systemd.

> iwd (iNet wireless daemon) is a wireless daemon for Linux written by Intel. The core goal of the project is to optimize resource utilization by not depending on any external libraries and instead utilizing features provided by the Linux Kernel to the maximum extent possible. [source: Arch Wiki](https://wiki.archlinux.org/title/Iwd)

You first need to configure your network interface with systemd, e.g.:

`/etc/systemd/network/wifi.network`:

```ini
[Match]
Name=wlan0

[Network]
DHCP=yes
```

To connect the network interface to a Wi-Fi network (will ask for the Wi-Fi password):

```sh
iwctl station wlan0 connect "MySSID"
```

The settings are stored in: `/var/lib/iwd/<SSID>.psk`

See which Wi-Fi network an interface is connected to:

```sh
iwctl station wlan0 show
```

> [!NOTE]
> Make sure, you set `EnableNetworkConfiguration=false` (or comment it out) in `/etc/iwd/main.conf`.

## NetworkManager

Like systemd, NetworkManager is a modern replacement for ifupdown. NetworkManager is more designed for desktop systems than servers (but still Raspberry Pi OS uses it by default). Unlike systemd, it comes with a UI (both GUI and TUI) to configure your network interfaces.

**Is active:** `systemctl status NetworkManager`

**Packages:** `network-manager`

**Config files:** `/etc/NetworkManager/system-connections/*.nmconnection`

**Wi-Fi password stored in:** `/etc/NetworkManager/system-connections/<SSID>.nmconnection`

**Reload network config:** `nmcli connection reload`

**Wildcard support for interface names:** Automatic DHCP for all managed interfaces

**`systemctl` services:** `NetworkManager`

### Configuring Network Interfaces

To configure network interfaces with NetworkManager:

```sh
nmtui
```

The related configuration files will be stored in `/etc/NetworkManager/system-connections/*.nmconnection`.

> [!TIP]
> List the location of all profiles being used:
>
> ```sh
> nmcli -f device,state,name,type,filename connection show
> ```

### Managed Interfaces

NetworkManager distinguishes between managed and unmanaged network interfaces. NetworkManager only manages "managed" interfaces and leaves unmanaged ones alone.

To see managed status:

```sh
nmcli device
```

Unmanaged interfaces are listed as "unmanaged". All other interfaces are managed.

> [!TIP]
> By default, NetworkManager treats interfaces listed in `/etc/network/interface` as unmanaged (i.e., managed by ifupdown) - no matter whether ifupdown is actually used.
>
> This behavior can be disabled in `/etc/NetworkManager/NetworkManager.conf` - either by removing the `ifupdown` plugin or by setting `ifupdown.managed` to `true`.

## netplan

netplan is Ubuntu's solution to have a unified configuration language for both systemd and NetworkManager. Although it was designed for Ubuntu, it works on any Debian system. Unlike systemd and NetworkManager, netplan itself doesn't do any network interface configuration. Instead, it creates configuration files for either systemd or NetworkManager.

**Is active:** `which netplan`

**Packages:** `netplan.io`

**Config files:** `/etc/netplan/*.yaml` (not `.yml`!) - [documentation](https://netplan.readthedocs.io/en/stable/netplan-yaml/#)

**Wi-Fi password stored in:** `/etc/netplan/*.yaml`

**Reload network config:** `netplan apply`

**Wildcard support for interface names:** Yes, via `match.name` ([documentation](https://netplan.readthedocs.io/en/stable/netplan-yaml/#properties-for-physical-device-types))

**`systemctl` services:** -

> [!NOTE]
> Netplan runs on boot to apply any changes of its config files - but it doesn't have a long running service.

> [!WARNING]
> To use **Wi-Fi with systemd**, you need to have the `wpasupplicant` packaged installed. netplan doesn't support `iwd` with systemd.

### Renderers

netplan has two renderers: systemd and NetworkManager.

The renderer determines which "backend" is used by netplan.

**To use systemd:**

```yaml
network:
  renderer: systemd  # the default; can also be omitted
```

**To use NetworkManager:**

```yaml
network:
  renderer: NetworkManager
```

### DHCP

`/etc/netplan/my-connection.yaml`:

```yaml
network:
  #renderer: NetworkManager
  ethernets:
    eth0:
      dhcp4: true
```

### Static IP Address

`/etc/netplan/my-connection.yaml`:

```yaml
network:
  #renderer: NetworkManager
  ethernets:
    eth0:
      addresses:
        - 192.168.1.194/21
      routes:  # default gateway
        - to: default
          via: 192.168.0.1
      nameservers:  # DNS settings
        search: [fritz.box]
        addresses: [192.168.0.1]
```

> [!WARNING]
> If you have multiple network interfaces, you can set the **default gateway (`routes` section) only on one interface**. If you set the default gateway on multiple network interfaces, you'll get an error.

### Wi-Fi

`/etc/netplan/my-connection.yaml`:

```yaml
network:
  #renderer: NetworkManager
  wifis:
    wlan0:
      access-points:
        "My-SSID":
          password: 'my-wifi-password'
      #dhcp4: true
      addresses:
        - 192.168.1.196/21
      routes:
        - to: default
          via: 192.168.0.1
      nameservers:
        search: [fritz.box]
        addresses: [192.168.0.1]
```

## Get eth0 back

Linux introduced **predictable network interface names** (`enp0s31f6`) around 2015 and they became the default in around 2017. They were introduced because the traditional interface names (`eth0`, `eth1`, `wlan0`) would sometimes assigned to different network adapters after a reboot.

Of course, this could only happen for machines that have multiple network adapters. For machines with just one network adapter, the traditional interface names work fine and can actually be more stable (because changing the PCI slot can change the name of a "predictable network interface name").

To get the traditional names back:

1. Edit GRUB defaults:

   ```sh
   nano /etc/default/grub
   ```

1. Find the line:

   ```
   GRUB_CMDLINE_LINUX=""
   ```

1. Change it to:

   ```
   GRUB_CMDLINE_LINUX="net.ifnames=0"
   ```

1. Update GRUB:

   ```sh
   update-grub
   ```

1. Reboot:

   ```sh
   reboot
   ```

> [!NOTE]
> On a Raspberry Pi (where Grub isn't used), add `net.ifnames=0` to `/boot/firmware/cmdline.txt`.
