# Nanopore Whole-Genome Sequencing Pipeline for Bacterial Genome Assembly and AMR Detection

## Overview

This repository contains the history of commands used and a workflow for bacterial genome assembly and antimicrobial resistance profiling using Oxford Nanopore long-read sequencing data for two different bacterial strains.

## Workflow
Read QC (NanoPlot)
Read filtering (NanoFilt)
Assembly (Flye)
Assembly QC (QUAST)
Polishing (Racon + Medaka)
Annotation (Prokka)
AMR detection (Abricate, AMRFinderPlus)
Virulence detection, etc.
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
