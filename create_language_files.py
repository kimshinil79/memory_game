#!/usr/bin/env python3
import re

# item_list.dart에서 모든 언어 데이터 추출
with open("lib/item_list_backup.dart", "r", encoding="utf-8") as f:
    content = f.read()

# 언어별 데이터 추출
languages = [
    'afrikaansItemList', 'swahiliItemList', 'bengaliItemList', 'indonesianItemList', 
    'khmerItemList', 'nepaliItemList', 'sinhalaItemList', 'thaiItemList', 
    'myanmarItemList', 'laoItemList', 'filipinoItemList', 'malayItemList', 
    'javaneseItemList', 'sundaneseItemList', 'tamilItemList', 'teluguItemList', 
    'malayalamItemList', 'gujaratiItemList', 'kannadaItemList', 'marathiItemList', 
    'punjabiItemList', 'swedishItemList', 'danishItemList', 'finnishItemList', 
    'norwegianItemList', 'bulgarianItemList', 'urduItemList', 'hindiItemList', 
    'amharicItemList', 'zuluItemList', 'korItemList', 'spaItemList', 
    'fraItemList', 'deuItemList', 'jpnItemList', 'chnItemList', 
    'greekItemList', 'romanianItemList', 'slovakItemList', 'ukrainianItemList', 
    'croatianItemList', 'slovenianItemList', 'persianItemList', 'hebrewItemList', 
    'mongolianItemList', 'albanianItemList', 'rusItemList', 'itaItemList', 
    'porItemList', 'araItemList', 'turItemList', 'vieItemList', 
    'dutItemList', 'serbianItemList', 'uzbekItemList', 'czeItemList', 
    'polItemList', 'hunItemList'
]

# 파일명 매핑
file_mapping = {
    'afrikaansItemList': 'afrikaans',
    'swahiliItemList': 'swahili',
    'bengaliItemList': 'bengali',
    'indonesianItemList': 'indonesian',
    'khmerItemList': 'khmer',
    'nepaliItemList': 'nepali',
    'sinhalaItemList': 'sinhala',
    'thaiItemList': 'thai',
    'myanmarItemList': 'myanmar',
    'laoItemList': 'lao',
    'filipinoItemList': 'filipino',
    'malayItemList': 'malay',
    'javaneseItemList': 'javanese',
    'sundaneseItemList': 'sundanese',
    'tamilItemList': 'tamil',
    'teluguItemList': 'telugu',
    'malayalamItemList': 'malayalam',
    'gujaratiItemList': 'gujarati',
    'kannadaItemList': 'kannada',
    'marathiItemList': 'marathi',
    'punjabiItemList': 'punjabi',
    'swedishItemList': 'swedish',
    'danishItemList': 'danish',
    'finnishItemList': 'finnish',
    'norwegianItemList': 'norwegian',
    'bulgarianItemList': 'bulgarian',
    'urduItemList': 'urdu',
    'hindiItemList': 'hindi',
    'amharicItemList': 'amharic',
    'zuluItemList': 'zulu',
    'korItemList': 'korean',
    'spaItemList': 'spanish',
    'fraItemList': 'french',
    'deuItemList': 'german',
    'jpnItemList': 'japanese',
    'chnItemList': 'chinese',
    'greekItemList': 'greek',
    'romanianItemList': 'romanian',
    'slovakItemList': 'slovak',
    'ukrainianItemList': 'ukrainian',
    'croatianItemList': 'croatian',
    'slovenianItemList': 'slovenian',
    'persianItemList': 'persian',
    'hebrewItemList': 'hebrew',
    'mongolianItemList': 'mongolian',
    'albanianItemList': 'albanian',
    'rusItemList': 'russian',
    'itaItemList': 'italian',
    'porItemList': 'portuguese',
    'araItemList': 'arabic',
    'turItemList': 'turkish',
    'vieItemList': 'vietnamese',
    'dutItemList': 'dutch',
    'serbianItemList': 'serbian',
    'uzbekItemList': 'uzbek',
    'czeItemList': 'czech',
    'polItemList': 'polish',
    'hunItemList': 'hungarian'
}

# 백업 파일 생성
with open("lib/item_list_backup.dart", "w", encoding="utf-8") as f:
    f.write(content)

for lang in languages:
    # 각 언어의 Map 데이터 추출
    pattern = rf"final Map<String, String> {lang} = \{{(.*?)\}};"
    match = re.search(pattern, content, re.DOTALL)
    
    if match:
        map_content = match.group(1)
        file_name = file_mapping[lang]
        
        # 파일 생성
        with open(f"lib/card_item_data/{file_name}.dart", "w", encoding="utf-8") as f:
            f.write(f"final Map<String, String> {lang} = {{\n")
            f.write(map_content)
            f.write("\n};")
        
        print(f"Created {file_name}.dart")
    else:
        print(f"Could not find {lang}")

print("All language files created!")
