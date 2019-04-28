# Copyright (c) 2015 Peter Varkoly <peter@varkoly.de> Nürnberg, Germany.  All rights reserved.

usage ()
{
        echo '/usr/share/oss/tools/radius/setup.sh [ -h -d -r ]'
        echo 'Optional parameters :'
        echo '          -h,   --help         Display this help.'
        echo '          -d,   --description  Display the descriptiont.'
        echo '          -r,   --force-reset  Setup the oss-radius new. Creates new certificates.'

}

RESET=0

while [ "$1" != "" ]; do
    case $1 in
        -r | --force-reset )    RESET=1
                                ;;
        -d | --description )    usage
                                exit;;
        -h | --help )           usage
                                exit;;
    esac
    shift
done

test -e /etc/sysconfig/schoolserver || exit 0
. /etc/sysconfig/schoolserver

#Enable ntlm auth
NtlmEnabled=$( grep 'ntlm auth = yes' /etc/samba/smb.conf )
if [ -z "${NtlmEnabled}" ]; then
	sed -i '/\[global\]/a ntlm auth = yes' /etc/samba/smb.conf 
	systemctl restart samba
fi

cd /usr/share/oss/templates/radius/
for i in $( find -type f )
do
	if [ "$i" = "clients.conf" ]; then
		continue
	else
		cp /etc/raddb/$i /etc/raddb/$i.$DATE
		cp $i /etc/raddb/$i
        fi	       
done
ln -fs  ../mods-available/set_logged_on /etc/raddb/mods-enabled/set_logged_on

sed -i "s#SCHOOL_SERVER_NET#${SCHOOL_SERVER_NET}#" /etc/raddb/clients.conf
sed -i "s#SCHOOL_WORKGROUP#${SCHOOL_WORKGROUP}#"   /etc/raddb/mods-available/mschap

systemctl enable  radiusd
systemctl restart radiusd
