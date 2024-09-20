#!/bin/bash

domain=$1
RED="\033[1;31m"
RESET="\033[0m"

subdomain_path=$domain/subdomains
screenshot_path=$domain/screenshots
scan_path=$domain/scans

if [ ! -d "$domain" ];then
	mkdir $domain
fi
if [ ! -d "$subdomain_path" ];then
        mkdir $subdomain_path
fi
if [ ! -d "$screenshot_path" ];then
        mkdir $screenshot_path
fi
if [ ! -d "$scan_path" ];then
        mkdir $scan_path
fi

# launch subfinder
echo -e "${RED} [+] Launching subfinder ... ${RESET}"
subfinder -d $domain > $subdomain_path/found.txt

# launch assetfinder
echo -e "${RED} [+] Launching assetfinder ... ${RESET}"
assetfinder $domain | grep $domain >> $subdomain_path/found.txt

# amass will take some time to run
#echo -e "${RED} [+] Launching amass ... ${RESET}"
#amass enum -d $domain >> $subdomain_path/found.txt

# cat out our find subdomain, grep the domain, sort it uniquely, run httprobe to see whats alive, grep out https, removes any https:// in front of the domain and output the file to alive.txt
echo -e "${RED} [+] Finding alive subdomains ... ${RESET}"
cat $subdomain_path/found.txt | grep $domain | sort -u | httprobe -prefer-https | grep https | sed 's/https\?:\/\///' | tee -a $subdomain_path/alive.txt

# this takes screenshots
echo -e "${RED} [+] Taking screenshots of alive subdomains ... ${RESET}"
gowitness file -f $subdomain_path/alive.txt -P $screenshot_path/ --no-http

# for nmap you can use -A or any preferences
echo -e "${RED} [+] Running on alive subdomains ... ${RESET}"
nmap -iL $subdomain_path/alive.txt -T4 -p- -oN $scan_path/nmap.txt
