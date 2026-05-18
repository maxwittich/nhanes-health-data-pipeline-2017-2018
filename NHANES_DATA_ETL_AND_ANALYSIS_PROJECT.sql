/*
===============================================================================
NHANES DATA ETL & ANALYSIS PROJECT
Beschreibung: Bereinigung und Verknüpfung von Demografie-, Körpermaß- 
              und Labordaten (Cholesterin) für den Zyklus 2017-2018.
Autor: Max Wittich
===============================================================================
*/

-- 1. Datenbank-Setup
CREATE DATABASE nhanes_etl_project;

-- 2. Explorative Datenanalyse (Rohdaten-Check)
-- Überprüfung der importierten Tabellen auf Vollständigkeit
SELECT * FROM demo_l LIMIT 10;
SELECT * FROM bmx_l LIMIT 10;
SELECT * FROM tchol_l LIMIT 10;

-- 3. Data Transformation (Views erstellen)
-- Erstellung von Views, um kryptische NHANES-Kürzel in lesbare Namen zu übersetzen

-- View: Patienten Stammdaten (Demografie)
CREATE OR REPLACE VIEW v_patienten_stammdaten AS 
SELECT 
    SEQN AS patient_id,
    CASE 
        WHEN RIAGENDR = 1 THEN 'Männlich'
        WHEN RIAGENDR = 2 THEN 'Weiblich'
        ELSE 'Unbekannt'
    END AS geschlecht,
    RIDAGEYR AS alter_jahre,
    CASE 
        WHEN RIDRETH3 = 1 THEN 'Mexikanisch-Amerikanisch'
        WHEN RIDRETH3 = 2 THEN 'Andere Hispanics'
        WHEN RIDRETH3 = 3 THEN 'Nicht-Hispanic Weiß'
        WHEN RIDRETH3 = 4 THEN 'Nicht-Hispanic Schwarz'
        WHEN RIDRETH3 = 6 THEN 'Nicht-Hispanic Asiatisch'
        WHEN RIDRETH3 = 7 THEN 'Andere/Multirassisch'
        ELSE 'Unbekannt'
    END AS ethnische_gruppe,
