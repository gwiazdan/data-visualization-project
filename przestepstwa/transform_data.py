import pandas as pd
import numpy as np
import re

# Wczytaj dane
df = pd.read_csv('przestepstwa.csv', sep=';')

print("Oryginalna forma:")
print(f"Wymiary: {df.shape}")
print(f"Kolumny: {df.columns[:5]}...")

# ID zmienne
id_vars = ['Kod', 'Nazwa']
data_vars = [col for col in df.columns if col not in id_vars]

# Melt - zmiana na format długi
melted = pd.melt(df, 
                  id_vars=id_vars,
                  value_vars=data_vars,
                  var_name='MetricInfo',
                  value_name='Value')

# Wyciągnij rok i kategorię z nazwy kolumny
# Format: "kategoria;rok;[jednostka]"
melted[['Kategoria', 'Rok', 'Jednostka']] = melted['MetricInfo'].str.split(';', expand=True, n=2)

# Wyczyść roku z nawisów
melted['Rok'] = melted['Rok'].str.strip('[]')
melted['Rok'] = pd.to_numeric(melted['Rok'], errors='coerce').astype('Int64')
melted['Jednostka'] = melted['Jednostka'].str.strip('[]')

# Konwertuj Value na float
melted['Value'] = pd.to_numeric(melted['Value'], errors='coerce')

# Usuń wiersze gdzie brak roku lub value
melted = melted.dropna(subset=['Rok', 'Value'])

# Sortuj
melted = melted.sort_values(['Kod', 'Rok', 'Kategoria']).reset_index(drop=True)

# Wybierz ostateczne kolumny
result = melted[['Kod', 'Nazwa', 'Rok', 'Kategoria', 'Jednostka', 'Value']]

print(f"\nPo transformacji:")
print(f"Wymiary: {result.shape}")
print(f"\nPierwsze wiersze:")
print(result.head(10))

# Zapisz
result.to_csv('przestepstwa_long.csv', index=False, sep=';')
print(f"\nZapisane do: przestepstwa_long.csv")
