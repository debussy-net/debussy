"""
Mininet functions for creating topologies from command-line parameters.
"""

import os
import re

# NOTE: newer mininet version also has MinimalTopo, TorusTopo
from mininet.topo import (SingleSwitchTopo, LinearTopo,
                          SingleSwitchReversedTopo)
from mininet.topolib import TreeTopo
from mininet.util import buildTopo

TOPOS = { "linear": LinearTopo,
          "reversed": SingleSwitchReversedTopo,
          "single": SingleSwitchTopo,
          "tree": TreeTopo
      }

def setCustom(name, value):
    """Set custom parameters for Mininet
       name: parameter name
       value: parameter value"""
    if name in ("topos", "switches", "hosts", "controllers"):
        param = name.upper()
        globals()[param].update(value)
    elif name == "validate":
        validate = value
    else:
        globals()[name] = value

def custom(value):
    """Parse custom parameters
       value: string containing custom parameters"""
    files = []
    if os.path.isfile(value):
        files.append(value)
    else:
        files += value.split(",")

    for filename in files:
        customs = {}
        if os.path.isfile(filename):
            execfile(filename, customs, customs)
            for name, val in customs.iteritems():
                setCustom(name, val)
        else:
            print "Could not find custom file", filename

def build(opts):
    """Build Mininet topology from custom and topo parameters
       opts: Mininet topology parameters"""
    try:
        return buildTopo(TOPOS, opts)
    except Exception:
        return None
