# POS Relational Database Project

## Overview
This repository contains a relational database project based on a synthetic POS (Point of Sale) dataset from a fast-food restaurant (QSR). The project demonstrates the design of a star schema and the creation of dimensional tables from a transactional fact table, enabling advanced SQL queries and data analysis. It is intended as a practice environment for data modeling, SQL, and exploratory data analysis in the context of a Data Science course or project.

## Repository Contents
- **archive/**: Contains the original synthetic POS dataset used as the source for this project.
- **database_structure.png**: Visual diagram of the relational model, showing the fact table and all dimensional tables.
- **1_create_tables.sql**: SQL script to create all tables in PostgreSQL.
- **2_insert_fact_table.sql**: SQL script to populate the fact table with transactional data.
- **3_insert_dim_tables.sql**: SQL script to populate dimensional tables (items, stores, discounts, and customers).
- **4_queries.sql**: Sample SQL queries for exploring the database and performing analysis.

## Usage
1. Ensure you have **PostgreSQL** installed and running.
2. Open each SQL script in numerical order and execute it to create and populate the database.
3. Use the included `database_structure.png` as a reference for table relationships and structure.
4. Explore the data with custom SQL queries for analysis, reporting, or practice.

## Project Goals
- Normalize repetitive attributes from the transactional POS dataset into independent dimensional tables.
- Build a coherent star schema that reduces redundancy and improves scalability.
- Practice advanced SQL queries on a realistic, transactional dataset.
- Demonstrate the ability to design an extensible relational database from realistic synthetic data.

## Notes
- This project does **not** aim to replicate the original dataset in full but focuses on database design, normalization, and usability for analysis.
- The `archive/` folder contains the original data for reference.
- Scripts should be executed in the given numerical order to ensure dependencies are properly handled.
