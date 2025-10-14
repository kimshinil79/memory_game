#!/usr/bin/env python3
import os
import re

# Brain Level Guide 번역 키들
brain_translations = {
    'brain_level_guide': 'Brain Level Guide',
    'understand_level_means': 'Understand what each level means',
    'rainbow_brain_level5': 'Rainbow Brain (Level 5)',
    'rainbow_brain_desc': 'Your brain is sparkling with colorful brilliance!',
    'rainbow_brain_fun': 'You\'ve reached the cognitive equivalent of a double rainbow - absolutely dazzling!',
    'gold_brain_level4': 'Gold Brain (Level 4)',
    'gold_brain_desc': 'Excellent cognitive function and memory.',
    'gold_brain_fun': 'Almost superhuman memory - you probably remember where you left your keys!',
    'silver_brain_level3': 'Silver Brain (Level 3)',
    'silver_brain_desc': 'Good brain health with room for improvement.',
    'silver_brain_fun': 'Your brain is warming up - like a computer booting up in the morning.',
    'bronze_brain_level2': 'Bronze Brain (Level 2)',
    'bronze_brain_desc': 'Average cognitive function - more games needed!',
    'bronze_brain_fun': 'Your brain is a bit sleepy - time for some mental coffee!',
    'poop_brain_level1': 'Poop Brain (Level 1)',
    'poop_brain_desc': 'Just starting your brain health journey.',
    'poop_brain_fun': 'Your brain right now is like a smartphone at 1% battery - desperately needs charging!',
    'keep_playing_memory_games': 'Keep playing memory games to increase your brain level!'
}

def add_brain_translations_to_file(file_path):
    """파일에 Brain Level Guide 번역을 추가합니다."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 이미 brain_level_guide가 있는지 확인
        if "'brain_level_guide'" in content:
            print(f"Skipping {file_path} - already has brain translations")
            return
        
        # 파일 끝에서 }; 전에 번역을 추가
        # by_country 다음에 추가하는 것이 안전
        pattern = r"('by_country': '[^']*',\s*\n)(\s*\};)"
        replacement = r"\1\n  // Brain Level Guide\n"
        
        for key, value in brain_translations.items():
            # 특수문자 이스케이프 처리
            escaped_value = value.replace("'", "\\'")
            replacement += f"  '{key}': '{escaped_value}',\n"
        
        replacement += r"\2"
        
        new_content = re.sub(pattern, replacement, content)
        
        if new_content != content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Added brain translations to {file_path}")
        else:
            print(f"Could not find insertion point in {file_path}")
            
    except Exception as e:
        print(f"Error processing {file_path}: {e}")

def main():
    # 번역 파일 디렉토리
    translation_dir = "lib/translation"
    
    # 모든 .dart 파일 찾기
    for filename in os.listdir(translation_dir):
        if filename.endswith('.dart'):
            file_path = os.path.join(translation_dir, filename)
            add_brain_translations_to_file(file_path)

if __name__ == "__main__":
    main()
