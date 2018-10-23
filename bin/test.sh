#/bin/bash
set -x
#========================================================================
DEBUG="-v"

# TARGET=audit_admin
: ${HOSTS:="hosts"}
#========================================================================

PATH_ANSIBLE="$(dirname $0)"/..

function help {
    echo "usage: $0 [ add the password of the remote user... ]"
}

if [[ "$#" -le 0 ]]; then
    help
    exit 1
fi

if [ ! -f ~/.ssh/id_rsa ]; then
	ssh-keygen -q -f ~/.ssh/id_rsa -N ""
	cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
	ssh -o StrictHostKeyChecking=no localhost "pwd" < /dev/null
fi

rpm -qa sshpass > epelx
if [[ ! -s epelx ]]; then
   sudo yum install sshpass -y
fi

cd ./weblogic-automation

pass=$1
awk -F' ' 'FNR > 1 { print  $1 }' hosts > sshcopy
awk NF sshcopy > linux
awk -v password="$pass" '{print "sshpass -p " password " ssh-copy-id -o StrictHostKeyChecking=no " $1}' linux > sshcopy
chmod u+x sshcopy
./sshcopy

cd ..


ansible-playbook \
        $DEBUG \
        -i "$PATH_ANSIBLE"/$HOSTS \
        -l weblogic-01 \
        --extra-vars "ansible_become_pass=$1" \
        "$PATH_ANSIBLE"/test.yml  
