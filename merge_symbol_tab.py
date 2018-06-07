import argparse

from operator import itemgetter

parser = argparse.ArgumentParser()
parser.add_argument("--output", required=True, type=argparse.FileType("wt"))
parser.add_argument("--input", required=True, nargs="+", type=argparse.FileType("rt"))

args = parser.parse_args()


symbol_table = {}
for input_symbols in args.input:
    for line in input_symbols:
        symbol, key = line.split()
        if symbol not in symbol_table:
            symbol_table[symbol] = len(symbol_table)

for key, value in sorted(symbol_table.items(), key=itemgetter(1)):
    args.output.write("{}\t{}\n".format(key, value))
