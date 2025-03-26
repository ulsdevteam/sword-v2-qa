#!/bin/bash

# Request a SWORD URI ($1), put results into temp file ($2), via HTTP Method ($3)
function sword_request {
	echo ${3} $SWORD_ENDPOINT/$1 into $2
	curl $SWORD_CURL_OPTS -s -D $SWORD_OUTPUT/$2.headers -o $SWORD_OUTPUT/$2.out \
		--request $3 \
		--url $SWORD_ENDPOINT/$1 \
		$SWORD_CURL_AUTH_KEY "$SWORD_CURL_AUTH_VAL" \
		$SWORD_POST_HEADER_KEY1 "$SWORD_POST_HEADER_VAL1" \
		$SWORD_POST_HEADER_KEY2 "$SWORD_POST_HEADER_VAL2" \
		$SWORD_POST_HEADER_KEY2 "$SWORD_POST_HEADER_VAL2" \
		$SWORD_POST_FILE_KEY "$SWORD_POST_FILE_VAL" 
	SWORD_HTTP_CODE=`head -1 $SWORD_OUTPUT/$2.headers`
	if [ ""`echo $SWORD_HTTP_CODE | cut -d' ' -f2 | cut -c 1` != "2" ]
	then
		>&2 echo ... returned $SWORD_HTTP_CODE
		exit 2
	fi
	xmllint --noout --nowarning $SWORD_OUTPUT/$2.out
	if [ $? -ne 0 ]
	then
		>&2 echo ... $2 not valid
		exit 2
	fi
}

function sword_get {
	SWORD_POST_FILE_KEY=
	SWORD_POST_FILE_VAL=
	SWORD_POST_HEADER_KEY1='--header'
	SWORD_POST_HEADER_KEY2=
	SWORD_POST_HEADER_KEY3=
	SWORD_POST_HEADER_VAL1='Content-type: application/xml'
	SWORD_POST_HEADER_VAL2=
	SWORD_POST_HEADER_VAL3=
	sword_request $1 $2 GET
}

function sword_post {
	SWORD_POST_FILE_KEY=$3
	SWORD_POST_FILE_VAL=$4
	SWORD_POST_HEADER_KEY1=
	SWORD_POST_HEADER_KEY2=
	SWORD_POST_HEADER_KEY3=
	if [ "$5" != "" ]
	then
		SWORD_POST_HEADER_KEY1='--header'
	fi
	if [ "$6" != "" ]
	then
		SWORD_POST_HEADER_KEY2='--header'
	fi
	if [ "$7" != "" ]
	then
		SWORD_POST_HEADER_KEY3='--header'
	fi
	SWORD_POST_HEADER_VAL1=$5
	SWORD_POST_HEADER_VAL2=$6
	SWORD_POST_HEADER_VAL3=$7
	sword_request $1 $2 POST
}

# Sanity check the confug
if [ -e .env ]
then
	source .env
fi
if [ "$SWORD_ENDPOINT" = "" ]
then
	>&2 echo SWORD_ENDPOINT is undefined
	exit 1
fi
SWORD_CURL_AUTH_KEY=
SWORD_CURL_AUTH_VAL=
if [ "$SWORD_APIKEY" != "" ]
then
	SWORD_CURL_AUTH_KEY="--header"
	SWORD_CURL_AUTH_VAL="Api-key: $SWORD_APIKEY"
fi
SWORD_OUTPUT=`mktemp -d output/sword.XXXXX`
if [ "$SWORD_OUTPUT" = "" -o ! -d $SWORD_OUTPUT ]
then
	>&2 echo Failed to create temporary directory
        exit 1
fi

# Sanity check the Service
echo Writing tests to $SWORD_OUTPUT
SWORD_OUTFILE=service_document
sword_get service_document $SWORD_OUTFILE
if [ "$SWORD_COLLECTIONS_XSL" = "" -a "$SWORD_COLLECTION" = "" ]
then
	SWORD_COLLECTIONS_XSL="get-all-collections.xsl"
fi
if [ "$SWORD_COLLECTIONS_XSL" != "" ]
then
	if [ ! -f "$SWORD_COLLECTIONS_XSL" ]
	then
		>&2 echo ... Transform not found
		exit 3
	fi
	SWORD_COLLECTIONS=`xsltproc $SWORD_COLLECTIONS_XSL $SWORD_OUTPUT/$SWORD_OUTFILE.out`
fi
if [ "$SWORD_COLLECTION" != "" ]
then
	SWORD_COLLECTIONS=$SWORD_COLLECTION
fi
for SWORD_CURRENT in $SWORD_COLLECTIONS
do
	SWORD_OUTFILE=collection
	sword_get collections/$SWORD_CURRENT $SWORD_OUTFILE
done

# Try deposits
for SWORD_CURRENT in $SWORD_COLLECTIONS
do
	for m in input/*/metadata.xml
	do
		# Try metadata deposit
		SWORD_OUTFILE=metadata-only
		sword_post collections/$SWORD_CURRENT/works/ $SWORD_OUTFILE \
			'--data-binary' "@${m}" \
			'Content-type: application/xml' \
			'Content-Disposition: attachment; filename=metadata.xml' \
			'Packaging: application/atom+xml;type=entry'
		# What URI was created for this work?
		SWORD_URI=`xsltproc get-src-link.xsl $SWORD_OUTPUT/$SWORD_OUTFILE.out | sed "s|$SWORD_ENDPOINT/||"`
		if [ "$SWORD_URI" = "" ]
		then
			>&2 echo ... Resulting link src not found
			exit 4
		fi
		# Try get work
		SWORD_OUTFILE=metadata-returned
		sword_get $SWORD_URI $SWORD_OUTFILE
		# What URI was created for the files?
		SWORD_URI=`xsltproc get-edit-link.xsl $SWORD_OUTPUT/$SWORD_OUTFILE.out | sed "s|$SWORD_ENDPOINT/||"`
		if [ "$SWORD_URI" = "" ]
		then
			>&2 echo ... Resulting link edit not found
			exit 4
		fi
		# Try file deposit
		for f in `dirname $m`/files/*
		do
			HTTPFILENAME=$(basename "$f" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
			SWORD_OUTFILE=file-deposit
			sword_post $SWORD_URI $SWORD_OUTFILE \
			'--data-binary' "@${f}" \
			'Content-type: '`file --brief --mime "$f" | cut -d';' -f1` \
			'Packaging: http://purl.org/net/sword/package/Binary' \
			"Content-Disposition: attachment; filename=\"${HTTPFILENAME}\""
		done
		# Try updates
	done
done

# Success, cleanup
rm -fr $SWORD_OUTPUT

