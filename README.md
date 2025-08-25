# Hyku SWORD QA

Test a [Hyku Willow SWORD](https://github.com/notch8/willow_sword/) endpoint

## Quick Start

* Copy config.example to config.xml
  * edit the values to your Hyku instance
* If you want to change tests run, edit the "Tests.csv"
* Run `runtests.py < "Tests.csv"`
* Review output provided on the terminal

## BYO files example

### SimpleZip
```
mkdir temp/simplezip; mkdir temp/simplezip/supplement; cp files/generic.minimal.xml temp/simplezip/metadata.xml; cp files/*.pdf temp/simplezip; cp files/*.csv files/*.xlsx files/*.png files/*.docx temp/simplezip/supplement
pushd temp/simplezip/; zip -r SimpleZip.zip .; popd
mv temp/simplezip/SimpleZip.zip files/
```

### BagIt
```
pip install bagit
bagit.py --contact-name 'Hyku Demo User' temp/simplezip/
pushd temp/simplezip; zip -r BagIt.zip .; popd
mv temp/simplezip/BagIt.zip files/
sed 's/<metadata>/<metadata> /' -i temp/simplezip/data/metadata.xml
pushd temp/simplezip; zip -r BadBagIt.zip .; popd
mv temp/simplezip/BadBagIt.zip files/
```

### Embargos
```
mkdir temp/etd; cp files/etd.full.xml temp/metadata.xml; cp files/*.pdf temp/etd/; cp files/*.png temp/etd/
zip -j files/EtdEmbargo.zip temp/etd/*
sed 's|<visibility>embargo</visibility>|<visibility>embargo</visibility>|' files/etd.full.xml | sed 's|<embargo_release_date>.*||' | sed 's|<visibility_during_embargo>.*||' | sed 's|<visibility_after_embargo>.*||' > files/etd.noembargo.xml
```


## CSV Tests

Tests are defined in CSV format, using the following colunms:
* Title: a human readable name for the test
* Method: A (generally HTTP) method to use for the test e.g. GET, POST, PUT
  * FILE is a magic method which reads a local XML file
* URI: The HTTP endpoint, or local filename which will be accessed
  * Variables as `$VAR` will be interpolated
* Headers: Multiline HTTP headers to supply, e.g. `Content-Type: application/xml`
  * Variables as `$VAR` will be interpolated
* Form: Multiline form fields to be be submitted in the form of key=filename
  * Variables will be interpolated
* Payload: A filename which will be submitted as binary content to the request
* Expected: An expected HTTP status code
* Test: Multiline assertions in the form of `Expected=/xpath/expression[@attr="value"]`
  * Variables will be interpolated
  * Use a left hand wildcard to indicate any value, e.g. `*=//element/subelement`
  * `lxml`'s xpath syntax is supported
* NS: Multiline namespace aliases in the form of `alias=uri://name.space/specification`

## License

Copyright (c) University Library System, University of Pittsburgh

Released under the MIT license
