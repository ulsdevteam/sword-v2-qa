#!/bin/bash
if [ -e .env ]
then
	source .env
fi
if [ "$SWORD_ENDPOINT" = "" ]
then
	>&2 echo SWORD_ENDPOINT is undefined
	exit 1
fi
if [ "$SWORD_APIKEY" != "" ]
then
	SWORD_CURL_AUTH_KEY="--header"
	SWORD_CURL_AUTH_VAL="Api-key: $SWORD_APIKEY"
fi
SWORD_OUTPUT=`mktemp -d output/sword.XXXXX`
echo Writing tests to $SWORD_OUTPUT
echo Fetching service document
curl $SWORD_CURL_OPTS -D $SWORD_OUTPUT/service_document.headers -o $SWORD_OUTPUT/service_document.out \
	--request GET \
	--url $SWORD_ENDPOINT/service_document \
	--header 'Content-Type: application/xml' \
	$SWORD_CURL_AUTH_KEY "$SWORD_CURL_AUTH_VAL"
SWORD_HTTP_CODE=`head -1 $SWORD_OUTPUT/service_document.headers`
if [ `echo $SWORD_HTTP_CODE | cut -d' ' -f2 | cut -c 1` != "2" ]
then
	>&2 echo ... returned $SWORD_HTTP_CODE
	exit 2
fi
xmllint --noout --nowarning $SWORD_OUTPUT/service_document.out
if [ $? -ne 0 ]
then
	>&2 echo ... Service Document not valid
	exit 2
fi
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
	SWORD_COLLECTIONS=`xsltproc $SWORD_COLLECTIONS_XSL $SWORD_OUTPUT/service_document.out`
fi
if [ "$SWORD_COLLECTION" != "" ]
then
	SWORD_COLLECTIONS=$SWORD_COLLECTION
fi
echo I will process: $SWORD_COLLECTIONS
rm -fr $SWORD_OUTPUT

