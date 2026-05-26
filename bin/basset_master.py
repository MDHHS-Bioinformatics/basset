#!/usr/bin/env python3

import argparse
import pandas as pd
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--run_summary", required=True)
parser.add_argument("--out", default="basset_summary_master.tsv")
parser.add_argument("--existing_master", nargs="*", default=[])
args = parser.parse_args()

columns = [
    "sample",
    "organism",
    "tool",
    "result_type",
    "result_value",
    "tool_version",
    "basset_version",
    "analysis_date"
]

dfs = []

for master_file in args.existing_master:
    master = Path(master_file)
    if master.exists() and master.stat().st_size > 0:
        dfs.append(pd.read_csv(master, sep="\t", dtype=str))

run_summary = Path(args.run_summary)
if run_summary.exists() and run_summary.stat().st_size > 0:
    dfs.append(pd.read_csv(run_summary, sep="\t", dtype=str))

if dfs:
    final = pd.concat(dfs, ignore_index=True).fillna("")
    final = final.drop_duplicates()
else:
    final = pd.DataFrame(columns=columns)

final = final.sort_values(
    by=["analysis_date", "organism", "sample", "tool", "result_type"],
    kind="stable"
)

final.to_csv(args.out, sep="\t", index=False)

final.to_csv(args.out, sep="\t", index=False)
