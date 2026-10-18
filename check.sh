#!/usr/bin/env bash
# Check that every file listed in a World of Warcraft addon's TOC, and in the XML files it loads, exists.
# Prints each missing path and exits 1 if any.
#
# Environment (optional):
#   ADDON_PATH  addon root (default: .)
set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

cd "${ADDON_PATH:-.}" || die "addon path not found: ${ADDON_PATH}"

shopt -s nullglob
tocs=(*.toc)
shopt -u nullglob
(( ${#tocs[@]} == 1 )) || die "expected exactly one .toc in $(pwd), found ${#tocs[@]}"
toc=${tocs[0]}

declare -A seen
checked=0
missing=0

# check_file <path> <source>: path is relative to the addon root, with / separators.
check_file() {
    local path=$1 source=$2 match pattern
    [[ -n ${seen[$path]:-} ]] && return
    seen[$path]=1

    # [Family], [Game] and [TextLocale] expand per client; require at least one match.
    if [[ $path =~ \[(Family|Game|TextLocale)\] ]]; then
        pattern=${path//"[Family]"/*}
        pattern=${pattern//"[Game]"/*}
        pattern=${pattern//"[TextLocale]"/*}
        local found=0
        while IFS= read -r match; do
            found=1
            check_file "$match" "$source"
        done < <(compgen -G "$pattern" || true)
        (( found )) || { echo "missing: $path (from $source)"; missing=$((missing + 1)); }
        return
    fi

    checked=$((checked + 1))
    if [[ ! -f $path ]]; then
        echo "missing: $path (from $source)"
        missing=$((missing + 1))
    elif [[ $path == *.xml ]]; then
        check_xml "$path"
    fi
}

# check_xml <path>: checks <Script file> and <Include file>, relative to the XML's folder.
check_xml() {
    local xml=$1 dir file
    dir=$(dirname "$xml")
    while IFS= read -r file; do
        file=${file//\\//}
        [[ $dir != . ]] && file="$dir/$file"
        check_file "$file" "$xml"
    done < <(perl -0777 -ne 's/<!--.*?-->//gs; print "$1\n" while /<(?:Script|Include)\b[^>]*?\bfile\s*=\s*["\x27]([^"\x27]*)["\x27]/g' "$xml")
}

# shellcheck disable=SC2094 # $toc is only passed as a label
while IFS= read -r line || [[ -n $line ]]; do
    line=${line%$'\r'}
    line=${line#"${line%%[![:space:]]*}"}
    [[ -z $line || $line == \#* ]] && continue
    # strip trailing [AllowLoad...] directives
    while [[ $line =~ ^(.*[^[:space:]])[[:space:]]*\[Allow[^]]*\][[:space:]]*$ ]]; do
        line=${BASH_REMATCH[1]}
    done
    line=${line%"${line##*[![:space:]]}"}
    check_file "${line//\\//}" "$toc"
done < "$toc"

(( missing == 0 )) || die "$missing missing file(s)"
echo "OK: $checked files from $toc and its XML exist"
