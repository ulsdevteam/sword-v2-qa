"""
Read json file (provided in argv), and convert it into a csv that can be fed into 
runtests.py. CSV is written to stdout.
"""

import json
import csv
import sys

csv_headers = ("Title","Method","URI","Headers",
    "Form","Payload","Expected","Store","Test","NS")


def usage():
    print(f"Usage: python3 {__file__} <input.json>", file=sys.stderr)
    print("Read json file, and convert it into a csv that can be fed into" 
    "runtests.py. CSV is written to stdout.", file=sys.stderr)

def main():
    """
    JSON assumed to have a base object, with a field "steps" which is an 
    array of json objects. Each of the json objects corresponds to a row of the
    csv. If a field of a json object is not specified, it is assumed to be empty.
    Strings and ints are treated in trivial ways. JSON arrays are translated into
    multiline sequences within CSV.
    
    See ../README.md for details about CSV
    """
    if len(sys.argv) != 2:
        print("Invalid Number of arguments")
        usage()
        return
    json_file = sys.argv[1]
    with open(json_file) as f:
        input_file = json.load(f)
    output = csv.DictWriter(sys.stdout, csv_headers)
    output.writeheader()
    for step in input_file['steps']:
        for k, v in step.items():
            if type(v) == list:
                step[k] = '\n'.join(v)
        output.writerow(step)
    


if __name__ == '__main__':
    main()
