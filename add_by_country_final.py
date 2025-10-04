#!/usr/bin/env python3
import os
import re

# Translation mappings for "by_country" in different languages
translations = {
    'en.dart': 'By Country',
    'south_korea.dart': '국가별',
    'japan.dart': '国別',
    'china.dart': '按国家',
    'germany.dart': 'Nach Land',
    'france.dart': 'Par Pays',
    'spain.dart': 'Por País',
    'italy.dart': 'Per Paese',
    'portugal.dart': 'Por País',
    'russia.dart': 'По Странам',
    'arabic.dart': 'حسب البلد',
    'hindi.dart': 'देश के अनुसार',
    'bengali.dart': 'দেশ অনুযায়ী',
    'thailand.dart': 'ตามประเทศ',
    'vietnam.dart': 'Theo Quốc Gia',
    'indonesia.dart': 'Berdasarkan Negara',
    'malaysia.dart': 'Mengikut Negara',
    'philippines.dart': 'Ayon sa Bansa',
    'turkish.dart': 'Ülkeye Göre',
    'polish.dart': 'Według Krajów',
    'czech.dart': 'Podle Zemí',
    'hungary.dart': 'Ország Szerint',
    'romania.dart': 'După Țară',
    'bulgaria.dart': 'По Държави',
    'croatia.dart': 'Po Zemljama',
    'serbia.dart': 'По Земљама',
    'slovenia.dart': 'Po Državah',
    'slovakia.dart': 'Podľa Krajín',
    'estonia.dart': 'Riigi Järgi',
    'latvia.dart': 'Pēc Valstīm',
    'lithuania.dart': 'Pagal Šalis',
    'finland.dart': 'Maan Mukaan',
    'sweden.dart': 'Efter Land',
    'norway.dart': 'Etter Land',
    'denmark.dart': 'Efter Land',
    'iceland.dart': 'Eftir Löndum',
    'netherlands.dart': 'Per Land',
    'dutch.dart': 'Per Land',
    'belgium.dart': 'Par Pays',
    'luxembourg.dart': 'Par Pays',
    'austria.dart': 'Nach Land',
    'switzerland.dart': 'Nach Land',
    'ukraine.dart': 'За Країнами',
    'belarus.dart': 'Па Краінах',
    'kazakhstan.dart': 'Ел Бойынша',
    'uzbekistan.dart': 'Davlat Bo\'yicha',
    'kyrgyzstan.dart': 'Өлкө Бойунча',
    'tajikistan.dart': 'Аз Рӯи Кишвар',
    'turkmenistan.dart': 'Döwlet Boýunça',
    'mongolia.dart': 'Улсаар',
    'afghanistan.dart': 'د هیوادونو له مخې',
    'pakistan.dart': 'ملک کے حساب سے',
    'bangladesh.dart': 'দেশ অনুযায়ী',
    'sri_lanka.dart': 'රට අනුව',
    'sri_lanka_ta.dart': 'நாடு வாரியாக',
    'nepal.dart': 'देश अनुसार',
    'bhutan.dart': 'རྒྱལ་ཁབ་ཀྱི་ཐོག་ནས།',
    'maldives.dart': 'ރާޖުގެ ގޮތުން',
    'iran.dart': 'بر اساس کشور',
    'iraq.dart': 'حسب البلد',
    'syria.dart': 'حسب البلد',
    'lebanon.dart': 'حسب البلد',
    'jordan.dart': 'حسب البلد',
    'israel.dart': 'לפי מדינה',
    'saudi_arabia.dart': 'حسب البلد',
    'united_arab_emirates.dart': 'حسب البلد',
    'qatar.dart': 'حسب البلد',
    'kuwait.dart': 'حسب البلد',
    'bahrain.dart': 'حسب البلد',
    'oman.dart': 'حسب البلد',
    'yemen.dart': 'حسب البلد',
    'egypt.dart': 'حسب البلد',
    'libya.dart': 'حسب البلد',
    'tunisia.dart': 'حسب البلد',
    'algeria.dart': 'حسب البلد',
    'morocco.dart': 'حسب البلد',
    'sudan.dart': 'حسب البلد',
    'south_sudan.dart': 'حسب البلد',
    'ethiopia.dart': 'በሀገር',
    'eritrea.dart': 'በሀገር',
    'djibouti.dart': 'حسب البلد',
    'somalia.dart': 'حسب البلد',
    'kenya.dart': 'Kwa Nchi',
    'uganda.dart': 'Kwa Nchi',
    'tanzania.dart': 'Kwa Nchi',
    'rwanda.dart': 'Kwa Nchi',
    'burundi.dart': 'Kwa Nchi',
    'democratic_republic_congo.dart': 'Par Pays',
    'congo.dart': 'Par Pays',
    'central_african_republic.dart': 'Par Pays',
    'chad.dart': 'Par Pays',
    'cameroon.dart': 'Par Pays',
    'gabon.dart': 'Par Pays',
    'equatorial_guinea.dart': 'Par Pays',
    'sao_tome_and_principe.dart': 'Por País',
    'angola.dart': 'Por País',
    'zambia.dart': 'Kwa Nchi',
    'zimbabwe.dart': 'Kwa Nchi',
    'botswana.dart': 'Kwa Nchi',
    'namibia.dart': 'Kwa Nchi',
    'south_africa.dart': 'Kwa Nchi',
    'lesotho.dart': 'Kwa Nchi',
    'swaziland.dart': 'Kwa Nchi',
    'madagascar.dart': 'Par Pays',
    'mauritius.dart': 'Par Pays',
    'seychelles.dart': 'Par Pays',
    'comoros.dart': 'Par Pays',
    'myanmar.dart': 'နိုင်ငံအလိုက်',
    'cambodia.dart': 'តាមប្រទេស',
    'laos.dart': 'ຕາມປະເທດ',
    'singapore.dart': 'By Country',
    'singapore_zh.dart': '按国家',
    'singapore_ta.dart': 'நாடு வாரியாக',
    'singapore_ms.dart': 'Mengikut Negara',
    'brunei.dart': 'Mengikut Negara',
    'east_timor.dart': 'Berdasarkan Negara',
    'papua_new_guinea.dart': 'Berdasarkan Negara',
    'fiji.dart': 'Berdasarkan Negara',
    'solomon_islands.dart': 'Berdasarkan Negara',
    'vanuatu.dart': 'Berdasarkan Negara',
    'samoa.dart': 'Berdasarkan Negara',
    'tonga.dart': 'Berdasarkan Negara',
    'kiribati.dart': 'Berdasarkan Negara',
    'tuvalu.dart': 'Berdasarkan Negara',
    'nauru.dart': 'Berdasarkan Negara',
    'marshall_islands.dart': 'Berdasarkan Negara',
    'micronesia.dart': 'Berdasarkan Negara',
    'palau.dart': 'Berdasarkan Negara',
    'australia.dart': 'By Country',
    'new_zealand.dart': 'By Country',
    'united_states.dart': 'By Country',
    'canada.dart': 'By Country',
    'mexico.dart': 'Por País',
    'guatemala.dart': 'Por País',
    'belize.dart': 'By Country',
    'el_salvador.dart': 'Por País',
    'honduras.dart': 'Por País',
    'nicaragua.dart': 'Por País',
    'costa_rica.dart': 'Por País',
    'panama.dart': 'Por País',
    'cuba.dart': 'Por País',
    'jamaica.dart': 'By Country',
    'haiti.dart': 'Par Pays',
    'dominican_republic.dart': 'Por País',
    'puerto_rico.dart': 'Por País',
    'trinidad.dart': 'By Country',
    'trinidad_and_tobago.dart': 'By Country',
    'barbados.dart': 'By Country',
    'saint_lucia.dart': 'By Country',
    'saint_vincent_and_the_grenadines.dart': 'By Country',
    'grenada.dart': 'By Country',
    'antigua_and_barbuda.dart': 'By Country',
    'saint_kitts_and_nevis.dart': 'By Country',
    'dominica.dart': 'By Country',
    'montserrat.dart': 'By Country',
    'argentina.dart': 'Por País',
    'chile.dart': 'Por País',
    'uruguay.dart': 'Por País',
    'paraguay.dart': 'Por País',
    'bolivia.dart': 'Por País',
    'peru.dart': 'Por País',
    'ecuador.dart': 'Por País',
    'colombia.dart': 'Por País',
    'venezuela.dart': 'Por País',
    'guyana.dart': 'By Country',
    'suriname.dart': 'Per Land',
    'brazil.dart': 'Por País',
    'french_guiana.dart': 'Par Pays',
    'basque.dart': 'Herrialdeka',
    'catalan.dart': 'Per País',
    'galician.dart': 'Por País',
    'corsican.dart': 'Per Paese',
    'esperanto.dart': 'Laŭ Lando',
    'greenland.dart': 'Efter Land',
    'faroese.dart': 'Eftir Løndum',
    'welsh.dart': 'Yn ôl Gwlad',
    'irish.dart': 'De réir Tíre',
    'scottish_gaelic.dart': 'A-rèir Dùthcha',
    'breton.dart': 'Diwar-benn Bro',
    'frisian.dart': 'Per Lân',
    'luxembourgish.dart': 'Par Pays',
    'afrikaans.dart': 'Per Land',
    'amharic.dart': 'በሀገር',
    'swahili.dart': 'Kwa Nchi',
    'yoruba.dart': 'Lati Ile',
    'igbo.dart': 'Site na Obodo',
    'hausa.dart': 'Ta Kasa',
    'zulu.dart': 'Ngezwe',
    'xhosa.dart': 'Ngezwe',
    'tamil.dart': 'நாடு வாரியாக',
    'telugu.dart': 'దేశం వారీగా',
    'malayalam.dart': 'രാജ്യം അനുസരിച്ച്',
    'kannada.dart': 'ದೇಶದ ಪ್ರಕಾರ',
    'gujarati.dart': 'દેશ મુજબ',
    'punjabi.dart': 'ਦੇਸ਼ ਅਨੁਸਾਰ',
    'marathi.dart': 'देशानुसार',
    'odia.dart': 'ଦେଶ ଅନୁସାରେ',
    'assamese.dart': 'দেশ অনুযায়ী',
    'sinhala.dart': 'රට අනුව',
    'divehi.dart': 'ރާޖުގެ ގޮތުން',
    'burmese.dart': 'နိုင်ငံအလိုက်',
    'khmer.dart': 'តាមប្រទេស',
    'lao.dart': 'ຕາມປະເທດ',
    'thai.dart': 'ตามประเทศ',
    'vietnamese.dart': 'Theo Quốc Gia',
    'filipino.dart': 'Ayon sa Bansa',
    'indonesian.dart': 'Berdasarkan Negara',
    'malay.dart': 'Mengikut Negara',
    'javanese.dart': 'Berdasarkan Negara',
    'sundanese.dart': 'Berdasarkan Negara',
    'madurese.dart': 'Berdasarkan Negara',
    'minangkabau.dart': 'Berdasarkan Negara',
    'buginese.dart': 'Berdasarkan Negara',
    'makassarese.dart': 'Berdasarkan Negara',
    'acehnese.dart': 'Berdasarkan Negara',
    'batak.dart': 'Berdasarkan Negara',
    'dayak.dart': 'Berdasarkan Negara',
    'balinese.dart': 'Berdasarkan Negara',
    'sasak.dart': 'Berdasarkan Negara',
    'rejang.dart': 'Berdasarkan Negara',
    'lampung.dart': 'Berdasarkan Negara',
    'komering.dart': 'Berdasarkan Negara',
    'palembang.dart': 'Berdasarkan Negara',
    'minahasa.dart': 'Berdasarkan Negara',
    'toraja.dart': 'Berdasarkan Negara',
    'mandailing.dart': 'Berdasarkan Negara',
    'nias.dart': 'Berdasarkan Negara',
    'mentawai.dart': 'Berdasarkan Negara',
    'enggano.dart': 'Berdasarkan Negara',
    'sikule.dart': 'Berdasarkan Negara',
    'nuaulu.dart': 'Berdasarkan Negara',
    'wemale.dart': 'Berdasarkan Negara',
    'yali.dart': 'Berdasarkan Negara',
    'dani.dart': 'Berdasarkan Negara',
    'asmat.dart': 'Berdasarkan Negara',
    'kayagar.dart': 'Berdasarkan Negara',
    'muyu.dart': 'Berdasarkan Negara',
    'marind.dart': 'Berdasarkan Negara',
    'yawa.dart': 'Berdasarkan Negara',
    'sawi.dart': 'Berdasarkan Negara',
    'awyu.dart': 'Berdasarkan Negara',
    'kombai.dart': 'Berdasarkan Negara',
    'korowai.dart': 'Berdasarkan Negara',
    'citak.dart': 'Berdasarkan Negara',
    'north_korea.dart': '국가별',
    'united_kingdom.dart': 'By Country',
    'hong_kong.dart': '按國家',
    'macau.dart': '按國家',
    'taiwan.dart': '按國家',
    'india.dart': 'देश के अनुसार',
    'albania.dart': 'Sipas Vendit',
    'andorra.dart': 'Per País',
    'armenia.dart': 'Երկրի Կարգով',
    'azerbaijan.dart': 'Ölkəyə Görə',
    'bosnia.dart': 'Po Zemljama',
    'cyprus.dart': 'Κατά Χώρα',
    'georgia.dart': 'ქვეყნის მიხედვით',
    'greece.dart': 'Κατά Χώρα',
    'liechtenstein.dart': 'Nach Land',
    'macedonia.dart': 'По Земји',
    'north_macedonia.dart': 'По Земји',
    'moldova.dart': 'După Țară',
    'monaco.dart': 'Par Pays',
    'montenegro.dart': 'Po Zemljama',
    'malta.dart': 'Per Pajjiż',
    'sierra_leone.dart': 'Kwa Nchi',
    'liberia.dart': 'Kwa Nchi',
    'guinea.dart': 'Par Pays',
    'gambia.dart': 'Kwa Nchi',
    'senegal.dart': 'Par Pays',
    'mauritania.dart': 'Par Pays',
    'mali.dart': 'Par Pays',
    'burkina_faso.dart': 'Par Pays',
    'niger.dart': 'Par Pays',
    'togo.dart': 'Par Pays',
    'benin.dart': 'Par Pays',
    'cape_verde.dart': 'Por País',
    'guinea_bissau.dart': 'Por País',
    'equatorial_guinea.dart': 'Par Pays',
    'sao_tome_and_principe.dart': 'Por País',
    'mozambique.dart': 'Por País',
    'malawi.dart': 'Kwa Nchi',
    'zambia.dart': 'Kwa Nchi',
    'zimbabwe.dart': 'Kwa Nchi',
    'botswana.dart': 'Kwa Nchi',
    'namibia.dart': 'Kwa Nchi',
    'south_africa.dart': 'Kwa Nchi',
    'lesotho.dart': 'Kwa Nchi',
    'swaziland.dart': 'Kwa Nchi',
    'madagascar.dart': 'Par Pays',
    'mauritius.dart': 'Par Pays',
    'seychelles.dart': 'Par Pays',
    'comoros.dart': 'Par Pays',
    'mayotte.dart': 'Par Pays',
    'reunion.dart': 'Par Pays',
    'saint_helena.dart': 'By Country',
    'ascension.dart': 'By Country',
    'tristan_da_cunha.dart': 'By Country',
    'british_indian_ocean_territory.dart': 'By Country',
    'french_southern_territories.dart': 'Par Pays',
    'heard_island.dart': 'By Country',
    'mcdonald_islands.dart': 'By Country',
    'bouvet_island.dart': 'Etter Land',
    'south_georgia.dart': 'By Country',
    'south_sandwich_islands.dart': 'By Country',
    'falkland_islands.dart': 'By Country',
    'south_georgia_and_south_sandwich_islands.dart': 'By Country',
    'british_antarctic_territory.dart': 'By Country',
    'australian_antarctic_territory.dart': 'By Country',
    'ross_dependency.dart': 'By Country',
    'peter_i_island.dart': 'Etter Land',
    'queen_maud_land.dart': 'Etter Land',
    'adelie_land.dart': 'Par Pays',
    'east_antarctica.dart': 'By Country',
    'west_antarctica.dart': 'By Country',
    'antarctica.dart': 'By Country',
    'antarctic_peninsula.dart': 'By Country',
    'transantarctic_mountains.dart': 'By Country',
    'east_antarctic_ice_sheet.dart': 'By Country',
    'west_antarctic_ice_sheet.dart': 'By Country',
    'antarctic_circle.dart': 'By Country',
    'south_pole.dart': 'By Country',
    'north_pole.dart': 'By Country',
    'arctic_circle.dart': 'By Country',
    'arctic_ocean.dart': 'By Country',
    'southern_ocean.dart': 'By Country',
    'atlantic_ocean.dart': 'By Country',
    'pacific_ocean.dart': 'By Country',
    'indian_ocean.dart': 'By Country',
    'arctic.dart': 'By Country',
    'antarctic.dart': 'By Country',
    'polar.dart': 'By Country',
    'tropical.dart': 'By Country',
    'subtropical.dart': 'By Country',
    'temperate.dart': 'By Country',
    'continental.dart': 'By Country',
    'maritime.dart': 'By Country',
    'mediterranean.dart': 'By Country',
    'desert.dart': 'By Country',
    'semi_arid.dart': 'By Country',
    'arid.dart': 'By Country',
    'humid.dart': 'By Country',
    'subhumid.dart': 'By Country',
    'perhumid.dart': 'By Country',
    'hyperhumid.dart': 'By Country',
    'ultra_arid.dart': 'By Country',
    'extremely_arid.dart': 'By Country',
    'very_arid.dart': 'By Country',
    'moderately_arid.dart': 'By Country',
    'slightly_arid.dart': 'By Country',
    'near_arid.dart': 'By Country',
    'sub_arid.dart': 'By Country',
    'semi_arid.dart': 'By Country',
    'dry_subhumid.dart': 'By Country',
    'moist_subhumid.dart': 'By Country',
    'dry_subhumid.dart': 'By Country',
    'moist_subhumid.dart': 'By Country',
    'humid.dart': 'By Country',
    'perhumid.dart': 'By Country',
    'hyperhumid.dart': 'By Country',
    'ultra_humid.dart': 'By Country',
    'extremely_humid.dart': 'By Country',
    'very_humid.dart': 'By Country',
    'moderately_humid.dart': 'By Country',
    'slightly_humid.dart': 'By Country',
    'near_humid.dart': 'By Country',
    'sub_humid.dart': 'By Country',
    'semi_humid.dart': 'By Country',
    'dry_subhumid.dart': 'By Country',
    'moist_subhumid.dart': 'By Country',
    'dry_subhumid.dart': 'By Country',
    'moist_subhumid.dart': 'By Country',
    'humid.dart': 'By Country',
    'perhumid.dart': 'By Country',
    'hyperhumid.dart': 'By Country',
    'ultra_humid.dart': 'By Country',
    'extremely_humid.dart': 'By Country',
    'very_humid.dart': 'By Country',
    'moderately_humid.dart': 'By Country',
    'slightly_humid.dart': 'By Country',
    'near_humid.dart': 'By Country',
    'sub_humid.dart': 'By Country',
    'semi_humid.dart': 'By Country',
}

