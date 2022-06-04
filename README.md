# v-rising-terraform

docker run -d --name='vrising' \
--net='bridge' \
-e TZ="America/New_York" \
-e SERVERNAME="vrisingmorelikedrising" \
-v '/root/vrising/server':'/mnt/vrising/server':'rw' \
-v '/root/vrising/persistentdata':'/mnt/vrising/persistentdata':'rw' \
-p 9876:9876/udp \
-p 9877:9877/udp \
'trueosiris/vrising'