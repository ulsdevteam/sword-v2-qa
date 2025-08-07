# Willow SWORD QA

Test a [legacy Hyku Willow SWORD](https://github.com/notch8/willow_sword/releases/tag/v0.3.0) endpoint

## Quick Start

* Copy env.tempalte to .env
  * edit the `SWORD_ENDPOINT` and `SWORD_APIKEY` values to your Hyku instance
  * To deposit the test files into every collection, leave `SWORD_COLLECTION` blank
  * To deposit the test files to a single colleciton, enter a value for `SWORD_COLLECITON`
  * To select specific collections from the service document, provide a `SWORD_COLLECTIONS_XSL`
    * For examples, see: `get-admin-sets.xsl` or `get-user-collecitons.xsl`
* If you want to change the deposit files, edit the metadata or files in `input/`
  * For example, any instances of `member_of_collection_ids` values will need to be your own
* Run `test.sh`
* Review output provided on the terminal

## License

Copyright (c) University Library System, University of Pittsburgh

Released under the MIT license
