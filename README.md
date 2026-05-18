# NHANES Public Health: Deep-Dive Data Engineering & Analytics

An end-to-end data project demonstrating advanced SQL transformation, data cleansing, and data pipeline principles, culminating in an interactive Tableau executive dashboard.

## Interactive Dashboard
The finalized, processed, and cleaned datasets were visualized to unearth socio-demographic health trends.
* **Live Dashboard:** [Link to Tableau Public Dashboard](https://public.tableau.com/views/NHANESHealthandDemographicsInsights2017-2018/NHANESHealthDemographicsInsights2017-2018?:language=de-DE&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

---

## Tech Stack & Workflow
* **Storage & Processing:** MySQL Server
* **Data Engineering (ETL):** Advanced SQL (DML/DDL, Complex Joins, Window Functions, Common Table Expressions)
* **Business Intelligence:** Tableau Public (Continuous/Discrete Field Architecture)

```
[Raw CDC NHANES Data] ──> [MySQL Importer] ──> [Staging Tables]
                                                      │
                                           (Rigorous Cleaning & Joins)
                                                      ▼
[Tableau Public Dashboard] <── [CSV Export] <── [v_clean_analysis_data (View)]
```

---

## Database Architecture & Engineering

The pipeline processes demographic and biometric datasets from the CDC National Health and Nutrition Examination Survey (NHANES). It implements a robust star-like query schema via a virtualized analytical view, abstracting structural noise from downstream analytics.

### Key Implementation Phases:
1. **Robust Data Cleansing:** Outliers (e.g., impossible BMI values of `0`) and non-target demographics (pediatric cohorts) are strictly isolated and omitted.
2. **Defensive Standardization:** Categorical encoded integers are decoded into meaningful business strings (`1` maps to `'Männlich'`) via optimized conditional structures (`CASE WHEN`).
3. **Advanced Analytics via Window Functions:** Utilizing statistical partitioning (`AVG(...) OVER (PARTITION BY ...)`) to construct peer-group rolling averages directly inside the data tier for zero-latency retrieval.
4. **Calculated Risk Scoring:** Implemented an enterprise-grade Common Table Expression (CTE) hierarchy that isolates high-risk patients based on multiple biometric flags (Socio-demographic metrics combined with elevated Total Cholesterol $\ge 240$ mg/dL).

---

## Repository Structure

* `NHANES_Data_Pipeline.sql` - Main technical production script containing DDL/DML, logical staging views, window functions, and analytics queries.
* `nhanes_clean_analysis.csv` - Transformed analytical payload exported for downstream data consumption.
* `README.md` - Technical project overview and architecture blueprint.

---

## Core Visualized Insights

* **Biometric Risk Dispersion (Scatter):** Correlating BMI against Total Cholesterol across different self-reported ethnic demographics.
* **Socio-Economic Health Trends (Grouped Bars):** Segmenting average body-mass indexing across marital statuses and biological sexes to isolate hidden public-health risk factors.
* **Longitudinal Biometric Trends (Line Chart):** Continuous tracking of the average BMI across distinct life epochs (ages 18 to 80).
