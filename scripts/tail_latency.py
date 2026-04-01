#!/usr/bin/env python3
import argparse, glob, math
from pathlib import Path
from typing import List, Tuple, Optional

import pandas as pd
import matplotlib.pyplot as plt


def percentile(sorted_vals: List[float], p: float) -> float:
    if not sorted_vals:
        raise ValueError("No data points.")
    if p <= 0:
        return float(sorted_vals[0])
    if p >= 100:
        return float(sorted_vals[-1])

    n = len(sorted_vals)
    r = (p / 100.0) * (n - 1)  # rank in [0, n-1]
    lo = int(math.floor(r))
    hi = int(math.ceil(r))
    if lo == hi:
        return float(sorted_vals[lo])
    frac = r - lo
    return float(sorted_vals[lo] * (1 - frac) + sorted_vals[hi] * frac)


def tail_stats(vals_ms: List[float]) -> dict:
    s = sorted(vals_ms)
    return {
        "count": len(s),
        "p50_ms": percentile(s, 50),
        "p90_ms": percentile(s, 90),
        "p95_ms": percentile(s, 95),
        "p99_ms": percentile(s, 99),
        "min_ms": float(s[0]),
        "max_ms": float(s[-1]),
        "mean_ms": float(sum(s) / len(s)),
    }


def cdf_xy(vals_ms: List[float]) -> Tuple[List[float], List[float]]:
    s = sorted(vals_ms)
    n = len(s)
    y = [(i + 1) / n for i in range(n)]
    return s, y


def expand_inputs(patterns: List[str]) -> List[Path]:
    out = []
    for pat in patterns:
        matches = glob.glob(pat)
        if matches:
            out.extend(Path(m) for m in matches)
        else:
            p = Path(pat)
            if p.exists():
                out.append(p)
    # de-dupe
    uniq, seen = [], set()
    for p in out:
        rp = str(p.resolve())
        if rp not in seen:
            seen.add(rp)
            uniq.append(p)
    return uniq


def pick_col(df: pd.DataFrame, user_col: Optional[str]) -> str:
    if user_col:
        if user_col not in df.columns:
            raise ValueError(f"--col '{user_col}' not found. Columns: {list(df.columns)}")
        return user_col
    # common candidates
    for c in ["latency_ms", "response_time_ms", "response_time", "latency", "duration_ms"]:
        if c in df.columns:
            return c
    # fallback: first numeric col
    numeric = [c for c in df.columns if pd.api.types.is_numeric_dtype(df[c])]
    if numeric:
        return numeric[0]
    raise ValueError(f"No numeric column found. Columns: {list(df.columns)}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", nargs="+", required=True, help="CSV files or globs with raw latencies.")
    ap.add_argument("--col", default=None, help="Latency column name (ms). If omitted, auto-detect.")
    ap.add_argument("--outdir", default="out", help="Output directory.")
    ap.add_argument("--title", default="Latency CDF", help="Plot title.")
    ap.add_argument("--combined", action="store_true", help="Also plot combined CDF across all runs.")
    ap.add_argument("--prefix", default="", help="Optional prefix appended to all output file names (e.g. '_baseline').")
    args = ap.parse_args()

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    pfx = args.prefix

    files = expand_inputs(args.input)
    if not files:
        raise SystemExit("No input files found.")

    per_run_rows = []
    series = []
    all_vals = []

    for f in files:
        df = pd.read_csv(f)
        col = pick_col(df, args.col)
        vals = pd.to_numeric(df[col], errors="coerce").dropna().astype(float).tolist()
        if not vals:
            raise SystemExit(f"No numeric latencies found in {f} column {col}")

        stats = tail_stats(vals)
        per_run_rows.append({"run": f.stem, **stats})
        series.append((f.stem, vals))
        all_vals.extend(vals)

    # save tables
    pd.DataFrame(per_run_rows).to_csv(outdir / f"{pfx}_per_run_tail_latencies.csv", index=False)

    pooled = tail_stats(all_vals)
    pd.DataFrame([pooled]).to_csv(outdir / f"{pfx}_pooled_tail_latencies.csv", index=False)

    # print summary
    print("Per-run P50/P90/P95/P99 (ms):")
    print(pd.DataFrame(per_run_rows)[["run","count","p50_ms","p90_ms","p95_ms","p99_ms"]].to_string(index=False))
    print("\nPooled across all runs (ms):")
    print(f"Count={pooled['count']}  P50={pooled['p50_ms']:.3f}  P90={pooled['p90_ms']:.3f}  "
          f"P95={pooled['p95_ms']:.3f}  P99={pooled['p99_ms']:.3f}")
    # --- Save summary to file ---
    import os

    summary_path = os.path.join(args.outdir, f"{pfx}_summary.txt")

    with open(summary_path, "w") as f:
        f.write("Pooled across all runs (ms):\n")
        f.write(
         f"Count={pooled['count']} "
         f"P50={pooled['p50_ms']:.3f} "
         f"P90={pooled['p90_ms']:.3f} "
         f"P95={pooled['p95_ms']:.3f} "
         f"P99={pooled['p99_ms']:.3f}\n"
    )

    print(f"Saved summary to {summary_path}")

    # plot per-run CDF
    plt.figure()
    for label, vals in series:
        x, y = cdf_xy(vals)
        plt.plot(x, y, label=label)
    plt.xlabel("Latency (ms)")
    plt.ylabel("CDF")
    plt.title(args.title + " (per run)")
    plt.grid(True, which="both", linestyle="--", linewidth=0.5)
    if len(series) > 1:
        plt.legend()
    plt.tight_layout()
    plt.savefig(outdir / f"{pfx}_cdf_per_run.png", dpi=200)

    # plot combined CDF if requested
    if args.combined:
        plt.figure()
        x, y = cdf_xy(all_vals)
        plt.plot(x, y)
        plt.xlabel("Latency (ms)")
        plt.ylabel("CDF")
        plt.title(args.title + " (combined)")
        plt.grid(True, which="both", linestyle="--", linewidth=0.5)
        plt.tight_layout()
        plt.savefig(outdir / f"{pfx}_cdf_combined.png", dpi=200)

    print(f"\nSaved outputs to {outdir}/")


if __name__ == "__main__":
    main()
