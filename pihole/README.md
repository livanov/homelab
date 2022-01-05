On Ubuntu we need to follow extra steps from [here](https://github.com/pi-hole/docker-pi-hole#installing-on-ubuntu)

```
sudo sed -r -i.orig 's/#?DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
sudo systemctl restart systemd-resolved
```

Add [regex block list](https://github.com/mmotti/pihole-regex/blob/master/regex.list) by going to `Group Management -> Domains -> RegEx filter`

Add [whitelist](https://raw.githubusercontent.com/mmotti/pihole-regex/master/whitelist.list) to fix false positives by going to `Group Management -> Adlists`
