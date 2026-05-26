#!/usr/bin/env python3

import argparse
import datetime
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument("--summary", required=True)
parser.add_argument("--versions", required=True)
parser.add_argument("--pipeline_version", required=True)
parser.add_argument("--out", required=True)
args = parser.parse_args()

# Read summary with explicit column names
summary = pd.read_csv(
    args.summary,
    sep="\t",
    header=None,
    names=["sample", "organism", "tool", "result_type", "result_value"]
)

# Parse versions.yml without PyYAML
tool_versions = {}

with open(args.versions) as fh:
    for line in fh:
        line = line.rstrip()

        # Skip blank lines
        if not line.strip():
            continue

        # Keep only indented lines like: "  ectyper: 2.0.0"
        if line.startswith(" ") or line.startswith("\t"):
            stripped = line.strip()

            if ":" in stripped:
                tool, version = stripped.split(":", 1)
                tool = tool.strip().lower()
                version = version.strip().strip("'\"")

                tool_versions[tool] = version

basset_version = args.pipeline_version

summary["tool_version"] = (
    summary["tool"]
    .str.lower()
    .map(tool_versions)
    .fillna("")
)

summary["basset_version"] = basset_version
summary["analysis_date"] = datetime.date.today().isoformat()

summary = summary.sort_values(
    by=["organism", "sample", "tool", "result_type"],
    kind="stable"
)

summary.to_csv(args.out, sep="\t", index=False)
