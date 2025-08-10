---
title: user-data/cloud-config for cloud-init
description: An overview of the user-data (a.k.a. cloud-config) file for cloud-init.
topics:
- cloud-init
date: 2025-08-10
---

The tool **cloud-init** allows you to customize cloud (and bare metal) systems in a standardized way - via a **user-data** file (also known as **cloud-config** file).

There is a lot of documentation available but I find it a bit hard to navigate or to find things you're looking for. So, this article aims to give you some pointers when working with cloud-init.

**Quick Links:**

* [Examples](https://cloudinit.readthedocs.io/en/latest/reference/examples_library.html)
* [Module Reference](https://cloudinit.readthedocs.io/en/latest/reference/modules.html)
* [Homepage](https://cloud-init.io/)
* [Documentation](https://cloudinit.readthedocs.io/en/latest/index.html)

## The user-data/cloud-config file

The cental way to configure a cloud-init supported system is via the **user-data** file.

While cloud-init actually supports [multiple formats](https://cloudinit.readthedocs.io/en/latest/explanation/format.html#user-data-formats) for the user-data file, most of the time you'll use the **cloud-config** format.

It's a regular YAML file that looks like this:

```yaml
#cloud-config
write_files:
  - content: |
      Hello from cloud-init
    path: /var/tmp/hello-world.txt
    permissions: '0770'
```

> [!NOTE]
To let cloud-init know that the user-data file is in the cloud-config format, **the first line must be `#cloud-config`!** (It's *not* an optional comment.)

## Reference Documentation

Each field (e.g. `write_files` in the example above) belongs to a **cloud-init module**.

A list of all modules including **descriptions for all fields** can be found in the [module reference](https://cloudinit.readthedocs.io/en/latest/reference/modules.html).

Unfortunately, at the time of writing, **you can't search this reference for field names**. You first have guess the module a field belongs to and then open the "Config schema" tab for that module.

## Examples

The cloud-init documentation contains a [large set of examples](https://cloudinit.readthedocs.io/en/latest/reference/examples_library.html) which can be a good starting point.

I will provide some useful examples here as well.

### Add SSH key for root

This installs you public SSH key for the `root` user ([module description](https://cloudinit.readthedocs.io/en/latest/reference/modules.html#ssh)):

```yaml
#cloud-config

# Allow SSH access for root
disable_root: false

users:
  - name: root
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDynzJa8m...== Your Name
```

### Re-create SSH Host Keys

By default, cloud-init will recreate the SSH host keys for the machine (i.e. the keys used by the SSH server).

The reason: The base image already contains SSH host keys and it would be bad if all cloned images have the same SSH keys.

You can control this behavior with the `ssh_deletekeys` field ([module description](https://cloudinit.readthedocs.io/en/latest/reference/modules.html#ssh)):

```yaml
#cloud-config

# Whether to delete any existing SSH server keys. (Default: true)
ssh_deletekeys: true
```

> [!WARNING]
> You should only disable this if you really need to keep your SSH host keys and understand the security implications of doing so.

### Upgrade Packages

This will update all installed packages ([module description](https://cloudinit.readthedocs.io/en/latest/reference/modules.html#package-update-upgrade-install)):

```yaml
#cloud-config

# Run "apt update" (or similar).
package_update: true
# Run "apt upgrade" (or similar).
package_upgrade: true
# Reboot machine, if requested.
package_reboot_if_required: true
```

### Run Arbitrary Commands

You can run arbitrary commands with `runcmd` ([module description](https://cloudinit.readthedocs.io/en/latest/reference/modules.html#runcmd)):

```yaml
#cloud-config

runcmd:
  - echo "Hello World"
  - deluser --remove-home pi || true
  - systemctl restart ssh
```
