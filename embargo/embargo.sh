#!/bin/bash
# This should set $ADMIN_SET and $API_KEY and $SWORD_TENANT
source .env

echo Post a SimpleZip work with embargo
curl -s --request POST --url https://$SWORD_TENANT/sword/v2/collections/$ADMIN_SET/works \
    --header 'Api-key: '$API_KEY \
    -F payload=@../files/EtdEmbargo.zip \
    -D ../temp/post.headers.out \
    -o ../temp/post.body.out

WORKID=`xmllint --xpath '//*[local-name() = "id" and namespace-uri() = "http://www.w3.org/2005/Atom"]/text()' ../temp/post.body.out`
WORKEDIT=`xmllint --xpath '//*[local-name() = "link" and namespace-uri() = "http://www.w3.org/2005/Atom" and @rel="edit"]/@href' ../temp/post.body.out | cut -d'"' -f2`
echo "Deposited $WORKID"

# Find the filesets created under this work
FILESETS=`xsltproc get-filesets.xsl ../temp/post.body.out`
# Extract the ATOM response to Hyku 'metadata' format
xsltproc h4cmeta.xsl ../temp/post.body.out > ../temp/post.metadata.xml
mv ../temp/post.body.out ../temp/$WORKID.body.out
mv ../temp/post.headers.out ../temp/$WORKID.headers.out
mv ../temp/post.metadata.xml ../temp/$WORKID.metadata.xml

echo Check the visibility value
RESULT=`xmllint --xpath '//metadata/visibility/text()' ../temp/$WORKID.metadata.xml`
if [[ 'embargo' != "$RESULT" ]]; then echo "work visibility should be embargo"; fi
echo Check that the other embargo tags are present
for field in 'visibility_after_embargo' 'visibility_during_embargo' 'embargo_release_date'
do
  RESULT=`xmllint --xpath '//metadata/'$field ../temp/$WORKID.metadata.xml 2> /dev/null`
  if [[ -z "$RESULT" ]]; then echo "work missing $field"; fi
done

echo Filesets should inherit the same embargos
for f in $FILESETS
do
  # Fileset UUID for convenience
  fid=`echo $f | rev | cut -d'/' -f1 | rev`
  # Get the fileset
  curl -s --request GET --url $f --header 'Api-key: '$API_KEY -D ../temp/$fid.headers.out -o ../temp/$fid.body.out
  # Extract the ATOM response into Hyku 'metadata' format
  xsltproc h4cmeta.xsl ../temp/$fid.body.out > ../temp/$fid.metadata.xml
  # Check the visibility value
  RESULT=`xmllint --xpath '//metadata/visibility/text()' ../temp/$fid.metadata.xml`
  if [[ 'embargo' != "$RESULT" ]]; then echo "fileset $fid visibility should be embargo"; fi
  # Check the other embargo tags are present
  for field in 'visibility_after_embargo' 'visibility_during_embargo' 'embargo_release_date'
  do
    RESULT=`xmllint --xpath '//metadata/'$field ../temp/$fid.metadata.xml 2> /dev/null`
    if [[ -z "$RESULT" ]]; then echo "fileset $fid missing $field"; fi
  done
done

echo Remove the embargo tags and change the visibility to open
xsltproc openup.xsl ../temp/$WORKID.metadata.xml > ../temp/$WORKID.put.metadata.xml

curl -s --request PUT --url $WORKEDIT \
    --header 'Api-key: '$API_KEY \
    -F metadata=@../temp/$WORKID.put.metadata.xml \
    -D ../temp/$WORKID.put.headers.out \
    -o ../temp/$WORKID.put.body.out

# Extract the ATOM response to Hyku 'metadata' format
xsltproc h4cmeta.xsl ../temp/$WORKID.put.body.out > ../temp/$WORKID.put.validate.metadata.xml
echo Check the visibility value
RESULT=`xmllint --xpath '//metadata/visibility/text()' ../temp/$WORKID.put.validate.metadata.xml`
if [[ 'open' != "$RESULT" ]]; then echo "work visibility should be open"; fi
echo Check that the other embargo tags are present
for field in 'visibility_after_embargo' 'visibility_during_embargo' 'embargo_release_date'
do
  RESULT=`xmllint --xpath '//metadata/'$field ../temp/$WORKID.put.validate.metadata.xml 2> /dev/null`
  if [[ ! -z "$RESULT" ]]; then echo "work $field found when unexpected"; fi
done

