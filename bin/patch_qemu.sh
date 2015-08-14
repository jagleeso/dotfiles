#!/usr/bin/env sh
start_commit="f6f5f464b4ce62aa990e27f230b21d4e3983a018"
end_commit="$(git log | head -n 1 | sed 's/^commit\s\+//)'
patch=$LKERN/exynos7420.${start_commit}_${end_commit}.diff
git diff $start_commit..$end_commit -- $KERN > $patch

