# Hyku SWORD QA Embargos

## Quick Start

* Requires:
  * curl
  * xsltproc
  * xmllint
  * writable space in `../temp/`
* Create a .env file setting bash environment variables of `API_KEY` and `ADMIN_SET` and `SWORD_TENANT`
* Run `embargo.sh`

## What it does

This script will create two new works in the specified Admin Set: one embargoed work, and one open work.  Each work has mulitple filesets.  It will check the visiblity and embargo values returned in the ATOM, for the work and for the filesets.

It will then modify the works, opening the embargoed work and adding an embargo to the open work.  It will again check the visiblity and embargo values returned in the ATOM, for the work and for the filesets.  Finally, it will modify the last fileset, adding or removing the embargo.

Some progess messages and any unexpected results will be output to STDOUT.

Files downloaded and submitted will be recorded in `../temp/`.

## License

Copyright (c) University Library System, University of Pittsburgh

Released under the MIT license