echo Filesets should not have changed
for f in $FILESETS
do
  # Fileset UUID for convenience
  fid=`echo $f | rev | cut -d'/' -f1 | rev`
  # Get the fileset
  curl -s --request GET --url $f --header 'Api-key: '$API_KEY -D ../temp/$fid.headers.out -o ../temp/$fid.body.out
  # Extract the ATOM response into Hyku 'metadata' format
  xsltproc h4cmeta.xsl ../temp/$fid.body.out > ../temp/$fid.metadata.xml
  # Check the visibility value
  RESULT=`xmllint --xpath '//metadata/visibility/text()' ../temp/$fid.metadata.xml`
  if [[ 'embargo' != "$RESULT" ]]; then echo "fileset $fid visibility should be embargo"; fi
  # Check the other embargo tags are present
  for field in 'visibility_after_embargo' 'visibility_during_embargo' 'embargo_release_date'
  do
    RESULT=`xmllint --xpath '//metadata/'$field ../temp/$fid.metadata.xml 2> /dev/null`
    if [[ -z "$RESULT" ]]; then echo "fileset $fid missing $field"; fi
  done
done

echo Change the last fileset to open
xsltproc openup.xsl ../temp/$fid.metadata.xml > ../temp/$fid.put.metadata.xml

curl -s --request PUT --url $f \
    --header 'Api-key: '$API_KEY \
    -F metadata=@../temp/$fid.put.metadata.xml \
    -D ../temp/$fid.put.headers.out \
    -o ../temp/$fid.put.body.out

# Extract the ATOM response to Hyku 'metadata' format
xsltproc h4cmeta.xsl ../temp/$fid.put.body.out > ../temp/$fid.put.validate.metadata.xml
echo Check the visibility value
RESULT=`xmllint --xpath '//metadata/visibility/text()' ../temp/$fid.put.validate.metadata.xml`
if [[ 'open' != "$RESULT" ]]; then echo "fileset $fid visibility should be open"; fi
echo Check that the other embargo tags are absent
for field in 'visibility_after_embargo' 'visibility_during_embargo' 'embargo_release_date' 'visibilty_during_lease' 'visibility_after_lease' 'lease_expiration_date'
do
  RESULT=`xmllint --xpath '//metadata/'$field ../temp/$fid.put.validate.metadata.xml 2> /dev/null`
  if [[ ! -z "$RESULT" ]]; then echo "fileset $fid $field found when unexpected"; fi
done

echo Post a SimpleZip work with no embargo
curl -s --request POST --url https://$SWORD_TENANT/sword/v2/collections/$ADMIN_SET/works \
    --header 'Api-key: '$API_KEY \
    -F payload=@../files/SimpleZip.zip \
    -D ../temp/post.headers.out \
    -o ../temp/post.body.out

WORKID=`xmllint --xpath '//*[local-name() = "id" and namespace-uri() = "http://www.w3.org/2005/Atom"]/text()' ../temp/post.body.out`
WORKEDIT=`xmllint --xpath '//*[local-name() = "link" and namespace-uri() = "http://www.w3.org/2005/Atom" and @rel="edit"]/@href' ../temp/post.body.out | cut -d'"' -f2`
echo "Deposited $WORKID"

# Find the filesets created under this work
FILESETS=`xsltproc get-filesets.xsl ../temp/post.body.out`
# Extract the ATOM response to Hyku 'metadata' format
xsltproc h4cmeta.xsl ../temp/post.body.out > ../temp/post.metadata.xml
mv ../temp/post.body.out ../temp/$WORKID.body.out
mv ../temp/post.headers.out ../temp/$WORKID.headers.out
mv ../temp/post.metadata.xml ../temp/$WORKID.metadata.xml

echo Check the visibility value
RESULT=`xmllint --xpath '//metadata/visibility/text()' ../temp/$WORKID.metadata.xml`
if [[ 'open' != "$RESULT" ]]; then echo "work visibility should be open"; fi
echo Check that the other embargo tags are not present
for field in 'visibility_after_embargo' 'visibility_during_embargo' 'embargo_release_date' 'visibilty_during_lease' 'visibility_after_lease' 'lease_expiration_date'
do
  RESULT=`xmllint --xpath '//metadata/'$field ../temp/$WORKID.metadata.xml 2> /dev/null`
  if [[ ! -z "$RESULT" ]]; then echo "work $field found when not expected"; fi
done

