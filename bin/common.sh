#!/usr/bin/env bash
quote_re() {
    sed 's|/|\\/|g'<<<"$1"
}

# kill windows without a title
kwin() {
    wmctrl -l | ruby -ane '
    hex = $F[0];
    name = $F[3..$F.size].join("");
    is_empty = name == "";
    # puts "hex = #{ hex }, name = #{ name }, is_empty = #{ is_empty }";
    if is_empty then
        puts hex
    end
    ' | while read window; do
        wmctrl -i -c $window
    done
}

if [ "$RUN_COMMON" == "yes" ]; then
    "$@"
fi
