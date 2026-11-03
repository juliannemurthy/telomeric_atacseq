# Snakefile: snakefile_atacseq.py
# Julianne (Yulia) Murthy

import os
from glob import glob
import yaml

configfile: "config.yaml"

# Helper: format strings like "{proj}/path" using config variables
def fmt(s: str) -> str:
    # allow {proj} and nested keys in paths using a small dict
    d = {"proj": config["proj"]}
    return s.format(**d)

PROJ = config["proj"]

MERGE_DIR   = fmt(config["paths"]["merge_dir"])
BIGWIG_DIR  = fmt(config["paths"]["bigwig_dir"])
MATRICES_DIR= fmt(config["paths"]["matrices_dir"])
HEATMAPS_DIR= fmt(config["paths"]["heatmaps_dir"])

BLACKLIST   = fmt(config["refs"]["hg38_blacklist"])
EFFSIZE     = int(config["effective_genome_size"])

CTRL = config["control_sample"]
TRT  = config["treatment_sample"]

REGIONS = list(config["regions"].keys())

# Discover samples from existing merged BAMs
bam_pattern = os.path.join(MERGE_DIR, "{sample}_hg38_frag1_100_merged.bam")
samples = []
for p in glob(os.path.join(MERGE_DIR, "*_hg38_frag1_100_merged.bam")):
    base = os.path.basename(p)
    sample = base.replace("_hg38_frag1_100_merged.bam", "")
    samples.append(sample)
SAMPLES = sorted(set(samples))

# Require control/treatment exist among discovered samples
if CTRL not in SAMPLES:
    raise ValueError(f"control_sample '{CTRL}' not found in merged BAMs under {MERGE_DIR}. Found: {SAMPLES}")
if TRT not in SAMPLES:
    raise ValueError(f"treatment_sample '{TRT}' not found in merged BAMs under {MERGE_DIR}. Found: {SAMPLES}")

# ---- Params ----
mp = config["matrix_params"]
pp = config["plot_params"]

