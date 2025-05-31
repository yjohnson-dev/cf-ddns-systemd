# cf-ddns-systemd

A script to update Cloudflare DNS entries via `systemd` timers.

## Components

The following files are necessary for the service to work.

- One or more **Service** files, based on `cf-ddns.service`
- The **Timer** file, `cf-ddns.timer`
- The **Target** file, `cf-ddns.target`
- The **Script** file, `cf-ddns.sh`

Every hour, `cf-ddns.timer` calls `cf-ddns.target` to execute one or more variations of `cf-ddns.service`, as defined by the administrator. These variants of `cf-ddns.service` use an environment file to call `cf-ddns.sh` with the appropriate secrets and values; each of them should use their own environment files to customize the output of the command. The script outputs to the journal

The service file is designed to work within `systemd` user instances (accessible via `systemctl --user`) and would ideally be run under a specific, unprivileged user. When wanting to use multiple service files, make sure to update `cf-ddns.target` with the name.

### Why so many `systemd` directives?

This is a network-facing script and service, but it is only meant to push information to an endpoint rather than change anything on the host system. I tested running the script with all of these limitations and it fulfilled the intended purpose just fine, and the nice part is that you should be good to modify the script if you want to, say, use it with a different provider or do some local changes, with little risk to your system as long as you use `systemctl --user start <SERVICE_NAME>.service`.

For more information, see [`systemd.exec`](https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html).

## Installation

You can run the following to copy the files as is:

```bash
mkdir -p $HOME/.local/bin/cf-ddns/
mkdir -p $HOME/.config/cf-ddns/
mkdir -p $HOME/.config/systemd/user/

# It's a simple bash script, modify it as you see fit
cp cf-ddns.sh $HOME/.local/bin/cf-ddns/cf-ddns.sh

# If you want multiple sites to be updated, you may want to make multiple of these .service files with different names
cp cf-ddns.service $HOME/.config/systemd/user/cf-ddns.service

# You may want to make multiple of these files when making multiple .service units
cp example.env $HOME/.config/cf-ddns/cf-ddns.env
chmod 700 $HOME/.config/cf-ddns/cf-ddns.env

# You may want to change the frequency (default is hourly)
cp cf-ddns.timer $HOME/.config/systemd/user/cf-ddns.timer

# Remember to update this file with the names of your other .service files
cp cf-ddns.target $HOME/.config/systemd/user/cf-ddns.target
```

Then, you can run the following to have `systemd` work with them.

```bash
# Allows the service to execute after each boot
systemctl --user enable cf-ddns.service

# Enables the timer
systemctl --user enable cf-ddns.timer
```

## Environment Variables

The cf-ddns.service file defines a `EnvironmentFile` that contains the requisite variables. The script is run with the environment variables defined in the file, so it must be readable by the user and ideally no one else.

```conf
CLOUDFLARE_API_TOKEN=   # A token with DNS:Edit permissions on the zone
CLOUDFLARE_EMAIL=       # Your Cloudflare email
ZONE_ID=                # You can find this in the zone's dashboard
DNS_RECORD_ID=          # You can find this in the account audit logs when creating a record
DNS_NAME=               # The FQDN (e.g., my-server.example.com)

# Defaults
PROXIED=true
TTL=3600
```

## Resources

- https://developers.cloudflare.com/api/resources/dns/subresources/records/methods/get/
- https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html
