# Network Diagram
```
              10.10.1.0/24        10.15.1.0/24           10.20.1.0/24
              gw 10.10.1.1                               gw 10.20.1.1

          ┌───── left ─────┐  ┌───── transit ─────┐ ┌──────right ────┐
          │                │  │                   │ │                │
          │                │  │                   │ │                │
        host1            router1                router2            host2

    10.10.1.10          10.10.1.1              10.20.1.1        10.20.1.10
                        10.15.1.1              10.15.1.2
```

# Packet flow

Don't forget that we see both ends of a transmission - the source sending
the packet and the destination receiving it.

Containers have their own IP stack and ARP cache, however the exact
behaviour of the cache is the Linux kernel source.

## `host1` finds MAC of gateway IP:
```
host1-1    | 07:39:56.213015 22:2d:27:c5:d2:52 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.10.1.1 tell 10.10.1.10, length 28
router1-1  | 07:39:56.213068 22:2d:27:c5:d2:52 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.10.1.1 tell 10.10.1.10, length 28
router1-1  | 07:39:56.213184 66:47:bb:40:3f:1c > 22:2d:27:c5:d2:52, ethertype ARP (0x0806), length 42: Reply 10.10.1.1 is-at 66:47:bb:40:3f:1c, length 28
host1-1    | 07:39:56.213192 66:47:bb:40:3f:1c > 22:2d:27:c5:d2:52, ethertype ARP (0x0806), length 42: Reply 10.10.1.1 is-at 66:47:bb:40:3f:1c, length 28
```

## `host1` forwards ping to `host2` via `router1`:
```
host1-1    | 07:39:56.213198 22:2d:27:c5:d2:52 > 66:47:bb:40:3f:1c, ethertype IPv4 (0x0800), length 98: 10.10.1.10 > 10.20.1.10: ICMP echo request, id 7756, seq 1, length 64
router1-1  | 07:39:56.213201 22:2d:27:c5:d2:52 > 66:47:bb:40:3f:1c, ethertype IPv4 (0x0800), length 98: 10.10.1.10 > 10.20.1.10: ICMP echo request, id 7756, seq 1, length 64
```

## `router2` looks up MAC of `host2`:
```
router2-1  | 07:39:56.213266 c2:b6:a4:a7:ee:66 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.20.1.10 tell 10.20.1.1, length 28
host2-1    | 07:39:56.213276 c2:b6:a4:a7:ee:66 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.20.1.10 tell 10.20.1.1, length 28
host2-1    | 07:39:56.213291 72:5b:b9:18:0b:d6 > c2:b6:a4:a7:ee:66, ethertype ARP (0x0806), length 42: Reply 10.20.1.10 is-at 72:5b:b9:18:0b:d6, length 28
router2-1  | 07:39:56.213294 72:5b:b9:18:0b:d6 > c2:b6:a4:a7:ee:66, ethertype ARP (0x0806), length 42: Reply 10.20.1.10 is-at 72:5b:b9:18:0b:d6, length 28
```

## `router2` forwards ping to `host2`:
```
router2-1  | 07:39:56.213296 c2:b6:a4:a7:ee:66 > 72:5b:b9:18:0b:d6, ethertype IPv4 (0x0800), length 98: 10.10.1.10 > 10.20.1.10: ICMP echo request, id 7756, seq 1, length 64
host2-1    | 07:39:56.213324 c2:b6:a4:a7:ee:66 > 72:5b:b9:18:0b:d6, ethertype IPv4 (0x0800), length 98: 10.10.1.10 > 10.20.1.10: ICMP echo request, id 7756, seq 1, length 64
```

## `host2` sends ping response via `router2`, `router1`, and `host1`:
```
host2-1    | 07:39:56.213353 72:5b:b9:18:0b:d6 > c2:b6:a4:a7:ee:66, ethertype IPv4 (0x0800), length 98: 10.20.1.10 > 10.10.1.10: ICMP echo reply, id 7756, seq 1, length 64
router2-1  | 07:39:56.213356 72:5b:b9:18:0b:d6 > c2:b6:a4:a7:ee:66, ethertype IPv4 (0x0800), length 98: 10.20.1.10 > 10.10.1.10: ICMP echo reply, id 7756, seq 1, length 64
router1-1  | 07:39:56.213366 66:47:bb:40:3f:1c > 22:2d:27:c5:d2:52, ethertype IPv4 (0x0800), length 98: 10.20.1.10 > 10.10.1.10: ICMP echo reply, id 7756, seq 1, length 64
host1-1    | 07:39:56.213369 66:47:bb:40:3f:1c > 22:2d:27:c5:d2:52, ethertype IPv4 (0x0800), length 98: 10.20.1.10 > 10.10.1.10: ICMP echo reply, id 7756, seq 1, length 64
```

