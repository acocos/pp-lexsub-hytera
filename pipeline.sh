#!/usr/bin/env bash

FILELIST=$1

######################################
# Resources -- change paths as needed
######################################
HYTERPATH=./hytera
ADDCOSPATH=./lexsub_addcos
PPDBFILE=./data/ppdb-2.0-xxl-lexical.gz
EMBEDDINGFILE=./data/word_pos.agiga.4b.gensim3.4
MINSCORE=2.3

######################################
# Pipeline
######################################

# Run lexsub_addcos on reference files and convert results to FST
# ----------------------------------------------------------------
while read -r REFFILE HYPFILE
do
    
    BASEDIR=`dirname $REFFILE`
    
    # tokenize the English reference translations with Moses (if needed; if not, replace this block with `cp $REFFILE $REFFILE.tok`)
    cd tokenizer_wmt
    tokenizer.perl < ../$REFFILE > ../$REFFILE.tok
    cd ..
    
    # format tokenized ref sentences (one per line) for input to lexsub_addcos
    python format_for_addcos.py $REFFILE.tok 
    # the above command will output the file needed as input to addcos
    
    # run addcos
    ADDCOSFILE=$REFFILE.tok.addcosinput
    ALLDATAFILE=$REFFILE.tok.alldata.json
    OUTFILE=$REFFILE.addcosoutput.$MINSCORE
    python $ADDCOSPATH/lexsub_addcos_ppdb.py $ADDCOSFILE $PPDBFILE $EMBEDDINGFILE $OUTFILE $MINSCORE
    
    # re-format addcos output for hyter
    FSTDIR=$BASEDIR/fst
    mkdir -p $FSTDIR
    
    FN=`basename $OUTFILE`
    mkdir -p $FSTDIR/$FN
    
    python format_fst.py $OUTFILE $ALLDATAFILE $FSTDIR/$FN

done < "$FILELIST"

# Compile all FST and force them to use the same symbol table
# -----------------------------------------------------------

python merge_symbol_tab.py --input `find $FSTDIR -name syms.txt` --output ${FSTDIR}/all_symbols.txt

# Create FAR and run hytera
# -----------------------------------------------------------
while read -r REFFILE HYPFILE;
do
    BASEDIR==`dirname $REFFILE`
    FSTDIR=$BASEDIR/fst
    REFDIR=$BASEDIR/automatic_references
    mkdir -p $REFDIR
    for dir_name in `find $FSTDIR -mindepth 1 -maxdepth 1 -type d`;
    do
        echo "processing ${dir_name}"
        for fn in `ls ${dir_name}/*.fst.txt`;
        # compile FST
        do
            ./hytera/bin/fstcompile --keep_isymbols --keep_osymbols --isymbols=${FSTDIR}/all_symbols.txt --osymbols=${FSTDIR}/all_symbols.txt $fn ${fn/.fst.txt/.fst};
        done
        ref=`basename $dir_name`
        # create far
        ./hytera/bin/farcreate ${dir_name}/*.fst $REFDIR/${ref}.far
        # run hyter
        ./hytera/hyter --references $REFDIR/${ref}.far --hypotheses $HYPFILE
    done
done < "$FILELIST"
