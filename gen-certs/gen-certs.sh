#!/bin/sh
#
# This is simplifing version of certificates generator of Openssl project for FreeBSD
#

gen::check::req() {
        if [ ! -f "in.indexer.lst" ] || [ ! -f "in.server.lst" ] || [ ! -f "in.dashboard.lst" ]; then
		echo "#########################################################"
		echo "in.indexer.lst, in.server.lst or in.dashboard.lst files not found."
		echo "#########################################################"

		exit;
	fi

	for f in $(echo "in.indexer.lst in.server.lst in.dashboard.lst")
	do
		grep -e "^[^#].*_ip=" ${f}

		if [ $? -gt 0 ]; then
			echo "#################################################"
			echo "${f} is empty or not contains valid entries."
			echo "#################################################"

			exit;
		fi
	done
}

gen::root::ca() {
	echo "#############################"
	echo "Generating RootCa certificate"
	echo "#############################"
	$(openssl req -x509 -new -nodes -newkey rsa:2048 -keyout out-certificates/root-ca.key \
		-out out-certificates/root-ca.pem -batch -subj '/OU=Openssl/O=Openssl/L=California/' -days 3650)
}

gen::admin::cert() {
	echo "############################"
        echo "Generating Admin certificate"
        echo "############################"

	$(openssl genrsa -out out-certificates/admin-key-temp.pem 2048)

	$(openssl pkcs8 -inform PEM -outform PEM -in out-certificates/admin-key-temp.pem \
		-topk8 -nocrypt -v1 PBE-SHA1-3DES -out out-certificates/admin-key.pem)

	$(openssl req -new -key out-certificates/admin-key.pem -out out-certificates/admin.csr \
		-batch -subj '/C=US/L=California/O=Openssl/OU=Openssl/CN=admin')

	$(openssl x509 -days 3650 -req -in out-certificates/admin.csr -CA out-certificates/root-ca.pem \
		-CAkey out-certificates/root-ca.key -CAcreateserial -sha256 -out out-certificates/admin.pem)
}

gen::cert::config() {
	local _name="$1"
	local _ip="$2"

	echo "###################################"
        echo "Generating ${_name} config file"
        echo "###################################"

	$(cat cert.conf.template | sed -e "s|%%name%%|${_name}|g" -e "s|%%ip%%|${_ip}|g" > "out-certificates/${_name}.conf")
}

gen::cert() {
	local _name="$1"
	local _ip="$2"

	if [ ! -f "out-certificates/${_name}-key.pem" ]; then
		gen::cert::config "${_name}" "${_ip}"

		echo "####################################"
	        echo "Generating ${_name} certificate"
	        echo "####################################"

		$(openssl req -new -nodes -newkey rsa:2048 -keyout out-certificates/${_name}-key.pem \
			-out out-certificates/${_name}.csr -config out-certificates/${_name}.conf)

		$(openssl x509 -req -in out-certificates/${_name}.csr -CA out-certificates/root-ca.pem -CAkey \
			out-certificates/root-ca.key -CAcreateserial -out out-certificates/${_name}.pem \
				-extfile out-certificates/${_name}.conf -extensions v3_req -days 3650)
	else
		echo "####################################"
                echo "Skip. ${_name} certificate exists"
                echo "####################################"
	fi
}

gen::init() {
	local _file
	local _indexer
	local _server
	local _dashboard
	local _name
	local _ip

	gen::check::req

	mkdir -p "out-certificates"

        if [ ! -f "out-certificates/root-ca.key" ]; then
                gen::root::ca
        fi
        if [ ! -f "out-certificates/admin-key.pem" ]; then
                gen::admin::cert
        fi

	_indexer=$(cat in.indexer.lst | sed -e '/^#/d' | sed '/^$/d')

	for _file in ${_indexer}
	do
		_name=$(echo ${_file} | grep ".*_ip=" | cut -d '_' -f1)
		_ip=$(echo ${_file} | grep ".*_ip=" | cut -d '=' -f2)

		gen::cert "${_name}" "${_ip}"
	done

        _server=$(cat in.server.lst | sed -e '/^#/d' | sed '/^$/d')

        for _file in ${_server}
        do
                _name=$(echo ${_file} | grep ".*_ip=" | cut -d '_' -f1)
                _ip=$(echo ${_file} | grep ".*_ip=" | cut -d '=' -f2)

		gen::cert "${_name}" "${_ip}"
        done

        _dashboard=$(cat in.dashboard.lst | sed -e '/^#/d' | sed '/^$/d')

        for _file in ${_dashboard}
        do
                _name=$(echo ${_file} | grep ".*_ip=" | cut -d '_' -f1)
                _ip=$(echo ${_file} | grep ".*_ip=" | cut -d '=' -f2)

		gen::cert "${_name}" "${_ip}"
        done
}

echo "####################################################################################"
echo "Do you want generate root, admin, server, indexer and dashboard certificates? (y/n):"
echo "####################################################################################"

read answer

if [ "${answer}" = "y" ]; then
	gen::init
else
	echo "Bye!"
	exit;
fi