import csv
import argparse
import sys
import requests
import string
import lxml
from lxml import etree
import io
from io import BytesIO
import tempfile
import os

# A global variable of key-value replacements
# E.g. "$BASE_URL/sword/v2/work/$WORKID" can be interpolated via:
# { 'BASE_URL': 'https://my.server.tld', 'WORKID': 'abc-123' }
variables = {}

def variable_replace(inputstring):
    """
    Given a templated string, replace any variables found in the global variables dictionary
    inputstring: str A string containing variable names to be interpolated
    return: str The interpolated string
    """
    template_string = string.Template(inputstring)
    return template_string.substitute(variables)

def xpath_lookup(xmlstring, xpath, nsmap):
    """
    Lookup values in an XML document by XPath
    xmlstring: bytes A string of an XML document
    xpath: str The xpath expression to execute on the XML
    nsmap: dict The XML namespaces used by the xpath, in { alias: nsURI } form
    return: str A concatenation of all results as text output, or None
    """
    if not xmlstring:
        return None
    bytesio = BytesIO(xmlstring)
    xmlfile = etree.parse(bytesio)
    results = xmlfile.xpath(xpath, namespaces=nsmap)
    return_string = None
    if results is not None:
      return_string = ''
      try:
        iterable = iter(results)
      except TypeError:
        iterable = False
      if iterable:
        for result in results:
          if hasattr(result, 'itertext'):
            return_string = return_string + ''.join(result.itertext())
          else:
            return_string = return_string + result
      else:
        return_string = str(results)
    return return_string

def write_to_tempfile(num, output):
    """
    Write the output to a temporary file and announce the path to STDERR
    num: int The row number being processed
    output: str The raw response to record
    return: None
    """
    fh = tempfile.NamedTemporaryFile(prefix = str(num)+'_', dir = 'temp/', delete = False)
    fh.write(output)
    fname = os.path.realpath(fh.name)
    print(f"  logged to {fname}", file=sys.stderr)
    fh.close()

def test_http_request(row_number, row):
    """
    Process a CSV row as an HTTP test, write out success or failure to STDERR
    row_number: int The row in the CSV being processed
    row: dict The data from the CSV, in { header: row_value } form; see README for columns
    return: None
    """
    uri = variable_replace(row['URI'])

    all_headers = {}
    response = None
    for line in row['Headers'].splitlines():
        header, value = line.split(': ', 1)
        all_headers[header] = variable_replace(value)

    if row['Method'] == 'GET':
        response = requests.get(uri, headers = all_headers)
    elif row['Method'] == 'POST' or row['Method'] == 'PUT':
        filestreams = {}
        if row['Form']:
            for line in row['Form'].splitlines():
                key, filename = line.split('=', 1)
                filestreams[key] = open(filename, 'rb')
        datastream = None
        if row['Payload']:
            with open(row['Payload'], 'rb') as f:
                datastream = f.read()
        response = requests.request(row['Method'], uri, headers = all_headers, files = filestreams, data = datastream)
        for fh in filestreams:
            filestreams[fh].close()
    else:
        print(f"Method {row['Method']} not implemented for {row_number}", file=sys.stderr)

    xmlfile = None
    namespaces = string_to_dictionary(row['NS'])
    if response.status_code != int(row['Expected']):
        print(f"#{row_number} Failed. {row['Title']}", file=sys.stderr)
        write_to_tempfile(row_number, response.content)
        print(f"  #{row_number} Bed Code. Tried {row['Method']} {uri}", file=sys.stderr)
        print(f"  #{row_number} Bad Code. Expected {row['Expected']}", file=sys.stderr)
        print(f"  #{row_number} Bad Code. Found {response.status_code}", file=sys.stderr)
    else:
        xmlfile = response.content
        handle_tests(row_number, row, xmlfile)
    if row['Store']:
        output_files = store_variables(row['Store'], xmlfile, namespaces)
        # xml file is response.content so is written to files

def string_to_dictionary(string):
    """
    Given a multiline string of key value pairs, create a dictionary
    string: str A multiline string with lines in the form of "key=value"
    return: dict in the form of { key: value }
    """
    dictionary = {}
    if string:
        for line in string.splitlines():
            key, value = line.split('=', 1)
            dictionary[key] = value
    return dictionary