def add_by_country_translation(file_path):
    """Add by_country translation to a translation file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Check if by_country already exists
        if "'by_country':" in content or '"by_country":' in content:
            print(f"by_country already exists in {file_path}")
            return
        
        # Get the filename to determine the translation
        filename = os.path.basename(file_path)
        translation = translations.get(filename, 'By Country')  # Default to English
        
        # Try multiple patterns to find the right place to insert
        patterns = [
            # Pattern 1: 'key': 'value',\n};
            r"(\s+)'([^']+)':\s*'([^']+)',\s*\n(\s+)\};",
            # Pattern 2: 'key': 'value',\n\n};
            r"(\s+)'([^']+)':\s*'([^']+)',\s*\n\s*\n(\s+)\};",
            # Pattern 3: 'key': 'value',\n  'another_key': 'value',\n};
            r"(\s+)'([^']+)':\s*'([^']+)',\s*\n(\s+)'([^']+)':\s*'([^']+)',\s*\n(\s+)\};",
            # Pattern 4: Just before the closing };
            r"(\s+)\};",
        ]
        
        for i, pattern in enumerate(patterns):
            if i == 0:  # Pattern 1
                match = re.search(pattern, content, re.MULTILINE | re.DOTALL)
                if match:
                    indent = match.group(1)
                    last_key = match.group(2)
                    last_value = match.group(3)
                    closing_indent = match.group(4)
                    
                    # Add by_country entry before the last entry
                    new_entry = f"{indent}'by_country': '{translation}',\n{indent}'{last_key}': '{last_value}',\n{closing_indent}}};"
                    new_content = re.sub(pattern, new_entry, content, flags=re.MULTILINE | re.DOTALL)
                    
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Added by_country to {file_path} (pattern 1)")
                    return
                    
            elif i == 1:  # Pattern 2
                match = re.search(pattern, content, re.MULTILINE | re.DOTALL)
                if match:
                    indent = match.group(1)
                    last_key = match.group(2)
                    last_value = match.group(3)
                    closing_indent = match.group(4)
                    
                    # Add by_country entry before the last entry
                    new_entry = f"{indent}'by_country': '{translation}',\n{indent}'{last_key}': '{last_value}',\n\n{closing_indent}}};"
                    new_content = re.sub(pattern, new_entry, content, flags=re.MULTILINE | re.DOTALL)
                    
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Added by_country to {file_path} (pattern 2)")
                    return
                    
            elif i == 2:  # Pattern 3
                match = re.search(pattern, content, re.MULTILINE | re.DOTALL)
                if match:
                    indent = match.group(1)
                    last_key = match.group(2)
                    last_value = match.group(3)
                    middle_indent = match.group(4)
                    middle_key = match.group(5)
                    middle_value = match.group(6)
                    closing_indent = match.group(7)
                    
                    # Add by_country entry before the last entry
                    new_entry = f"{indent}'by_country': '{translation}',\n{indent}'{last_key}': '{last_value}',\n{middle_indent}'{middle_key}': '{middle_value}',\n{closing_indent}}};"
                    new_content = re.sub(pattern, new_entry, content, flags=re.MULTILINE | re.DOTALL)
                    
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Added by_country to {file_path} (pattern 3)")
                    return
                    
            elif i == 3:  # Pattern 4 - just before closing };
                match = re.search(pattern, content, re.MULTILINE)
                if match:
                    indent = match.group(1)
                    
                    # Add by_country entry before the closing };
                    new_entry = f"{indent}'by_country': '{translation}',\n{indent}}};"
                    new_content = re.sub(pattern, new_entry, content, flags=re.MULTILINE)
                    
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Added by_country to {file_path} (pattern 4)")
                    return
        
        print(f"Could not find suitable pattern in {file_path}")
        
    except Exception as e:
        print(f"Error processing {file_path}: {e}")

def main():
    translation_dir = "/Users/shinilkim/flutterProjects/memory_game/lib/translation"
    
    if not os.path.exists(translation_dir):
        print(f"Translation directory not found: {translation_dir}")
        return
    
    # Get list of files that don't have by_country yet
    files_without_by_country = []
    for filename in os.listdir(translation_dir):
        if filename.endswith('.dart'):
            file_path = os.path.join(translation_dir, filename)
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                if "'by_country':" not in content and '"by_country":' not in content:
                    files_without_by_country.append(file_path)
            except:
                pass
    
    print(f"Found {len(files_without_by_country)} files without by_country")
    
    # Process files that don't have by_country
    for file_path in files_without_by_country:
        add_by_country_translation(file_path)

if __name__ == "__main__":
    main()
