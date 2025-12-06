#!/usr/bin/env bash
set -euo pipefail

RAW_FASTQ="/mnt/d/ngs/abhi/L25_7/rawdata/L25_7.fastq.gz"
OUT="/mnt/d/ngs/abhi/L25_7/rawdata/results"
THREADS=8

mkdir -p "$OUT"/{nanofilt,nanoplot,assembly,polish,map,prokka,abricate,amrfinder,quast,logs}

# 0) Quick check (you already have NanoPlot).
NanoPlot --fastq "$RAW_FASTQ" -o "$OUT/nanoplot" -t "$THREADS"

# 1) Filter reads (length & quality) using NanoFilt
#Keep reads > 500 bp and average Q >= 8 (adjust thresholds to taste)
zcat "$RAW_FASTQ" | NanoFilt -l 500 -q 8 > "$OUT/nanofilt/reads.filtered.fastq" 2> "$OUT/logs/nanofilt.log"

# compress filtered fastq (optional)
gzip -f "$OUT/nanofilt/reads.filtered.fastq"

# 2) De novo assembly with Flye (works well for bacterial genomes)
flye --nano-raw "$OUT/nanofilt/reads.filtered.fastq.gz" \
     --out-dir "$OUT/assembly/flye" --threads "$THREADS" --genome-size 5m \
     > "$OUT/logs/flye.log" 2>&1

# Assembly contigs
CONTIGS="$OUT/assembly/flye/assembly.fasta"

# 3) Assembly QC with QUAST
quast.py "$CONTIGS" -o "$OUT/quast/flye" -t "$THREADS" > "$OUT/logs/quast.log" 2>&1 || true

# 4) Polishing: map reads to contigs with minimap2, polish with racon (iterative) + medaka
minimap2 -t "$THREADS" -a "$CONTIGS" "$OUT/nanofilt/reads.filtered.fastq.gz" | samtools sort -o "$OUT/map/reads2contigs.sorted.bam" -T /tmp/tmp -@ "$THREADS"
samtools index "$OUT/map/reads2contigs.sorted.bam"

# Racon polishing (2 rounds recommended)
samtools view -h "$OUT/map/reads2contigs.sorted.bam" | samtools fastq - > "$OUT/map/reads_for_racon.fastq"
racon -t "$THREADS" "$OUT/map/reads_for_racon.fastq" "$OUT/map/reads2contigs.sorted.bam" "$CONTIGS" > "$OUT/polish/racon_round1.fasta"
# second round
racon -t "$THREADS" "$OUT/map/reads_for_racon.fastq" "$OUT/map/reads2contigs.sorted.bam" "$OUT/polish/racon_round1.fasta" > "$OUT/polish/racon_round2.fasta"

# Medaka polishing (requires medaka model; choose model matching your basecaller/kit, e.g., r941_min_high_g360)
medaka_consensus -i "$OUT/nanofilt/reads.filtered.fastq.gz" -d "$OUT/polish/racon_round2.fasta" -o "$OUT/polish/medaka" -t "$THREADS" -m r941_min_high_g360

POLISHED="$OUT/polish/medaka/consensus.fasta"

# 5) Optional: circular contig check (bacterial chromosome may be circular)
# (you can use circlator or inspect Prokka/QUAST outputs)

# 6) Annotate with Prokka
prokka --outdir "$OUT/prokka" --prefix sample --locustag SAMPLE --cpus "$THREADS" "$POLISHED" > "$OUT/logs/prokka.log" 2>&1

# 7) AMR detection - Abricate (CARD, ResFinder) (assembly-based)
# make sure abricate DBs are installed: `abricate --setupdb` and `abricate --update`
abricate --db card "$POLISHED" > "$OUT/abricate/sample_card.tsv" 2> "$OUT/logs/abricate_card.log" || true
abricate --db resfinder "$POLISHED" > "$OUT/abricate/sample_resfinder.tsv" 2> "$OUT/logs/abricate_resfinder.log" || true
abricate --summary "$OUT/abricate/sample_card.tsv" > "$OUT/abricate/sample_card_summary.tsv" || true
abricate --summary "$OUT/abricate/sample_resfinder.tsv" > "$OUT/abricate/sample_resfinder_summary.tsv" || true

# 8) AMR detection - NCBI AMRFinderPlus (recommended)
amrfinder -n "$POLISHED" -o "$OUT/amrfinder/sample_amrfinder.tsv" --organism bacteria --threads "$THREADS" 2> "$OUT/logs/amrfinder.log" || true

# 9) OPTIONAL: map reads to known AMR gene database (read-based evidence)
# (download a nucleotide AMR DB in fasta, e.g. CARD nucleotide FASTA)
# minimap2 -t "$THREADS" -a amr_db.fna "$OUT/nanofilt/reads.filtered.fastq.gz" | samtools view -bS - | samtools sort -o "$OUT/map/reads2amr.bam"
# samtools index "$OUT/map/reads2amr.bam"
# samtools idxstats "$OUT/map/reads2amr.bam" > "$OUT/map/reads2amr.idxstats"

echo "DONE. Results in $OUT (assembly, prokka, abricate, amrfinder, quast)."
