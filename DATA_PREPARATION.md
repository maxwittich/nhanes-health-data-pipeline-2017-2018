**Automatisierte ETL-Pipeline für NHANES-Gesundheitsdaten: Von SAS (.xpt) zu SQL**


**Problem:**

NHANES-Rohdaten werden im spezialisierten SAS-Transportformat (.xpt) bereitgestellt, das nicht direkt von relationalen Datenbanken (SQL) gelesen werden kann.


**Lösung:** 

Extraktion: Download der Rohdaten von der CDC-Website.

Transformation: Ich habe ein Python-Skript entwickelt, das die Bibliotheken Pandas und pyreadstat nutzt, um mehrere .xpt-Dateien automatisiert in bereinigte .csv-Dateien umzuwandeln.

Laden: Anschließend wurden die CSV-Dateien in eine nhanes_etl_project Datenbank importiert, um sie für medizinische Analysen verfügbar zu machen.



**Code:** 

<details>
  <summary><b>Python Code (ETL-Prozess) anzeigen</b></summary> 

  ```python
  import pandas as pd
  import os

  # Verzeichnis nach .xpt Dateien durchsuchen
  files = [f for f in os.listdir('.') if f.lower().endswith('.xpt')]

  if not files:
      print("Keine .xpt Dateien gefunden!")
  else:
      for file in files:
          print(f"Konvertiere: {file}...")
          # Einlesen der SAS-Transportdatei
          df = pd.read_sas(file)
          
          # Zielname generieren (z.B. DEMO_L.csv)
          csv_name = file.rsplit('.', 1)[0] + '.csv'
          
          # Speichern als CSV ohne Index-Spalte
          df.to_csv(csv_name, index=False)
          print(f"Erfolgreich erstellt: {csv_name}")

  print("\n--- Alle Dateien verarbeitet ---")

