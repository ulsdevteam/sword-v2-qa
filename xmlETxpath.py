import argparse
import sys
import xml.etree.ElementTree

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
    xmlfile = xml.etree.ElementTree.fromstring(sys.stdin.read())
    searchbase = xml.etree.ElementTree.fromstring('<root />')
    searchbase.append(xmlfile)
    results = searchbase.findall('.'+args.xpath, nsmap)
    if results:
      for result in results:
        print(result.text)
    else:
      exit(1)

if __name__ == "__main__":
    main()
