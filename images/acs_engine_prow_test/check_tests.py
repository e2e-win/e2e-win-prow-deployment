#!/usr/bin/python2

import sys

from junitparser import Failure
from junitparser import JUnitXml

xml_path = sys.argv[1]

xml = JUnitXml.fromfile(xml_path)

for case in xml:
    if case.name != "Test":
        if type(case.result) == Failure:
            sys.exit(1)
