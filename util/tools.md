
## tcconfig

```
sudo pip install tcconfig

```

docs:
http://tcconfig.readthedocs.io/en/latest/pages/usage/tcset/index.html


### Backup/Restore

### Show

```
# tcset --device eth0 --delay 10 --delay-distro 2  --loss 0.01 --rate 0.25M --network 192.168.0.10 --port 8080
# tcset --device eth0 --delay 1 --loss 0.02 --rate 500K --direction incoming
# tcshow --device eth0
```



jeffrey@jeff-P50:~$
mosquitto_pub -h staging.flumetech.com -u device -P 28asfnvFensL -t /responses/56F8A39248B956DD -m '{"timestamp":1494566481,"args":{"branch":"pilot-2.1","sha":"7e19df6","rom":2},"command":6}'

jeffrey@jeff-P50:~$
mosquitto_pub -h staging.flumetech.com -u device -P 28asfnvFensL -t /responses/56F8A39248B956DD -m '{"timestamp":1494566481,"args":{"branch":"pilot","sha":"3195f74","name":"amrdebug"},"command":7}'

jeffrey@jeff-P50:~$


Address: jeff-P50 (44:85:00:ef:ba:87)
### Randomly drop 1% of packets on port 1883 for ap1 and device with MAC=60:01:94:1a:66:08

Internet Protocol Version 4, Src: jeff-P50 (192.168.1.223), Dst: 45.32.67.231.vultr.com (45.32.67.231)


Internet Protocol Version 4, Src: deploy.flumetech.com (45.32.67.231), Dst: jeff-P50 (192.168.1.223)
### EOF
