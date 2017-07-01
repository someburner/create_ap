###

```

## deploy or staging
dst host 45.32.67.231 or dst host 45.32.93.103

```


## Pinging Router

```
PING 192.168.1.1 (192.168.1.1): 56 data bytes
64 bytes from 192.168.1.1: icmp_seq=0 ttl=64 time=5.117 ms
64 bytes from 192.168.1.1: icmp_seq=1 ttl=64 time=3.233 ms
64 bytes from 192.168.1.1: icmp_seq=2 ttl=64 time=2.359 ms
64 bytes from 192.168.1.1: icmp_seq=3 ttl=64 time=14.694 ms
64 bytes from 192.168.1.1: icmp_seq=4 ttl=64 time=4.153 ms
64 bytes from 192.168.1.1: icmp_seq=5 ttl=64 time=5.309 ms
64 bytes from 192.168.1.1: icmp_seq=6 ttl=64 time=5.694 ms
64 bytes from 192.168.1.1: icmp_seq=7 ttl=64 time=2.303 ms
64 bytes from 192.168.1.1: icmp_seq=8 ttl=64 time=2.374 ms
64 bytes from 192.168.1.1: icmp_seq=9 ttl=64 time=6.683 ms
64 bytes from 192.168.1.1: icmp_seq=10 ttl=64 time=8.985 ms
64 bytes from 192.168.1.1: icmp_seq=11 ttl=64 time=4.067 ms
64 bytes from 192.168.1.1: icmp_seq=12 ttl=64 time=3.119 ms
64 bytes from 192.168.1.1: icmp_seq=13 ttl=64 time=127.024 ms
64 bytes from 192.168.1.1: icmp_seq=14 ttl=64 time=46.464 ms
64 bytes from 192.168.1.1: icmp_seq=15 ttl=64 time=517.594 ms
64 bytes from 192.168.1.1: icmp_seq=16 ttl=64 time=71.215 ms
64 bytes from 192.168.1.1: icmp_seq=17 ttl=64 time=24.227 ms
64 bytes from 192.168.1.1: icmp_seq=18 ttl=64 time=43.053 ms
64 bytes from 192.168.1.1: icmp_seq=19 ttl=64 time=28.720 ms
64 bytes from 192.168.1.1: icmp_seq=20 ttl=64 time=23.082 ms
64 bytes from 192.168.1.1: icmp_seq=21 ttl=64 time=6.779 ms
64 bytes from 192.168.1.1: icmp_seq=22 ttl=64 time=7.913 ms
64 bytes from 192.168.1.1: icmp_seq=23 ttl=64 time=21.345 ms
64 bytes from 192.168.1.1: icmp_seq=24 ttl=64 time=7.729 ms
64 bytes from 192.168.1.1: icmp_seq=25 ttl=64 time=5.657 ms
```


## Pinging Deploy


```
macbook-t:~ laux$ ping 45.32.67.231
PING 45.32.67.231 (45.32.67.231): 56 data bytes
92 bytes from router.local (192.168.1.1): Redirect Host(New addr: 192.168.1.201)
Vr HL TOS  Len   ID Flg  off TTL Pro  cks      Src      Dst
 4  5  00 0054 a915   0 0000  3f  01 9fd3 192.168.1.17  45.32.67.231

64 bytes from 45.32.67.231: icmp_seq=0 ttl=48 time=196.402 ms
92 bytes from router.local (192.168.1.1): Redirect Host(New addr: 192.168.1.201)
Vr HL TOS  Len   ID Flg  off TTL Pro  cks      Src      Dst
 4  5  00 0054 d40c   0 0000  3f  01 74dc 192.168.1.17  45.32.67.231

64 bytes from 45.32.67.231: icmp_seq=1 ttl=48 time=195.552 ms
92 bytes from router.local (192.168.1.1): Redirect Host(New addr: 192.168.1.201)
Vr HL TOS  Len   ID Flg  off TTL Pro  cks      Src      Dst
 4  5  00 0054 fa83   0 0000  3f  01 4e65 192.168.1.17  45.32.67.231

64 bytes from 45.32.67.231: icmp_seq=2 ttl=48 time=195.599 ms
92 bytes from router.local (192.168.1.1): Redirect Host(New addr: 192.168.1.201)
Vr HL TOS  Len   ID Flg  off TTL Pro  cks      Src      Dst
 4  5  00 0054 c89f   0 0000  3f  01 8049 192.168.1.17  45.32.67.231

64 bytes from 45.32.67.231: icmp_seq=3 ttl=48 time=196.287 ms
92 bytes from router.local (192.168.1.1): Redirect Host(New addr: 192.168.1.201)
Vr HL TOS  Len   ID Flg  off TTL Pro  cks      Src      Dst
 4  5  00 0054 f711   0 0000  3f  01 51d7 192.168.1.17  45.32.67.231

64 bytes from 45.32.67.231: icmp_seq=4 ttl=48 time=199.037 ms
92 bytes from router.local (192.168.1.1): Redirect Host(New addr: 192.168.1.201)
Vr HL TOS  Len   ID Flg  off TTL Pro  cks      Src      Dst
 4  5  00 0054 b1ed   0 0000  3f  01 96fb 192.168.1.17  45.32.67.231

64 bytes from 45.32.67.231: icmp_seq=5 ttl=48 time=194.496 ms
64 bytes from 45.32.67.231: icmp_seq=6 ttl=48 time=193.411 ms
92 bytes from router.local (192.168.1.1): Redirect Host(New addr: 192.168.1.201)
Vr HL TOS  Len   ID Flg  off TTL Pro  cks      Src      Dst
 4  5  00 0054 e2c6   0 0000  3f  01 6622 192.168.1.17  45.32.67.231

64 bytes from 45.32.67.231: icmp_seq=7 ttl=48 time=201.555 ms
64 bytes from 45.32.67.231: icmp_seq=8 ttl=48 time=190.488 ms
64 bytes from 45.32.67.231: icmp_seq=9 ttl=48 time=199.053 ms
92 bytes from router.local (192.168.1.1): Redirect Host(New addr: 192.168.1.201)
Vr HL TOS  Len   ID Flg  off TTL Pro  cks      Src      Dst
 4  5  00 0054 fdb9   0 0000  3f  01 4b2f 192.168.1.17  45.32.67.231

64 bytes from 45.32.67.231: icmp_seq=10 ttl=48 time=198.965 ms
^C
--- 45.32.67.231 ping statistics ---
11 packets transmitted,
11 packets received,
0.0% packet loss
round-trip

min = 190.488
avg = 196.440
max = 201.555
stddev = 2.954 ms



```




#### EOF
