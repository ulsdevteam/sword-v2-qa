import csv
import argparse
import sys
import requests
import string
import lxml
from lxml import etree
import io
from io import StringIO
import tempfile
import os

variables = {}

def variable_replace(inputstring):
    template_string = string.Template(inputstring)
    return template_string.substitute(variables)

def xpath_lookup(xmlstring, xpath, nsmap):
    if not xmlstring:
        return None
    stringio = StringIO(xmlstring)
    xmlfile = etree.parse(stringio)
    results = xmlfile.xpath(xpath, namespaces=nsmap)
    return_string = None
    if results:
      return_string = ''
      for result in results:
        if hasattr(result, 'itertext'):
          return_string = return_string + ''.join(result.itertext())
        else:
          return_string = return_string + result
    return return_string

def write_to_tempfile(num, output):
    fh = tempfile.NamedTemporaryFile(prefix = str(num)+'_', dir = 'temp/', delete = False)
    fh.write(output)
    fname = os.path.realpath(fh.name)
    print(f"logged to {fname}", file=sys.stderr)
    fh.close()

def test_http_request(row_number, row):
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
        print(f"Bad response for #{row_number}, {row['Title']}", file=sys.stderr)
        print(f"#{row_number} Failed. Tried {row['Method']} {uri}", file=sys.stderr)
        print(f"#{row_number} Failed. Expected {row['Expected']}", file=sys.stderr)
        print(f"#{row_number} Failed. Found {response.status_code}", file=sys.stderr)
        write_to_tempfile(row_number, response.content)
    else:
        failed_test = False
        xmlfile = response.text
        for line in row['Test'].splitlines():
            expected, xpath = line.split('=', 1)
            expected = variable_replace(expected)
            xpath = variable_replace(xpath)
            value = xpath_lookup(xmlfile, xpath, namespaces)
            if not (expected == '*' and value is not None) and not expected == value:
                if not failed_test:
                    print(f"Bad data for #{row_number}, {row['Title']}", file=sys.stderr)
                    write_to_tempfile(row_number, response.content)
                print(f"#{row_number} Failed. Tried {xpath}", file=sys.stderr)
                print(f"#{row_number} Failed. Expected {expected}", file=sys.stderr)
                print(f"#{row_number} Failed. Found {value}", file=sys.stderr)
                failed_test = True
        if not failed_test:
            print(f"#{row_number} Success. {row['Title']}")
    if row['Store']:
        store_variables(row['Store'], xmlfile, namespaces)

def string_to_dictionary(string):
    dictionary = {}
    if string:
        for line in string.splitlines():
            key, value = line.split('=', 1)
            dictionary[key] = value
    return dictionary

def store_variables(assignments, source, ns):
    for line in assignments.splitlines():
        variable, xpath = line.split('=', 1)
        xpath = variable_replace(xpath)
        value = xpath_lookup(source, xpath, ns)
        if value:
            variables[variable] = value
        else:
            variables.pop(variable, None)

def main():
    reader = csv.DictReader(sys.stdin)
    for row_id, row in enumerate(reader, start=1):
        # row id skips the header, so spreadsheet lines shift one
        row_number = row_id + 1
        if row['Method'] == 'FILE':
            namespaces = string_to_dictionary(row['NS'])
            with open(row['URI'], 'r') as fh:
                source_text = fh.read()
                store_variables(row['Store'], source_text, namespaces)
        elif row['Method'] in ['GET', 'POST', 'PUT']:
            try:
                test_http_request(row_number, row)
            except KeyError as e:
                print(f"Bad requirements for #{row_number}, {row['Title']}", file=sys.stderr)
                print(f"#{row_number} Failed. Missing {e}", file=sys.stderr)
        else:
            print(f"Method not defined for {row_number}", file=sys.stderr)

if __name__ == '__main__':
    main();
