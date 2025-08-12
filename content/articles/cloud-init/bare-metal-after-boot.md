---
title: Cloud-init on Bare Metal after Boot
description: Describes how to use cloud-init for an already started machine in an on-premises environment.
topics:
- cloud-init
date: 2025-08-23
---

The tool cloud-init is normally used for cloud VMs and on first boot.

This article shows how to manually invoke cloud-init on an on-premises machine (e.g., in a small network, home lab, ...) even after the machine has already booted.

This article is a *starting point*. We'll provide the necessary cloud-init data using a standard HTTP server. You can later add features like HTTPS and dynamic data if needed.

## The Datasource

The **datasource** specifies what cloud-init should do.

Normally, cloud-init detects which cloud provider it's running on and automatically selects the appropriate datasource. (For a list of supported cloud providers, see the [datasources documentation](https://cloudinit.readthedocs.io/en/latest/reference/datasources.html).)

To use cloud-init in an on-premises environment, you have to use the [**NoCloud datasource**](https://cloudinit.readthedocs.io/en/latest/reference/datasources/nocloud.html).

The NoCloud datasource can get its data from [various sources](https://cloudinit.readthedocs.io/en/latest/reference/datasources/nocloud.html#configuration-sources) - in this article, we'll use HTTP.

cloud-init will *only* accept this datasource if it provides at least two files:

* [`user-data`](user-data.md) - contains the actual things to do.
* `meta-data` - normally contains information provided by the cloud provider.

For this article, use the following contents for the `user-data` file:

```yaml
#cloud-config

# Don't delete existing SSH host keys.
ssh_deletekeys: false

runcmd:
  - echo "it worked!" > /tmp/example.txt
```

For the `meta-data` file, we will use the following contents:

```yaml
instance-id: my-instance-001
```

> [!NOTE]
> As far as I can tell, the value of `instance-id` doesn't matter here and can be the same for all machines.
>
> Its primary purpose is to let cloud-init [detect whether it has already run](https://cloudinit.readthedocs.io/en/latest/explanation/first_boot.html) on the machine.

## The HTTP Server

We'll use Docker to host the HTTP server that serves the cloud-init files:

```yaml
services:
  cloud-init-http:
    image: caddy:alpine # https://caddyserver.com/
    container_name: http-server

    ports:
      - "8080:8080"

    volumes:
      - ./cloud-init:/srv/cloud-init:ro
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_config:/config
      - caddy_data:/data

    restart: unless-stopped

volumes:
  # See: https://hub.docker.com/_/caddy/#how-to-use-this-image
  caddy_config:
  caddy_data:
```

The `Caddyfile`:

```Caddyfile
{
    log {
        format console
        level ERROR
    }
}

http://:8080 {
    root * /srv
    file_server
}
```

With this, you should have this file tree:

```
/
├── docker-compose.yml
├── Caddyfile
└── cloud-init/
    ├── meta-data
    └── user-data
```

> [!WARNING]
> This setup serves the cloud-init files **unencrypted** over HTTP. This is **just for demonstration purposes**.
>
> Since cloud-init lets you run arbitrary commands, an attacker could modify your `user-data` in transit and **take over your server**.
>
> In production, you should **secure the server with HTTPS/TLS**. Caddy has built-in support for [ACME/Let's Encrypt](https://caddyserver.com/docs/automatic-https).

## On the Target System

On the system you want to setup with cloud-init, you need to register your HTTP server as the datasource.

To do this, create the file `/etc/cloud/cloud.cfg.d/99_datasource.cfg`:

```yaml
datasource_list: ["NoCloud"]
datasource:
  NoCloud:
    seedfrom: http://<your-server>:8080/cloud-init/
```

You can use both an IP address or a DNS name for `<your-server>`.

Next, test the connection:

```sh
$ curl http://<your-server>:8080/cloud-init/user-data
$ curl http://<your-server>:8080/cloud-init/meta-data
```

> [!WARNING]
> Testing the connection is very important. If cloud-init can't reach your HTTP server, it will **fall back to an empty datasource**.
>
> Running cloud-init with an empty datasource will **re-create the machine's SSH keys on every run** because the [`ssh_deletekeys` instruction](https://cloudinit.readthedocs.io/en/latest/reference/modules.html#ssh) defaults to `true`.

After that, you can invoke cloud-init with the following commands:

```sh
$ cloud-init clean --logs --machine-id --seed
$ cloud-init init
$ cloud-init modules --mode=config
$ cloud-init modules --mode=final
$ touch /etc/cloud/cloud-init.disabled
```

The first command (`cloud-init clean`) resets cloud-init so it behaves as if it has never run.

The next three commands execute the [three cloud-init stages](https://cloudinit.readthedocs.io/en/latest/explanation/boot.html): `init`, `config`, and `final`.

The last command ensures cloud-init [doesn't run again](https://cloudinit.readthedocs.io/en/latest/howto/disable_cloud_init.html) the next time the system is rebooted.

> [!TIP]
> To see which modules run at which stage, check the `cloud_init_modules`, `cloud_config_modules`, and `cloud_final_modules` sections in `/etc/cloud/cloud.cfg`.

## Troubleshooting

If anything goes wrong or doesn't work as expected, these commands can help you troubleshoot:

**Print the datasource:**

```sh
cloud-id
```

If you followed this article, the output should be `nocloud`.

**Print the status:**

```sh
cloud-init status --long
```

**Check the logs:**

```sh
less /var/log/cloud-init.log
less /var/log/cloud-init-output.log
```