UP = int(mp["upstream"])
DN = int(mp["downstream"])
UP_KB = int(UP // 1000)
DN_KB = int(DN // 1000)

BS = int(mp["bin_size"])
REFPOINT = mp.get("reference_point", "center")

MISSING = "--missingDataAsZero" if mp.get("missing_data_as_zero", True) else ""

COLOR_MAP = pp["color_map"]
ZMIN = pp["zmin"]
ZMAX = pp["zmax"]
DPI = pp["dpi"]
HM_H = pp["heatmap_height"]
HM_W = pp["heatmap_width"]

# Outputs naming (region-specific)
def bw_path(sample):
    return os.path.join(BIGWIG_DIR, f"{sample}_hg38_frag1_100_merged.hg38.RPGC.bs1.bw")

def region_filtered_bed(region):
    # store filtered beds under matrices_dir so everything is per-run reproducible
    return os.path.join(MATRICES_DIR, "regions_filtered", f"{region}.noBlacklist.bed")

def matrix_path(region, sample):
    return os.path.join(MATRICES_DIR, region, "per_condition",
                        f"{sample}_hg38_frag1_100_merged.hg38.RPGC.bs1.{region}.{REFPOINT}2kb.bs{BS}.matrix.gz")

def heatmap_quick_path(region, sample):
    return os.path.join(HEATMAPS_DIR, region,
                        f"{sample}_hg38_frag1_100_merged.hg38.RPGC.bs1.{region}.{REFPOINT}2kb.bs{BS}.heatmap.pdf")

def control_sorted_bed(region):
    return os.path.join(MATRICES_DIR, region, f"{CTRL}.{region}.control_sorted_regions.bed")

def sorted_matrix_path(region, sample):
    return os.path.join(MATRICES_DIR, region, "sorted_across_all",
                        f"{sample}_hg38_frag1_100_merged.hg38.RPGC.bs1.{region}.{REFPOINT}2kb.bs{BS}.sortedToControl.matrix.gz")

def heatmap_sorted_path(region, sample):
    return os.path.join(HEATMAPS_DIR, region,
                        f"{sample}_hg38_frag1_100_merged.hg38.RPGC.bs1.{region}.{REFPOINT}2kb.bs{BS}.sortedToControl.heatmap.pdf")

def profile_pdf(region):
    return os.path.join(HEATMAPS_DIR, region, f"{CTRL}_vs_{TRT}.{region}.{REFPOINT}2kb.profile.pdf")

def panel_png(region):
    return os.path.join(HEATMAPS_DIR, region, f"{region}.{REFPOINT}2kb_over_heatmaps.panel.png")

# ---- Top level targets ----
rule all:
    input:
        # final sorted heatmaps for ctrl+treatment for each region
        [heatmap_sorted_path(r, CTRL) for r in REGIONS],
        [heatmap_sorted_path(r, TRT)  for r in REGIONS],

        # profile + panel for each region
        [profile_pdf(r) for r in REGIONS],
        [panel_png(r)   for r in REGIONS],

# ---- 1) Filter region BED by hg38 blacklist ----
rule filter_regions_blacklist:
    input:
        regions = "/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/refs/PARP3/{region}.bed",
        blacklist = "/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/refs/hg38blacklist_ENCFF023CZC.bed"
    output:
        bed = "/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/experiments/08_25_StrackerLab/matrices/regions_filtered/{region}.noBlacklist.bed"
    shell:
        r"""
        mkdir -p $(dirname {output.bed})
        awk 'BEGIN{{OFS="\t"}} NR==1 && ($2=="start" || $3=="end") {{next}} /^track|^browser|^#/ {{next}} {{print}}' {input.regions} \
          | bedtools intersect -v -a stdin -b {input.blacklist} \
          | sort -k1,1 -k2,2n > {output.bed}
        """

# ---- 2) bamCoverage RPGC bigwig generation (with blacklist) ----
rule bamcoverage_rpgc:
    input:
        bam=bam_pattern,
        blacklist=BLACKLIST
    output:
        bw=os.path.join(BIGWIG_DIR, "{sample}_hg38_frag1_100_merged.hg38.RPGC.bs1.bw")
    threads: int(config["resources"]["bamcoverage"]["threads"])
    resources:
        mem_mb=int(config["resources"]["bamcoverage"]["mem_mb"]),
        time=str(config["resources"]["bamcoverage"]["time"])
    shell:
        r"""
        mkdir -p {BIGWIG_DIR}
        bamCoverage \
          --bam {input.bam} \
          --outFileName {output.bw} \
          --outFileFormat bigwig \
          --normalizeUsing RPGC \
          --effectiveGenomeSize {EFFSIZE} \
          --ignoreDuplicates \
          --binSize 1 \
          --blackListFileName {input.blacklist} \
          --numberOfProcessors {threads}
        """

# ---- 3) computeMatrix per sample, per region ----
rule compute_matrix_reference_point:
    input:
        bw=lambda wc: bw_path(wc.sample),
        bed=region_filtered_bed("{region}")
    output:
        mat=matrix_path("{region}", "{sample}")
    threads: int(config["resources"]["compute_matrix"]["threads"])
    resources:
        mem_mb=int(config["resources"]["compute_matrix"]["mem_mb"]),
        time=str(config["resources"]["compute_matrix"]["time"])
    shell:
        r"""
        mkdir -p $(dirname {output.mat})
        computeMatrix reference-point \
          --referencePoint {REFPOINT} \
          -b {UP} -a {DN} -bs {BS} \
          {MISSING} \
          -R {input.bed} \
          -S {input.bw} \
          --numberOfProcessors {threads} \
          -o {output.mat}
        """

# ---- 4) quick heatmap ----
rule plot_heatmap_quick:
    input:
        mat=matrix_path("{region}", "{sample}")
    output:
        pdf=heatmap_quick_path("{region}", "{sample}")
    threads: int(config["resources"]["plot"]["threads"])
    resources:
        mem_mb=int(config["resources"]["plot"]["mem_mb"]),
        time=str(config["resources"]["plot"]["time"])
    shell:
        r"""
        mkdir -p $(dirname {output.pdf})
        base=$(basename {input.mat} .matrix.gz)
        plotHeatmap \
          -m {input.mat} \
          -o {output.pdf} \
          --colorMap {COLOR_MAP} \
          --plotType lines --averageTypeSummaryPlot mean \
          --refPointLabel "{wildcards.region} {REFPOINT}" --startLabel "-{UP_KB} kb" --endLabel "+{DN_KB} kb" \
          --xAxisLabel "Distance from {wildcards.region} {REFPOINT} (bp)" \
          --yAxisLabel "{wildcards.region} peak regions" \
          --regionsLabel "{wildcards.region}" \
          --samplesLabel "{wildcards.sample}" \
          --zMin {ZMIN} --zMax {ZMAX} \
          --dpi {DPI} \
          --heatmapHeight {HM_H} \
          --heatmapWidth {HM_W}
        """

# ---- 5) export control-sorted region order BED (lock row order) ----
rule export_control_sorted_regions:
    input:
        control_mat=lambda wc: matrix_path(wc.region, CTRL)
    output:
        bed=control_sorted_bed("{region}"),
        preview=os.path.join(MATRICES_DIR, "{region}", "sorted_across_all", "control_sort_preview.pdf")
    threads: int(config["resources"]["plot"]["threads"])
    resources:
        mem_mb=int(config["resources"]["plot"]["mem_mb"]),
        time=str(config["resources"]["plot"]["time"])
    shell:
        r"""
        mkdir -p $(dirname {output.bed})
        mkdir -p $(dirname {output.preview})
        plotHeatmap \
          -m {input.control_mat} \
          --sortRegions descend \
          --outFileSortedRegions {output.bed} \
          -o {output.preview}
        """

# ---- 6) sort each matrix to control bed ----
rule sort_matrix_to_control:
    input:
        mat=matrix_path("{region}", "{sample}"),
        bed=control_sorted_bed("{region}")
    output:
        sorted_mat=sorted_matrix_path("{region}", "{sample}")
    threads: int(config["resources"]["plot"]["threads"])
    resources:
        mem_mb=int(config["resources"]["plot"]["mem_mb"]),
        time=str(config["resources"]["plot"]["time"])
    shell:
        r"""
        mkdir -p $(dirname {output.sorted_mat})
        computeMatrixOperations sort \
          -R {input.bed} \
          -m {input.mat} \
          -o {output.sorted_mat}
        """

# ---- 7) final locked-order heatmaps ----
rule plot_heatmap_sorted:
    input:
        sorted_mat=sorted_matrix_path("{region}", "{sample}"),
        bed=control_sorted_bed("{region}")
    output:
        pdf=heatmap_sorted_path("{region}", "{sample}")
    threads: int(config["resources"]["plot"]["threads"])
    resources:
        mem_mb=int(config["resources"]["plot"]["mem_mb"]),
        time=str(config["resources"]["plot"]["time"])
    shell:
        r"""
        mkdir -p $(dirname {output.pdf})
        plotHeatmap \
          -m {input.sorted_mat} \
          -o {output.pdf} \
          --colorMap {COLOR_MAP} \
          --plotType lines --averageTypeSummaryPlot mean \
          --refPointLabel "{wildcards.region} {REFPOINT}" --startLabel "-{UP_KB} kb" --endLabel "+{DN_KB} kb" \
          --xAxisLabel "Distance from {wildcards.region} {REFPOINT} (bp)" \
          --yAxisLabel "{wildcards.region} regions (ranked by {CTRL} ATAC signal)" \
          --regionsLabel "{wildcards.region}" \
          --samplesLabel "{wildcards.sample}" \
          --zMin {ZMIN} --zMax {ZMAX} \
          --dpi {DPI} \
          --heatmapHeight {HM_H} \
          --heatmapWidth {HM_W}
        """

# ---- 8) create CTRL vs siP3 profile PDF ----
rule plot_profile_ctrl_vs_treatment:
    input:
        bed=region_filtered_bed("{region}"),
        ctrl_bw=lambda wc: bw_path(CTRL),
        trt_bw=lambda wc: bw_path(TRT)
    output:
        mat=os.path.join(MATRICES_DIR, "{region}", f"{CTRL}_vs_{TRT}.{REFPOINT}2kb.bs{BS}.matrix.gz"),
        pdf=profile_pdf("{region}")
    threads: int(config["resources"]["compute_matrix"]["threads"])
    resources:
        mem_mb=int(config["resources"]["compute_matrix"]["mem_mb"]),
        time=str(config["resources"]["compute_matrix"]["time"])
    shell:
        r"""
        mkdir -p $(dirname {output.mat})
        mkdir -p $(dirname {output.pdf})
        computeMatrix reference-point \
          --referencePoint {REFPOINT} \
          -b {UP} -a {DN} -bs {BS} \
          {MISSING} \
          -R {input.bed} \
          -S {input.ctrl_bw} {input.trt_bw} \
          --numberOfProcessors {threads} \
          -o {output.mat}

        plotProfile \
          -m {output.mat} \
          -out {output.pdf} \
          --perGroup \
          --plotType lines \
          --refPointLabel "{wildcards.region} {REFPOINT}" \
          --startLabel "-{UP_KB} kb" --endLabel "+{DN_KB} kb" \
          --samplesLabel "{CTRL}" "{TRT}" \
          --yAxisLabel "Mean RPGC signal" \
          --dpi {DPI}
        """

# ---- 9) combine into panel PNG (pdftocairo + PIL) ----
rule make_panel_png:
    input:
        prof=profile_pdf("{region}"),
        h1=heatmap_sorted_path("{region}", CTRL),
        h2=heatmap_sorted_path("{region}", TRT)
    output:
        png=panel_png("{region}")
    threads: 1
    resources:
        mem_mb=8000,
        time="01:00:00"
    shell:
        r"""
        outdir=$(dirname {output.png})
        mkdir -p "$outdir"

        # render PDFs -> PNG (pdftocairo writes <prefix>.png)
        pdftocairo -png -singlefile {input.prof} "$outdir/profile"
        pdftocairo -png -singlefile {input.h1}   "$outdir/heatmap_{CTRL}"
        pdftocairo -png -singlefile {input.h2}   "$outdir/heatmap_{TRT}"

        export OUTDIR_PLOT="$outdir"
        export REGION="{wildcards.region}"
        export OUTNAME="$(basename {output.png})"
        export CTRL="{CTRL}"
        export TRT="{TRT}"

        python - <<'PY'
from PIL import Image
import os

outdir = os.environ["OUTDIR_PLOT"]
outname = os.environ["OUTNAME"]
ctrl = os.environ["CTRL"]
trt  = os.environ["TRT"]

profile = Image.open(os.path.join(outdir, "profile.png")).convert("RGBA")

hm_ctrl_path = os.path.join(outdir, "heatmap_" + ctrl + ".png")
hm_trt_path  = os.path.join(outdir, "heatmap_" + trt  + ".png")

hm_ctrl = Image.open(hm_ctrl_path).convert("RGBA")
hm_trt  = Image.open(hm_trt_path).convert("RGBA")

# make heatmaps same height
H = max(hm_ctrl.height, hm_trt.height)
def pad_to_height(im, H):
    if im.height == H:
        return im
    canvas = Image.new("RGBA", (im.width, H), (255,255,255,255))
    canvas.paste(im, (0, (H - im.height)//2))
    return canvas

hm_ctrl = pad_to_height(hm_ctrl, H)
hm_trt  = pad_to_height(hm_trt, H)

heat_row = Image.new("RGBA", (hm_ctrl.width + hm_trt.width, H), (255,255,255,255))
heat_row.paste(hm_ctrl, (0,0))
heat_row.paste(hm_trt, (hm_ctrl.width, 0))

# match widths
W = max(profile.width, heat_row.width)
def pad_to_width(im, W):
    if im.width == W:
        return im
    canvas = Image.new("RGBA", (W, im.height), (255,255,255,255))
    canvas.paste(im, ((W - im.width)//2, 0))
    return canvas

profile  = pad_to_width(profile, W)
heat_row = pad_to_width(heat_row, W)

panel = Image.new("RGBA", (W, profile.height + heat_row.height), (255,255,255,255))
panel.paste(profile, (0,0))
panel.paste(heat_row, (0, profile.height))

out = os.path.join(outdir, outname)
panel.convert("RGB").save(out, "PNG")
print("WROTE", out)
PY

        ls -lh {output.png}
        """

