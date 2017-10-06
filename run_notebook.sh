#!/bin/bash

# print out help statement
if [ $1 = '-h' ] || [ $1 = '--help' ]
then
    echo 'Usage:'
    echo 'run_notebook.sh <arg1: session ID> <arg2: HERA_plots/ path>'
    echo ''
    echo 'argument1 : the ID of the session to process'
    echo 'argument2 : path to HERA_plots/ directory'
    exit 0
fi

if [ -z "$1" ] ; then
    echo "arg1 is blank"
    exit 1
fi

if [ -z "$2" ] ; then
    echo "arg2 is blank"
    exit 1
fi

# Exit with an error if any sub-command fails.

set -e

# Create a temporary Lustre directory for exporting the data and command the
# Librarian to populate it.

sessid="$1"
staging_dir=$(mktemp -d --tmpdir=/lustre/aoc/projects/hera/nightlynb sessid$sessid.XXXXXX)
search="{
 \"session-id-is-exactly\": $sessid,
 \"or\": {
  \"name-matches\": \"%.HH.uv\",
  \"name-matches\": \"%.HH.uvOR\",
  \"name-matches\": \"%.json\",
  \"name-matches\": \"%.calfits\"
 }
}
"

chmod ug+rwx "$staging_dir"
librarian_stage_files.py --wait local "$staging_dir" "$search"

DATA_PATH=

for item in "$staging_dir"/2* ; do
    if [ -n "$DATA_PATH" ] ; then
        echo >&1 "WARNING: multiple subdirectories staged? $DATA_PATH, $item"
        break
    fi
    export DATA_PATH="$item"
done

jd=$(basename $DATA_PATH)

# get more env vars
BASENBDIR=$2
OUTPUT=data_inspect_"$jd".ipynb
OUTPUTDIR=$2

# copy and run notebook
jupyter nbconvert --output=$OUTPUTDIR/$OUTPUT \
  --to notebook \
  --ExecutePreprocessor.allow_errors=True \
  --ExecutePreprocessor.timeout=-1 \
  --execute $BASENBDIR/Data_Inspect.ipynb

# cd to git repo
cd $OUTPUTDIR

# add to git repo
git add $OUTPUT
git commit -m "data inspect notebook for $jd"
git push

rm -rf "$staging_dir"