## Some post-ping directed ARP requests presumably to keep the cache fresh:
```
router1-1  | 07:40:01.335882 66:47:bb:40:3f:1c > 22:2d:27:c5:d2:52, ethertype ARP (0x0806), length 42: Request who-has 10.10.1.10 tell 10.10.1.1, length 28
host2-1    | 07:40:01.335962 72:5b:b9:18:0b:d6 > c2:b6:a4:a7:ee:66, ethertype ARP (0x0806), length 42: Request who-has 10.20.1.1 tell 10.20.1.10, length 28
host1-1    | 07:40:01.336163 66:47:bb:40:3f:1c > 22:2d:27:c5:d2:52, ethertype ARP (0x0806), length 42: Request who-has 10.10.1.10 tell 10.10.1.1, length 28
router2-1  | 07:40:01.336191 72:5b:b9:18:0b:d6 > c2:b6:a4:a7:ee:66, ethertype ARP (0x0806), length 42: Request who-has 10.20.1.1 tell 10.20.1.10, length 28
host1-1    | 07:40:01.336242 22:2d:27:c5:d2:52 > 66:47:bb:40:3f:1c, ethertype ARP (0x0806), length 42: Reply 10.10.1.10 is-at 22:2d:27:c5:d2:52, length 28
router1-1  | 07:40:01.336285 22:2d:27:c5:d2:52 > 66:47:bb:40:3f:1c, ethertype ARP (0x0806), length 42: Reply 10.10.1.10 is-at 22:2d:27:c5:d2:52, length 28
router2-1  | 07:40:01.336280 c2:b6:a4:a7:ee:66 > 72:5b:b9:18:0b:d6, ethertype ARP (0x0806), length 42: Reply 10.20.1.1 is-at c2:b6:a4:a7:ee:66, length 28
host2-1    | 07:40:01.336290 c2:b6:a4:a7:ee:66 > 72:5b:b9:18:0b:d6, ethertype ARP (0x0806), length 42: Reply 10.20.1.1 is-at c2:b6:a4:a7:ee:66, length 28
```

# Other stuff

Interestingly, on startup each host does an ARP request for its own IP,
presumbly to check that no-one else has been assigned that address:
```
host2-1    | 07:36:51.768231 c2:b6:a4:a7:ee:66 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.20.1.1 tell 10.20.1.1, length 28
host2-1    | 07:36:51.805284 72:5b:b9:18:0b:d6 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.20.1.10 tell 10.20.1.10, length 28
router2-1  | 07:36:51.768207 c2:b6:a4:a7:ee:66 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.20.1.1 tell 10.20.1.1, length 28
router2-1  | 07:36:51.805318 72:5b:b9:18:0b:d6 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.20.1.10 tell 10.20.1.10, length 28
host1-1    | 07:36:51.806978 22:2d:27:c5:d2:52 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.10.1.10 tell 10.10.1.10, length 28
host1-1    | 07:36:51.824644 66:47:bb:40:3f:1c > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.10.1.1 tell 10.10.1.1, length 28
router1-1  | 07:36:51.806996 22:2d:27:c5:d2:52 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.10.1.10 tell 10.10.1.10, length 28
router1-1  | 07:36:51.824614 66:47:bb:40:3f:1c > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.10.1.1 tell 10.10.1.1, length 28
router2-1  | 07:36:52.734116 c2:b6:a4:a7:ee:66 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.20.1.1 tell 10.20.1.1, length 28
host2-1    | 07:36:52.734145 c2:b6:a4:a7:ee:66 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.20.1.1 tell 10.20.1.1, length 28
host2-1    | 07:36:52.799482 72:5b:b9:18:0b:d6 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.20.1.10 tell 10.20.1.10, length 28
router2-1  | 07:36:52.799509 72:5b:b9:18:0b:d6 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.20.1.10 tell 10.20.1.10, length 28
host1-1    | 07:36:52.818581 22:2d:27:c5:d2:52 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.10.1.10 tell 10.10.1.10, length 28
host1-1    | 07:36:52.830293 66:47:bb:40:3f:1c > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.10.1.1 tell 10.10.1.1, length 28
router1-1  | 07:36:52.818620 22:2d:27:c5:d2:52 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.10.1.10 tell 10.10.1.10, length 28
router1-1  | 07:36:52.830267 66:47:bb:40:3f:1c > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.10.1.1 tell 10.10.1.1, length 28
```