echo Filesets should inherit the same visibility
for f in $FILESETS
do
  # Fileset UUID for convenience
  fid=`echo $f | rev | cut -d'/' -f1 | rev`
  # Get the fileset
  curl -s --request GET --url $f --header 'Api-key: '$API_KEY -D ../temp/$fid.headers.out -o ../temp/$fid.body.out
  # Extract the ATOM response into Hyku 'metadata' format
  xsltproc h4cmeta.xsl ../temp/$fid.body.out > ../temp/$fid.metadata.xml
  # Check the visibility value
  RESULT=`xmllint --xpath '//metadata/visibility/text()' ../temp/$fid.metadata.xml`
  if [[ 'open' != "$RESULT" ]]; then echo "fileset $fid visibility should be open"; fi
  # Check the other embargo tags are present
  for field in 'visibility_after_embargo' 'visibility_during_embargo' 'embargo_release_date' 'visibilty_during_lease' 'visibility_after_lease' 'lease_expiration_date'
  do
    RESULT=`xmllint --xpath '//metadata/'$field ../temp/$fid.metadata.xml 2> /dev/null`
    if [[ ! -z "$RESULT" ]]; then echo "fileset $fid $field found when unexpected"; fi
  done
done

echo Add an embargo to the work
xsltproc embargo.xsl ../temp/$WORKID.metadata.xml > ../temp/$WORKID.put.metadata.xml

curl -s --request PUT --url $WORKEDIT \
    --header 'Api-key: '$API_KEY \
    -F metadata=@../temp/$WORKID.put.metadata.xml \
    -D ../temp/$WORKID.put.headers.out \
    -o ../temp/$WORKID.put.body.out

# Extract the ATOM response to Hyku 'metadata' format
xsltproc h4cmeta.xsl ../temp/$WORKID.put.body.out > ../temp/$WORKID.put.validate.metadata.xml
echo Check the visibility value
RESULT=`xmllint --xpath '//metadata/visibility/text()' ../temp/$WORKID.put.validate.metadata.xml`
if [[ 'embargo' != "$RESULT" ]]; then echo "work visibility should be embargo"; fi
echo Check that the other embargo tags are present
for field in 'visibility_after_embargo' 'visibility_during_embargo' 'embargo_release_date'
do
  RESULT=`xmllint --xpath '//metadata/'$field ../temp/$WORKID.put.validate.metadata.xml 2> /dev/null`
  if [[ -z "$RESULT" ]]; then echo "work $field missing"; fi
done

echo Filesets should not have changed
for f in $FILESETS
do
  # Fileset UUID for convenience
  fid=`echo $f | rev | cut -d'/' -f1 | rev`
  # Get the fileset
  curl -s --request GET --url $f --header 'Api-key: '$API_KEY -D ../temp/$fid.headers.out -o ../temp/$fid.body.out
  # Extract the ATOM response into Hyku 'metadata' format
  xsltproc h4cmeta.xsl ../temp/$fid.body.out > ../temp/$fid.metadata.xml
  # Check the visibility value
  RESULT=`xmllint --xpath '//metadata/visibility/text()' ../temp/$fid.metadata.xml`
  if [[ 'open' != "$RESULT" ]]; then echo "fileset $fid visibility should be open"; fi
  # Check that no embargo tags are present
  for field in 'visibility_after_embargo' 'visibility_during_embargo' 'embargo_release_date' 'visibilty_during_lease' 'visibility_after_lease' 'lease_expiration_date'
  do
    RESULT=`xmllint --xpath '//metadata/'$field ../temp/$fid.metadata.xml 2> /dev/null`
    if [[ ! -z "$RESULT" ]]; then echo "fileset $fid $field found when unexpected"; fi
  done
done

echo Change the last fileset to embargo
xsltproc embargo.xsl ../temp/$fid.metadata.xml > ../temp/$fid.put.metadata.xml

curl -s --request PUT --url $f \
    --header 'Api-key: '$API_KEY \
    -F metadata=@../temp/$fid.put.metadata.xml \
    -D ../temp/$fid.put.headers.out \
    -o ../temp/$fid.put.body.out

# Extract the ATOM response to Hyku 'metadata' format
xsltproc h4cmeta.xsl ../temp/$fid.put.body.out > ../temp/$fid.put.validate.metadata.xml
echo Check the visibility value
RESULT=`xmllint --xpath '//metadata/visibility/text()' ../temp/$fid.put.validate.metadata.xml`
if [[ 'embargo' != "$RESULT" ]]; then echo "fileset $fid visibility should be embargo"; fi
echo Check that the other embargo tags are present
for field in 'visibility_after_embargo' 'visibility_during_embargo' 'embargo_release_date'
do
  RESULT=`xmllint --xpath '//metadata/'$field ../temp/$fid.put.validate.metadata.xml 2> /dev/null`
  if [[ -z "$RESULT" ]]; then echo "fileset $fid $field missing"; fi
done


