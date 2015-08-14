#!/usr/bin/env bash
quote_re() {
    sed 's|/|\\/|g'<<<"$1"
}