def store_variables(assignments, source, ns):
    """
    Given variable names and xpaths, with an XML document and namespaces, find the value of the xpath in the XML and assign it to the variable name. Paths specified are writtent. Modifies the global variables. 
    assignments: str A multiline sequence of either file paths as "/path/to/file=*" or mappings of varible names to xpaths, as "FOO_BAR=/fizz:foo/buzz:bar[@att='val']"
    source: bytes The XML against which to evaluate the xpaths
    ns: dict Key-value pairs of namespace aliases to URIs as used in the xpath
    return: None
    """
    output_paths = []
    for line in assignments.splitlines():
        variable, xpath = line.split('=', 1)
        if xpath == '*':
            output_paths.append(variable)
            continue
        xpath = variable_replace(xpath)
        value = xpath_lookup(source, xpath, ns)
        if value:
            variables[variable] = value
        else:
            variables.pop(variable, None)
    
    for path in output_paths:
        with open(path, 'wb') as fw:
            fw.write(source)

    failed_store = False
    for line in assignments.splitlines():
        key, value = line.split('=', 1)
        if value == '*':
            continue
        if not variables[key]:
           if not failed_store:
                print(f"#{row_number} Failed. {row['Title']}", file=sys.stderr)
                write_to_tempfile(row_number, response.content)
           failed_store = True
           print(f"  #{row_number} Missing Value. Tried {value}", file=sys.stderr)

def handle_tests(row_number, row, xmlfile):
    namespaces = string_to_dictionary(row['NS'])
    failed_test = False
    for line in row['Test'].splitlines():
        expected, xpath = line.split('=', 1)
        expected = variable_replace(expected)
        xpath = variable_replace(xpath)
        value = xpath_lookup(xmlfile, xpath, namespaces)
        if not (expected == '*' and value is not None) and not expected == value:
            if not failed_test:
                print(f"#{row_number} Failed. {row['Title']}", file=sys.stderr)
                write_to_tempfile(row_number, xmlfile)
            print(f"  #{row_number} Bad Data. Tried {xpath}", file=sys.stderr)
            print(f"  #{row_number} Bad Data. Expected {expected}", file=sys.stderr)
            print(f"  #{row_number} Bad Data. Found {value}", file=sys.stderr)
            failed_test = True
    if not failed_test:
        print(f"#{row_number} Success. {row['Title']}")

def apply_xslt(row_number, row):
    """
    Process a CSV row as an XSLT method.
    Payload is transformed by URI. Transformed files are stored in paths (described 
        as /path/to/file=*) within Store. Rest of Store assignments are recorded.
    row_number: CSV row number
    row: Dictionary object that contains csv row data
    """
    xml_file, xslt_file = row['Payload'], row['URI']
    
       
    namespaces = string_to_dictionary(row['NS'])
    #output_files = store_variables(row['Store'], xml_source, namespaces)
    #store_variables(assignments, xslt_source, namespaces)
    
    xml = etree.parse(xml_file)
    xsl = etree.parse(xslt_file)
    transform = etree.XSLT(xsl)
    output = transform(xml)
    xml_output = etree.tostring(output, encoding='utf-8')
    store_variables(row['Store'], xml_output, namespaces)
    handle_tests(row_number, row, xml_output)


    

def main():
    """
    Read STDIN as a CSV, process each row as an HTTP test.  See README for columns.
    """
    reader = csv.DictReader(sys.stdin)
    for row_id, row in enumerate(reader, start=1):
        # row id skips the header, so spreadsheet lines shift one
        row_number = row_id + 1
        if row['Method'] == 'FILE':
            namespaces = string_to_dictionary(row['NS'])
            print(f"#{row_number} Processing. {row['Title']}", file=sys.stderr)
            with open(row['URI'], 'rb') as fh:
                source_text = fh.read()
                store_variables(row['Store'], source_text, namespaces)
        elif row['Method'] in ['GET', 'POST', 'PUT']:
            try:
                test_http_request(row_number, row)
            except KeyError as e:
                print(f"#{row_number} Failed. {row['Title']}", file=sys.stderr)
                print(f"  #{row_number} Variable Requirement. Missing {e}", file=sys.stderr)
        elif row['Method'] == 'XSLT':
            try:
                apply_xslt(row_number, row)
            except KeyError as e:
                print(f"#{row_number} Failed. {row['Title']}", file=sys.stderr)
                print(f"  #{row_number} Variable Requirement. Missing {e}", file=sys.stderr)
        else:
            print(f"Method not defined for {row_number}", file=sys.stderr)

if __name__ == '__main__':
    main();