CASE 
        WHEN DMDMARTZ = 1 THEN 'Verheiratet'
        WHEN DMDMARTZ = 2 THEN 'Witwe/r'
        WHEN DMDMARTZ = 3 THEN 'Geschieden'
        -- Die Kategorien 4,5 und 6 sind laut NHANES-Codebook möglich:
        WHEN DMDMARTZ = 4 THEN 'Getrennt lebend'
        WHEN DMDMARTZ = 5 THEN 'Nie verheiratet'
        WHEN DMDMARTZ = 6 THEN 'Zusammenlebend'
        ELSE 'Andere/Unbekannt' -- Filtert 77 (Refused) und 99 (Don't know)
    END AS familienstand
FROM demo_l;

-- View: Körpermasse (Examination)
CREATE OR REPLACE VIEW v_koerpermasse AS
SELECT
	SEQN AS patient_id,
    BMXWT AS gewicht_kg,
    BMXHT AS groesse_cm,
    BMXBMI AS bmi,
    BMXWAIST AS taillenumfang_cm
FROM bmx_l;

-- View: Cholesterinwerte (Laboratory)
CREATE OR REPLACE VIEW v_cholesterin AS
SELECT 
    SEQN AS patient_id,
    LBXTC AS gesamt_cholesterin
FROM tchol_l;

-- 4. Daten-Integration (Joins)
-- Zusammenführung der bereinigten Views für die Analyse
-- Filter: Nur Erwachsene (> 18 Jahre)
SELECT 
    p.patient_id,
    p.geschlecht,
    p.alter_jahre,
    k.bmi,
    c.gesamt_cholesterin
FROM v_patienten_stammdaten AS p
JOIN v_koerpermasse AS k ON p.patient_id = k.patient_id
JOIN v_cholesterin AS c ON p.patient_id = c.patient_id
WHERE p.alter_jahre > 18
LIMIT 100;

-- 5. Data Quality Check (Missing Values)
-- Identifikation von fehlenden Werten, um die Datenqualität zu bewerten
-- Hinweis: Ergebnis 0 bedeutet, dass der INNER JOIN bereits nur Datensätze mit vollständigen Werten in allen Tabellen beibehalten hat.
SELECT 
    COUNT(*) AS gesamtanzahl,
    SUM(CASE WHEN bmi IS NULL THEN 1 ELSE 0 END) AS bmi_fehlt,
    SUM(CASE WHEN gesamt_cholesterin IS NULL THEN 1 ELSE 0 END) AS chol_fehlt
FROM v_patienten_stammdaten AS p
JOIN v_koerpermasse AS k ON p.patient_id = k.patient_id
JOIN v_cholesterin AS c ON p.patient_id = c.patient_id;

-- 6. Final Data Cleaning (Creation of Analysis Base)
-- Erstellung einer bereinigten View als Basis für statistische Auswertungen
-- Ausschluss von NULL-Werten und Beschränkung auf Erwachsene
CREATE OR REPLACE VIEW v_clean_analysis_data AS
SELECT 
    p.patient_id,
    p.geschlecht,
    p.alter_jahre,
    p.ethnische_gruppe,
    p.familienstand,
    k.bmi,
    c.gesamt_cholesterin
FROM v_patienten_stammdaten AS p
JOIN v_koerpermasse AS k ON p.patient_id = k.patient_id
JOIN v_cholesterin AS c ON p.patient_id = c.patient_id
WHERE k.bmi IS NOT NULL 
	AND k.bmi != ''          -- Filtert leere Strings
	AND k.bmi > 0            -- Filtert 0-Werte
	AND c.gesamt_cholesterin IS NOT NULL
    AND c.gesamt_cholesterin > 0
	AND p.alter_jahre > 18;
    
-- 7. Outlier Detection (Optionaler Check)
-- Identifikation von Extremwerten, die die Analyse verzerren könnten
SELECT * FROM v_clean_analysis_data
ORDER BY gesamt_cholesterin DESC
LIMIT 10;

-- 8. Deskriptive Statistik: BMI nach Familienstand
-- Ziel: Untersuchung, ob es signifikante Unterschiede im BMI zwischen den Gruppen gibt
SELECT 
    familienstand,
    COUNT(*) AS anzahl_personen,
    ROUND(AVG(bmi), 2) AS durchschnitts_bmi,
    ROUND(MIN(bmi), 2) AS min_bmi,
    ROUND(MAX(bmi), 2) AS max_bmi
FROM v_clean_analysis_data
GROUP BY familienstand
ORDER BY durchschnitts_bmi DESC;

-- 9. Multivariate Analyse: BMI-Verteilung nach Geschlecht und Familienstand
-- Ziel: Herausfinden, ob bestimmte Lebensumstände Männer oder Frauen unterschiedlich beeinflussen
SELECT
	geschlecht,
    familienstand,
    COUNT(*) AS anzahl,
    ROUND(AVG(bmi), 2) AS avg_bmi
FROM v_clean_analysis_data
GROUP BY geschlecht, familienstand
ORDER BY geschlecht, avg_bmi DESC;

-- 10. Korrelations-Analyse: Cholesterinspiegel nach BMI-Kategorie
-- Ziel: Besteht ein Zusammenhang zwischen Übergewicht und hohem Cholesterin?
SELECT 
    CASE 
        WHEN bmi < 18.5 THEN 'Untergewicht'
        WHEN bmi >= 18.5 AND bmi < 25 THEN 'Normalgewicht'
        WHEN bmi >= 25 AND bmi < 30 THEN 'Übergewicht'
        ELSE 'Adipositas (30+)'
    END AS bmi_kategorie,
    COUNT(*) AS anzahl,
    ROUND(AVG(gesamt_cholesterin), 2) AS avg_cholesterin
FROM v_clean_analysis_data
GROUP BY bmi_kategorie
ORDER BY avg_cholesterin DESC;

-- 11. Altersgruppen-Analyse
-- Ziel: Den Gesundheitsverlauf über die Lebensspanne visualisieren
SELECT 
    FLOOR(alter_jahre / 10) * 10 AS altersgruppe,
    ROUND(AVG(bmi), 2) AS avg_bmi,
    COUNT(*) AS anzahl_pro_gruppe
FROM v_clean_analysis_data
GROUP BY altersgruppe
ORDER BY altersgruppe ASC;

-- 12. Window Functions: Individueller BMI vs. Gruppendurchschnitt
-- Ziel: Zeigen, wie weit ein Patient vom Durchschnitt seiner Gruppe abweicht
SELECT 
    patient_id,
    ethnische_gruppe,
    bmi,
    ROUND(AVG(bmi) OVER(PARTITION BY ethnische_gruppe), 2) AS gruppen_avg_bmi,
    ROUND(bmi - AVG(bmi) OVER(PARTITION BY ethnische_gruppe), 2) AS abweichung_vom_schnitt
FROM v_clean_analysis_data
LIMIT 100;

-- 13. Finale CTE: Identifikation von Risiko-Clustern
-- Ziel: Gruppen finden, die sowohl einen hohen BMI als auch hohes Cholesterin haben
WITH risiko_gruppen AS (
    SELECT 
        geschlecht,
        FLOOR(alter_jahre / 10) * 10 AS altersgruppe,
        ROUND(AVG(bmi), 2) AS avg_bmi,
        ROUND(AVG(gesamt_cholesterin), 2) AS avg_cholesterin,
        COUNT(*) AS anzahl_personen
    FROM v_clean_analysis_data
    GROUP BY geschlecht, altersgruppe
)
SELECT * FROM risiko_gruppen
WHERE avg_bmi > 27 AND avg_cholesterin > 190
ORDER BY avg_cholesterin DESC;
