#!/bin/bash 

# print out help statement
if [ $1 = '-h' ] || [ $1 = '--help' ]
then
    echo 'Usage:'
    echo 'run_notebook.sh <arg1: hera_data_dir> <arg2: HERA_plots/ path>'
    echo ''
    echo 'argument1 : JD directory where visibility data *.uv files live'
    echo 'argument2 : path to HERA_plots/ directory'
    exit 0
fi

if [ $1 = '']
then
    echo "arg1 is blank"
    exit 1
fi

if [ $2 = '']
then
    echo "arg2 is blank"
    exit 1
fi

# assign data directory
export DATA_PATH=$1

# get JD
jd=`python -c "print '${DATA_PATH}'.split('/')[-1]"`

# get more env vars
BASENBDIR=$2
OUTPUT=data_inspect_"$jd".ipynb
OUTPUTDIR=$2

# copy and run notebook
jupyter nbconvert --output=$OUTPUTDIR/$OUTPUT --to notebook --ExecutePreprocessor.allow_errors=True --ExecutePreprocessor.timeout=-1 --execute $BASENBDIR/Data_Inspect.ipynb

# cd to git repo
cd $OUTPUTDIR

# add to git repo
git add $OUTPUT
git commit -m "data inspect notebook for $jd"
git push
