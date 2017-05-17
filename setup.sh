#!/bin/bash

# tell nsswitch to get host resolution from dns though.
svccfg -s dns/client setprop config/nameserver = net_address: '(192.168.8.8 192.168.8.9)'
svccfg -s dns/client setprop config/domain = astring: '("dom.lan")'
svccfg -s dns/client setprop config/search = astring: '("dom.lan")'
svcadm enable dns/client
svcadm enable system/name-service-cache
svcadm refresh dns/client
svcadm restart dns/client

# set our pkg repo to /net/blazar/pkgrepo
pkg set-publisher -G '*' -M '*' -g /net/blazar/pkgrepo solaris

# get some packages.
pkg install --accept system/security/kerberos-5 samba jdk-8 git mercurial gnu-tar
sharectl set -p ddns_enable=true smb

# join the kerberos domain
kclient -R DOM.LAN -k 192.168.8.8,192.168.8.9 -a administrator -T ms_ad -p ./profile.krb5

# point nameservice switch at the ad dc's
ldapclient manual \
        -a credentialLevel=proxy \
        -a authenticationMethod=simple \
	-a proxyDN=cn=unixproxy,ou=users,ou=unix,dc=dom,dc=lan \
	-a proxyPassword=V01dV01dV01d \
        -a defaultSearchBase=dc=dom,dc=lan \
        -a defaultSearchScope=sub \
        -a domainName=DOM.LAN \
        -a defaultServerList="192.168.8.8,192.168.8.9" \
        -a "followReferrals=false" \
        -a attributeMap=group:userpassword=userPassword \
        -a attributeMap=group:memberuid=memberUid \
        -a attributeMap=group:gidnumber=gidNumber \
        -a attributeMap=passwd:gecos=description \
        -a attributeMap=passwd:gidnumber=gidNumber \
        -a attributeMap=passwd:uidnumber=uidNumber \
        -a attributeMap=passwd:homedirectory=unixHomeDirectory \
        -a attributeMap=passwd:loginshell=loginShell \
        -a attributeMap=shadow:shadowflag=shadowFlag \
        -a attributeMap=shadow:userpassword=userPassword \
        -a objectClassMap=group:posixGroup=group \
        -a objectClassMap=passwd:posixAccount=user \
        -a objectClassMap=shadow:shadowAccount=user \
        -a serviceSearchDescriptor=passwd:dc=dom,dc=lan?sub \
        -a serviceSearchDescriptor=group:dc=dom,dc=lan?sub

# re-tell nsswitch to get host resolution from dns though.
svccfg -s dns/client setprop config/nameserver = net_address: '(192.168.8.8 192.168.8.9)'
svccfg -s dns/client setprop config/search = astring: '("dom.lan")'
svcadm refresh dns/client
svcadm restart dns/client

svccfg -s name-service/switch setprop config/ipnodes = astring: '("files dns")'
svccfg -s name-service/switch setprop config/host = astring: '("files dns")'
svccfg -s name-service/switch setprop config/password = astring: '("files ldap")'
svccfg -s name-service/switch setprop config/group = astring: '("files ldap")'
svccfg -s name-service/switch setprop config/network = astring: '("files")'
svccfg -s name-service/switch setprop config/protocol = astring: '("files")'
svccfg -s name-service/switch setprop config/rpc = astring: '("files")'
svccfg -s name-service/switch setprop config/ether = astring: '("files")'
svccfg -s name-service/switch setprop config/netmask = astring: '("files")'
svccfg -s name-service/switch setprop config/bootparam = astring: '("files")'
svccfg -s name-service/switch setprop config/publickey = astring: '("files")'
svccfg -s name-service/switch setprop config/netgroup = astring: '("files")'
svccfg -s name-service/switch setprop config/automount = astring: '("files")'
svccfg -s name-service/switch setprop config/alias = astring: '("files")'
svccfg -s name-service/switch setprop config/service = astring: '("files")'
svccfg -s name-service/switch setprop config/printer = astring: '("user files")'
svccfg -s name-service/switch setprop config/project = astring: '("files")'
svccfg -s name-service/switch setprop config/auth_attr = astring: '("files")'
svccfg -s name-service/switch setprop config/prof_attr = astring: '("files")'
svccfg -s name-service/switch setprop config/tnrhtp = astring: '("files")'
svccfg -s name-service/switch setprop config/tnrhdb = astring: '("files")'
svccfg -s name-service/switch listprop config
svcadm refresh name-service/switch
svcadm restart name-service/switch
svcadm restart /network/ldap/client

# place some files into the right locations.
cat ./etc/ssh/sshd_config > /etc/ssh/sshd_config
cat ./etc/nfssec.conf > /etc/nfssec.conf
cat ./etc/security/policy.conf > /etc/security/policy.conf
cat ./etc/auto_master > /etc/auto_master
cat ./etc/auto_home > /etc/auto_home

# bounce some daemons
svcadm restart ssh 
svcadm restart autofs

# join the samba domain
#smbadm join -u Administrator DOM.LAN

# defaults to /etc/profile
echo 'export PATH=~/bin:/usr/sbin:$PATH' >> /etc/profile
echo "export PS1='\u@\h:\W % '" >> /etc/profile
echo "alias vi=vim" >> /etc/profile
echo "alias tar=gtar" >> /etc/profile
echo "alias sort=gsort" >> /etc/profile
