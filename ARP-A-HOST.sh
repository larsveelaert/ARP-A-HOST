#DEPENDENCIES: arp-scan
#take $1 (first argument of the script) -> file with mac adresses + hostname

tmpfile=$(mktemp /tmp/DYNAMIC-RESOLVE.XXXXXX) #tmp file for temporary results

#clear lines form the previous run in /etc/hosts file
sed -i.bak '/DYNAMIC_RESOLVE/d' /etc/hosts

#use the tool arp-scan to find all the devices on the network
if ! [ -z $2 ]; then
 arp-scan -l --localnet --interface=$2 >> $tmpfile
else
 for line in $(ip link | cut -d " " -f 2); do
 interface=${line::-1}
 arp-scan -l --localnet --interface=$interface 2>/dev/null >> $tmpfile
 done
 #TODO interfaceoption -> default wlan
fi
echo Arpscan Finished... Filtering results...

#reading the results one by one
while read -r line
do
 MAC=$(echo $line | cut -d " " -f 1)
 NAME=$(echo $line | cut -d " " -f 2)
 #grep MAC from ARP cache
 IP=$(cat $tmpfile | grep $MAC | cut -d$'\t' -f 1)

if ! [ -z "${IP}" ]; then
 echo Found $NAME at $IP! Adding to /etc/hosts...
 echo "$IP $NAME $NAME #DYNAMIC_RESOLVE">>/etc/hosts #If the MAC is found, add to the /etc/hosts file
 fi 
done < "$1"
echo Done with discovering hosts
