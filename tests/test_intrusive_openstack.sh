#!/bin/bash

echo -e ">>> Running Intrusive Test"

INCLUDEOS_SRC=${INCLUDEOS_SRC-~/IncludeOS}
INCLUDEOS_TOOLS=${INCLUDEOS_TOOLS-~/includeos-tools}
NAME=intrusive_test_nightly
IMAGE_NAME=ubuntu16.04
KEY_PAIR_NAME="master"

# Preemptive checks to see if there is openstack support
echo -e "\n\n>>> Checking if the required Openstack tools are installed"
errors=0
which openstack > /dev/null 2>&1 || { echo "Openstack cli is required"; errors=$((errors + 1)); }; 
if [ $errors -gt 0 ]; then
	echo You do not have the required programs for running the Openstack test, Exiting
	exit 1
fi

# Create trap to ensure clean up
function clean {
	echo -e "\n\n>>> Performing clean up"
	openstack server delete $NAME 
	echo $errors
}
trap clean EXIT

echo Starting instance
openstack server create --image $IMAGE_NAME --flavor small --key-name $KEY_PAIR_NAME $NAME --wait
IP=$(openstack server list -c Networks -f value --name $NAME | cut -d " " -f 2)
echo Instance started on IP: $IP

timeout=0
until ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $IP exit || [ "$timeout" -gt 30 ]
do
	sleep 1
	timeout=$((timeout+1))
done

if [ "$timeout" -gt 30 ]; then
	echo No connection made to instance, Exiting
	exit 1
fi

ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $IP '
	export CC="clang-3.8"
	export CXX="clang++-3.8"
	export INCLUDEOS_SRC=~/workspace
	export INCLUDEOS_PREFIX=~/workspace/IncludeOS_install
	git clone https://github.com/includeos/includeos-tools.git

	mkdir workspace; cd workspace
	wget -q 192.168.0.18:8080/built.tar.gz
	tar -zxf built.tar.gz

	pgrep "apt-get"

	until [ $? -ne 0 ]; do
		 sleep 1
		 pgrep "apt-get"
	done

	~/includeos-tools/install/install_only_dependencies.sh
	cd test
	./testrunner.py -t intrusive'

errors=$?
# Exit
if [ $errors -gt 0 ]; then
    echo -e "\nERROR: Intrusive tests did not pass"
else
    echo -e "\nPASS: Intrusive tests successful"
fi
exit $errors
