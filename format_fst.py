#!/usr/bin/env python

'''
format_fst.py

Format the output substitutions from lexsub_addcos_ppdb.py as a FAR file for input
to hyttera

Writes results to sys.stdout

USAGE:
python format_for_hyter.py <ADDCOSFILE> <ALLDATAFILE> > <OUTFILE>

- ADDCOSFILE is the file with predicted substitutes output by lexsub_addcos_ppdb.py
- ALLDATAFILE is hte corresponding json file output by format_for_addcos.py
'''

import os, sys, csv
import json
from itertools import tee

def pairwise(iterable):
    a, b = tee(iterable)
    next(b, None)
    return zip(a,b)

def read_addcos_output(fname):
    data = {}
    with open(fname, 'rU') as fin:
        for line in fin:
            tgt, subs = line.split(' :: ')
            tgtid, pos, word = tgt.split('--')
            sublist = []
            if len(subs) > 0:
                subs = [s.strip().split() for s in subs.split('//') if len(s.strip())>0]
                sublist = [w for w,s in subs if float(s)>=0]
            data[int(tgtid)] = (word, pos, sublist)
    return data

def format_fst(subs, alldata, outdir):
    vocabulary = set()
    cnt = 0
    for sid, toks, tgts, tgtoffsets, tgtids in alldata:
        sentence = [w.split('_')[0].lower() for w in toks]
        substitutions = []
        for tgtid, tgtoffset in zip(tgtids, tgtoffsets):
            word, pos, sublist = subs.get(tgtid, (None,None,None))
            if not word:
                continue
            substitutions.extend([(tgtoffset, sub) for sub in sublist])
        
        with open(os.path.join(outdir, "%0.5d.fst.txt" % sid), 'wt') as ofile:
            for from_state, to_state in pairwise(range(len(sentence)+1)):
                vocabulary.add(sentence[from_state])
                ofile.write("%d\t%d\t%s\t%s\n" % (from_state, to_state, 
                                                  sentence[from_state].encode('utf8'), 
                                                  sentence[from_state].encode('utf8')))
            ofile.write('%d\n' % to_state)
            
            for idx, word in substitutions:
                vocabulary.add(word)
                ofile.write("%d\t%d\t%s\t%s\n" % (idx, idx+1, word, word))
        cnt += 1
    print("Generated %d references" % cnt)
    return vocabulary

def write_symboltable(vocab, outdir):
    with open(os.path.join(outdir, "syms.txt"), 'wt') as fout:
        print >> fout, '\t'.join(("<eps>", "0"))
        print >> fout, '\t'.join(("<phi>", "1"))
        print >> fout, '\t'.join(("<rho>", "2"))
        print >> fout, '\t'.join(("<sigma>", "e"))
        
        for idx, word in enumerate(vocab, start=4):
            print >> fout, '\t'.join((word.encode('utf8'), str(idx)))

if __name__=="__main__":
    
    addcosfile = sys.argv[1]
    alldatafile = sys.argv[2]
    outdir = sys.argv[3]
    
    subs = read_addcos_output(addcosfile)
    
    with open(alldatafile, 'rU') as fin:
        alldata = json.load(fin)
    
    vocabulary = format_fst(subs, alldata, outdir)
    
    write_symboltable(vocabulary, outdir)
