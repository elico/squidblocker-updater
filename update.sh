#!/usr/bin/env bash

USER="admin"
PASS="hello"
HOST="192.168.10.65"
PORT="8080"
FILE="./urls"

LISTS_PATH="/var/squidblocker/rawlists/"
LISTS_PATH="./"
BLACKLISTS="porn sex/lingerie"
WHITELISTS=""
UPDATE=1
LISTSURL="http://www.shallalist.de/Downloads"
LISTSURL="http://ngtech.co.il/squidblocker/lists"


function update {
	if [ -f "$5" ]; then
		echo "Updateing from file $5"
		curl -i -X POST -H "Content-Type: multipart/form-data" \
		-F "prefix=$6" \
		-F "val=$7" \
		-F "listfile=@$5" \
		"http://$1:$2@$3:$4/db/set_batch/"
		echo "result of the update $?"
	else
		echo "The file $5 doesn't exists!"
	fi
}

function blacklistdom {
	update $1 $2 $3 $4 $5 "dom:" "1"
}

function blacklisturl {
	update $1 $2 $3 $4 $5 "url:http://" "1"
	update $1 $2 $3 $4 $5 "url:http://www." "1"
	update $1 $2 $3 $4 $5 "url:https://" "1"
	update $1 $2 $3 $4 $5 "url:https://www." "1"
}

function whitelistdom {
	update $1 $2 $3 $4 $5 "dom:" "0"
}

function whitelisturl {
	update $1 $2 $3 $4 $5 "url:http://" "0"
	update $1 $2 $3 $4 $5 "url:http://www." "0"
	update $1 $2 $3 $4 $5 "url:https://" "0"
	update $1 $2 $3 $4 $5 "url:https://www." "0"
}

#Check the directory
if [ ! -e "$LISTS_PATH" ]; then
	echo $LISTS_PATH
	mkdir -p $LISTS_PATH
fi

cd $LISTS_PATH
if [ "$?" -eq 0 ];then
	echo "OK"
else
	echo "ERR"
	return
fi

#Do we download?  Check the md5sum
NEW=0
if [ -e "$LISTS_PATH/shallalist.tar.gz" ]; then
	/usr/bin/curl -o $LISTS_PATH/shallalist.tar.gz.md5 $LISTSURL/shallalist.tar.gz.md5

	#Check the status
	/usr/bin/md5sum --status -c *.md5

	#Do we download a new version?
	if [ $? -ne 0 ]; then
		/usr/bin/unlink shallalist.tar.gz
		/usr/bin/wget $LISTSURL/shallalist.tar.gz -O $LISTS_PATH/shallalist.tar.gz
		NEW=1
	fi
else
	/usr/bin/curl -o $LISTS_PATH/shallalist.tar.gz.md5 $LISTSURL/shallalist.tar.gz.md5
	/usr/bin/wget $LISTSURL/shallalist.tar.gz -O  $LISTS_PATH/shallalist.tar.gz
	NEW=1
fi

#Did we download a new tar-gzip?
if [ $NEW -eq 1 ]; then
	#Check the status
	/usr/bin/md5sum --status -c *.md5

	#MD5 match?  The commit.
	if [ $? -eq 0 ]; then
		if [ -f "/usr/bin/pv" ];then
			/usr/bin/pv shallalist.tar.gz | /bin/tar xzf - -C ./
		else
			/bin/tar -zxvf shallalist.tar.gz
		fi
	fi
fi

# Update anyway because it's very very fast..
if [ $UPDATE -eq 1 ]; then
	for list in $BLACKLISTS
	do
		echo "Updating the category: $list"
		if [ -d "$LISTS_PATH/BL/$list" ]; then
			blacklisturl $USER $PASS $HOST $PORT "$LISTS_PATH/BL/$list/urls"
			blacklistdom $USER $PASS $HOST $PORT "$LISTS_PATH/BL/$list/domains"
		fi
	done
	for list in $WHITELISTS
	do
		echo "Updating the category: $list"
		if [ -d "$LISTS_PATH/BL/$list" ]; then
			whitelisturl $USER $PASS $HOST $PORT "$LISTS_PATH/BL/$list/urls"
			whitelistdom $USER $PASS $HOST $PORT "$LISTS_PATH/BL/$list/domains"
		fi
	done
fi
