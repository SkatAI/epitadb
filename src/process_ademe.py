'''
modifies the ADEME csv dataset for use in the S10 worksheet
'''

import pandas as pd
import re

column_mapping = {
    'N°DPE': 'DPE Number',
    'Date réception DPE': 'DPE Reception Date',
    'Date établissement DPE': 'DPE Issue Date',
    'Date visite diagnostiqueur': 'Inspector Visit Date',
    'Modèle DPE': 'DPE Model',
    'N° DPE remplacé': 'Replaced DPE Number',
    'Date fin validité DPE': 'DPE Expiry Date',
    'Version DPE': 'DPE Version',
    'N° DPE immeuble associé': 'Associated Building DPE Number',
    'Méthode du DPE': 'DPE Method',
    'N° immatriculation copropriété': 'Condo Registration Number',
    'Invariant fiscal logement': 'Housing Tax ID',
    'Etiquette DPE': 'DPE Label',
    'Etiquette GES': 'GHG Label',
    'Conso kWhep/m²/an': 'Energy Use (kWhep/m2/year)',
    'Emission GES kgCO2/m²/an': 'GHG Emissions (kgCO2/m2/year)',
    'Année construction': 'Construction Year',
    'Catégorie ERP': 'ERP Category',
    'Période construction': 'Construction Period',
    'Secteur activité': 'Activity Sector',
    'Nombre occupant': 'Occupant Count',
    'Surface (SHON)': 'Gross Floor Area',
    'Surface utile': 'Usable Area',
    'Type énergie principale chauffage': 'Main Heating Energy Type',
    'Adresse brute': 'Raw Address',
    'Nom  commune (BAN)': 'City Name (BAN)',
    'Code INSEE (BAN)': 'INSEE Code (BAN)',
    'N° voie (BAN)': 'Street Number (BAN)',
    'Identifiant  BAN': 'BAN ID',
    'Adresse (BAN)': 'Address (BAN)',
    'Code postal (BAN)': 'Postal Code (BAN)',
    'Score BAN': 'BAN Score',
    'Nom  rue (BAN)': 'Street Name (BAN)',
    'Coordonnée cartographique X (BAN)': 'X Coordinate (BAN)',
    'Coordonnée cartographique Y (BAN)': 'Y Coordinate (BAN)',
    'Code postal (brut)': 'Postal Code (Raw)',
    'N° étage appartement': 'Apartment Floor',
    'Nom résidence': 'Residence Name',
    'Complément d\'adresse bâtiment': 'Building Address Details',
    'Cage d\'escalier': 'Stairwell',
    'Complément d\'adresse logement': 'Housing Address Details',
    'Statut géocodage': 'Geocoding Status',
    'Nom  commune (Brut)': 'City Name (Raw)',
    'N° département (BAN)': 'Department Number (BAN)',
    'N° région (BAN)': 'Region Number (BAN)',
    'Conso é finale énergie n°1': 'Final Energy Use 01',
    'Conso é primaire énergie n°1': 'Primary Energy Use 01',
    'Type énergie n°1': 'Energy Type 01',
    'Type usage énergie n°1': 'Energy Usage Type 01',
    'Frais annuel énergie n°1': 'Annual Energy Cost 01',
    'Année relève conso énergie n°1': 'Energy Reading Year 01',
    'Conso é finale énergie n°2': 'Final Energy Use 02',
    'Conso é primaire énergie n°2': 'Primary Energy Use 02',
    'Type énergie n°2': 'Energy Type 02',
    'Type usage énergie n°2': 'Energy Usage Type 02',
    'Frais annuel énergie n°2': 'Annual Energy Cost 02',
    'Année relève conso énergie n°2': 'Energy Reading Year 02',
    'Conso é finale énergie n°3': 'Final Energy Use 03',
    'Conso é primaire énergie n°3': 'Primary Energy Use 03',
    'Type énergie n°3': 'Energy Type 03',
    'Type usage énergie n°3': 'Energy Usage Type 03',
    'Frais annuel énergie n°3': 'Annual Energy Cost 03',
    'Année relève conso énergie n°3': 'Energy Reading Year 03'
}


def slugify(text):
    """Generate URL-friendly slug from text"""
    # Convert to lowercase and replace spaces with hyphens
    slug = text.lower()
    # Remove special characters
    slug = re.sub(r'[éèêë]', 'e', slug)
    slug = re.sub(r'[à,â]', 'a', slug)
    slug = re.sub(r'[^a-z0-9\s_]', '', slug)
    # # Replace spaces with hyphens
    # slug = re.sub(r'\s+', '-', slug)
    # Remove multiple consecutive hyphens
    slug = re.sub(r'-+', '-', slug)
    return slug.replace(' ', '_')


if __name__ == "__main__":

    filename = "./data/ADEME_dpe-v2-tertiaire-2.csv"
    data = pd.read_csv(filename)

    columns = [slugify(column_mapping[col.replace('_', ' ')]) for col in data.columns ]

    data.columns = columns

    drop_columns = ['replaced_dpe_number', 'associated_building_dpe_number',
                    'condo_registration_number', 'housing_tax_id',
                    'stairwell', 'dpe_model']

    drop_columns += ['raw_address','postal_code_raw', 'city_name_raw', 'raw_address', 'dpe_version']
    data.drop(columns = drop_columns, inplace = True)

    data = data.fillna({col: '' if data[col].dtype == 'object' else 0 for col in data.columns})

    int_columns = ['construction_year', 'occupant_count', 'postal_code_ban', 'apartment_floor', 'region_number_ban']

    for col in int_columns:
        data[col] = data[col].astype(int)

    data.to_csv('./data/ademe_english.csv', index = False)