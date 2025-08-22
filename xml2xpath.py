import argparse
import sys
import libxml2

def main():
    parser = argparse.ArgumentParser(
        prog='xmlxpath',
        description='Run an xpath expression on an XML file',
        epilog='Example: xmlxpath --ns="foo=http://example.com/foo" --ns="bar=http://another.com/bar" --xpath="//foo:node/bar:node[@attrib=\'value\']" < infile > outfile')
    parser.add_argument('--xpath', required=True, type=str, help='The xpath expression, supporting the xml.etree.ElementTree subset')
    parser.add_argument('--ns', required=False, action='append', type=str, help='(optional) Namespace declaration(s), as "alias=URI"')
    args = parser.parse_args()

    xmlfile = libxml2.parseDoc(sys.stdin.read())
    context = xmlfile.xpathNewContext()
    if args.ns:
        for ns in args.ns:
            alias, uri = ns.split('=', 1)
            context.xpathRegisterNs(alias, uri)
    results = context.xpathEval(args.xpath)
    if results:
      for result in results:
        print(result.getContent())

    context.xpathFreeContext()
    xmlfile.freeDoc()

    if not results:
      exit(1)

if __name__ == "__main__":
    main()
