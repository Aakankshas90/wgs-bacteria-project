# Nanopore Whole-Genome Sequencing Pipeline for Bacterial Genome Assembly and AMR Detection

## Overview

This repository contains a reproducible workflow for bacterial genome assembly and antimicrobial resistance profiling using Oxford Nanopore long-read sequencing data.

## Workflow
Read QC (NanoPlot)
Read filtering (NanoFilt)
Assembly (Flye)
Assembly QC (QUAST)
Polishing (Racon + Medaka)
Annotation (Prokka)
AMR detection (Abricate, AMRFinderPlus)
16S phylogenetic analysis

## Tools
NanoPlot
NanoFilt
Flye
Minimap2
Samtools
Racon
Medaka
QUAST
Prokka
Abricate
AMRFinderPlus
