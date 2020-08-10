#!/usr/bin/env bash

if [ "$DEBUG" = 'yes' ] && [ "$DEBUG_SHELL" != 'no' ]; then
    set -x
fi

export REMOTE_XEN1_NODE=xen1
export REMOTE_AMD_NODE=amd
export REMOTE_ML_NODE=ml
export REMOTE_CLUSTER1_NODE=cluster1
export REMOTE_LOGAN_NODE=logan
export REMOTE_ECO_NODE=eco11
export REMOTE_ECO13_NODE=eco13
export REMOTE_ECO14_NODE=eco14
export REMOTE_ECO16_NODE=eco16
export REMOTE_ECO17_NODE=eco17
export REMOTE_MEL15_NODE=mel15
export REMOTE_MEL17_NODE=mel17
export REMOTE_UBUNTU_NODE=ubuntu
export REMOTE_GRANT_NODE=grant
export REMOTE_MULTIGPU_NODE=multi-gpu
export REMOTE_SINGLEGPU_NODE=single-gpu

# Local tunneling ports that have been allocated.
export AMD_GDB_PORT=1235
export AMD_SSH_PORT=8686
export XEN1_GDBGUI_PORT=8888
export XEN1_SSH_PORT=8787
export XEN1_GDB_PORT=1234
export XEN1_GDB_MATHUNITTESTS_PORT=1236
export CLUSTER1_SSH_PORT=8181
export ECO_SSH_PORT=8111
export ECO14_SSH_PORT=8141
export ECO14_POSTGRES_PORT=8142

export ECO16_SSH_PORT=8161
export ECO16_TENSORBOARD_PORT=8162
export ECO16_JUPYTER_PORT=8163

export ECO14_DASH_PORT=8143
export ECO17_SSH_PORT=8171
export ECO17_POSTGRES_PORT=8172
export ECO17_DASHBOARD_PORT=8173
export MEL15_SSH_PORT=9151
export MEL15_POSTGRES_PORT=9152

export ECO13_SSH_PORT=8131
export ECO13_POSTGRES_PORT=8132
export ECO13_TENSORBOARD_PORT=8134
export ECO13_JUPYTER_PORT=8135

export MEL17_SSH_PORT=8118
export MEL17_POSTGRES_PORT=8119
export UBUNTU_SSH_PORT=8112
export LOGAN_SSH_PORT=8282
export LOGAN_POSTGRES_PORT=8127
export LOGAN_DASH_PORT=8129
export LOGAN_GDB_PORT=8283
export LOGAN_GDB_UNITTEST_PORT=1239
export LOGAN_GDB_UNITTEST_LOCAL_PORT=1240
export LOGAN_SNAKEVIZ_PORT=6226
export LOGAN_TENSORBOARD_PORT=6116
export LOGAN_JUPYTER_PORT=5757
export GRANT_SSH_PORT=8123
export GRANT_JUPYTER_PORT=8124
export MULTIGPU_JENKINS_PORT=8782
export MULTIGPU_GDB_PORT=1237
export MULTIGPU_SSH_PORT=8989
export MULTIGPU_POSTGRES_PORT=8128
export MULTIGPU_TENSORBOARD_PORT=8126
export SINGLEGPU_SSH_PORT=8125

export WIFI_LOW_BANDWIDTH_SSIDS=("SM-G900W8_1592")
