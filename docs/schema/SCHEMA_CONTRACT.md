# Schema Contract — PHA-WAW-001

## Purpose
This registry is the public structural reference for the analytical SQL artifacts.

## Scope
- Physical database objects inventoried: **18**
- Analytical tables: **17**
- `sysdiagrams`: retained as a database-support object and not treated as an analytical source table.

## Governance rule
The supplied physical schema inventory is the structural source used for this repository review. No primary key, foreign key, uniqueness constraint, or cardinality is inferred unless it is explicitly present in the supplied source material or documented by the SQL artifact itself.

## Publication boundary
No patient-level records are included. This repository contains SQL logic, aggregated analytical outputs, documentation, and schema metadata only.

## Important execution note
The repository preserves the supplied SQL artifacts. This review does not claim to have independently executed the SQL against the original SQL Server instance.
