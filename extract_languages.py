#!/usr/bin/env python3
import re

# item_list.dart 파일 읽기
with open("lib/item_list.dart", "r", encoding="utf-8") as f:
    content = f.read()

# 언어별 파일명 매핑
languages = {
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

for lang_var, file_name in languages.items():
    # 각 언어의 Map 데이터 추출 (더 정확한 패턴)
    pattern = rf"final Map<String, String> {lang_var} = \{{(.*?)\n\}};"
    match = re.search(pattern, content, re.DOTALL)
    
    if match:
        map_content = match.group(1)
        
        # 파일 생성
        with open(f"lib/card_item_data/{file_name}.dart", "w", encoding="utf-8") as f:
            f.write(f"final Map<String, String> {lang_var} = {{\n")
            f.write(map_content)
            f.write("\n};")
        
        print(f"Created {file_name}.dart")
    else:
        print(f"Could not find {lang_var}")

print("All language files created!")
