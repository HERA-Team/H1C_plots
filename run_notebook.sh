#!/bin/bash 

# print out help statement
if [ $1 = '-h' ] || [ $1 = '--help' ]
then
    echo 'Usage:'
    echo 'run_notebook.sh <arg1: hera_data_dir>'
    echo ''
    echo 'argument1 : JD directory where visibility data *.uv files live'
    exit 0
fi

# assign data directory
export DATA_PATH=$1

# get JD
jd=`python -c "print '${DATA_PATH}'.split('/')[-1]"`

# get more env vars
BASENBDIR=$HOME/HERA_plots
OUTPUT=data_inspect_"$jd".ipynb
OUTPUTDIR=$HOME/HERA_plots

# copy and run notebook
jupyter nbconvert --output=$OUTPUTDIR/$OUTPUT --to notebook --execute $BASENBDIR/Data_Inspect.ipynb

# cd to git repo
cd $OUTPUTDIR

# add to git repo
git add $OUTPUT
git commit -m "data inspect notebook for $jd"
git push
