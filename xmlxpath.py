import argparse
import sys
import io
from io import StringIO
import lxml
from lxml import etree

def main():
    parser = argparse.ArgumentParser(
        prog='xmlxpath',
        description='Run an xpath expression on an XML file',
        epilog='Example: xmlxpath --ns="foo=http://example.com/foo" --ns="bar=http://another.com/bar" --xpath="//foo:node/bar:node[@attrib=\'value\']" < infile > outfile')
    parser.add_argument('--xpath', required=True, type=str, help='The xpath expression, supporting the xml.etree.ElementTree subset')
    parser.add_argument('--ns', required=False, action='append', type=str, help='(optional) Namespace declaration(s), as "alias=URI"')
    args = parser.parse_args()

    nsmap = {}
    if args.ns:
        for ns in args.ns:
            alias, uri = ns.split('=', 1)
            nsmap[alias] = uri
    in_string = StringIO(sys.stdin.read())
    xmlfile = etree.parse(in_string)
    results = xmlfile.xpath(args.xpath, namespaces=nsmap)
    if results:
      for result in results:
        if hasattr(result, 'itertext'):
          print(''.join(result.itertext()))
        else:
          print(result)
    else:
      exit(1)

if __name__ == "__main__":
    main()
