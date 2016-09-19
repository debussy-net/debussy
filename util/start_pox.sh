#!/bin/bash

CWD="$(cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd)"
eval $(grep "^PoxDir=" $CWD/debussy.cfg)
export PYTHONPATH=:$CWD

${PoxDir}/pox.py log.level --DEBUG openflow.of_01 --port=6633 debussy.controller.poxmgr

