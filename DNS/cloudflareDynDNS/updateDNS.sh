#!/bin/bash

print_help() {
  echo -e "
  Use those Prameters:
  -t TOKEN        Auth-Token
  -m MAIL         Account E-Mail
  -z ZONE-ID      Zone-ID
  -r RECORD-ID    DNS-Record-ID
  -d FQDN         DOMAIN as FQDN
  -h              Show help
  -6              AAAA-Record for IPv6 
  -4              A-Record for IPv4 
  "
}

#test for curl
test_curl() {
  which curl 1>/dev/null
  if [ $? -ne 0 ];then
    echo "Please install curl"
    exit 1
  fi
}

get_externalIP() {
  EXTIP="0.0.0.0"
}

# INIT Test
if [ $# -eq 0 ];then
  print_help;exit
fi
test_curl

# OPTIONS
IP_VERSION=0
while getopts ':t:m:z:r:d:h46' OPTION
do
  case ${OPTION} in
    t) API_TOKEN="$OPTARG";;
    m) MAIL="$OPTARG";;
    z) ZONEID="$OPTARG";;
    r) DNS_RECORD="$OPTARG";;
    d) DOMAIN="$OPTARG";;
    6) IP_VERSION=$(( $IP_VERSION + 6 ));;
    4) IP_VERSION=$(( $IP_VERSION + 4 ));;
    h) print_help;exit;;
    *) print_help;exit;;
  esac
done

#MAIN

# manual override for statick command
#API_TOKE=
#DOMAIN=
#MAIL=
#DNS_RECORD=

# check if all Options are SET

if [ -z $API_TOKEN ];then
  if [ -z $MAIL ];then
    if [ -z $ZONEID ];then
      if [ -z $DNS_RECORD ];then
        if [ -z $DOMAIN ];then
          VALIDE=1
        fi
      fi
    fi
  fi
else
  echo "Argument missing: ";print_help;exit;
fi

if [ $VALIDE -eq 1 ];then
  # check IP Version
  if [[ $IP_VERSION -eq "0" || $IP_VERSION -eq "4" ]];then
    echo "IPv4 detected"
    TYPE="A"
    MESSAGE="{'name':'$DOMAIN','type':'$TYPE','content':'$EXTIP4','ttl':1}"
  elif [ $IP_VERSION -eq "6" ];then
    echo "IPv6 detected"
    TYPE="AAAA"
    MESSAGE="{'name':'$DOMAIN','type':'$TYPE','content':'$EXTIP6','ttl':1}"
  elif [ $IP_VERSION -eq "10" ];then
    echo "IPv4 and IPv6 detected"
    MESSAGE="{1:{'name':'$DOMAIN','type':'$TYPE','content':'$EXTIP4','ttl':1},2:{'name':'$DOMAIN','type':'AAAA','content':'$EXTIP6','ttl':1}"
  else;
    echo "To many -4 -6 "
  fi


  # API CALL
  curl https://api.cloudflare.com/client/v4/zones/$ZONEID/dns_records/$DNS_RECORD \
      -X PUT \
      -H 'Content-Type: application/json' \
      -H "X-Auth-Email: $MAIL" \
      -H "X-Auth-Key: $API_TOKEN" \
      -d $MESSAGE
fi
