#!/usr/bin/env bash

if [ "$DEBUG" = 'yes' ] && [ "$DEBUG_SHELL" != 'no' ]; then
    set -x
fi

REMOTE_XEN1_NODE=xen1
REMOTE_AMD_NODE=amd
REMOTE_ML_NODE=ml
REMOTE_CLUSTER1_NODE=cluster1
REMOTE_LOGAN_NODE=logan

# Local tunneling ports that have been allocated.
AMD_GDB_PORT=1235
AMD_SSH_PORT=8686
ML_GDB_PORT=1237
ML_SSH_PORT=8989
ML_JUPYTER_PORT=5757
XEN1_GDBGUI_PORT=8888
XEN1_SSH_PORT=8787
XEN1_GDB_PORT=1234
XEN1_GDB_MATHUNITTESTS_PORT=1236
CLUSTER1_SSH_PORT=8181
LOGAN_SSH_PORT=8282
LOGAN_GDB_PORT=1238
LOGAN_GDB_UNITTEST_PORT=1239
LOGAN_GDB_UNITTEST_LOCAL_PORT=1240
LOGAN_SNAKEVIZ_PORT=6226
LOGAN_TENSORBOARD_PORT=6116