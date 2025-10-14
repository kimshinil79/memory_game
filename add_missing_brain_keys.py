#!/usr/bin/env python3
import os
import re

# 15개 Brain Level 번역 키들 (기본값은 영어)
brain_keys_template = """  'rainbow_brain_level5': 'Rainbow Brain (Level 5)',
  'rainbow_brain_desc': 'Your brain is sparkling with colorful brilliance!',
  'rainbow_brain_fun': 'You\\'ve reached the cognitive equivalent of a double rainbow - absolutely dazzling!',
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
  'poop_brain_fun': 'Your brain right now is like a smartphone at 1% battery - desperately needs charging!',"""

def add_brain_keys_to_file(file_path):
    """파일에 15개 Brain Level 키들을 추가합니다."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 이미 rainbow_brain_level5가 있는지 확인
        if "'rainbow_brain_level5'" in content:
            print(f"✓ Skipping {os.path.basename(file_path)} - already has brain keys")
            return False
        
        # understand_level_means 다음에 rainbow_brain_level5를 추가
        pattern = r"('understand_level_means':\s*'[^']*',\s*\n)"
        
        if not re.search(pattern, content):
            print(f"✗ Could not find insertion point in {os.path.basename(file_path)}")
            return False
        
        replacement = r"\1" + brain_keys_template + "\n"
        new_content = re.sub(pattern, replacement, content)
        
        if new_content != content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"✓ Added brain keys to {os.path.basename(file_path)}")
            return True
        else:
            print(f"✗ No changes made to {os.path.basename(file_path)}")
            return False
            
    except Exception as e:
        print(f"✗ Error processing {os.path.basename(file_path)}: {e}")
        return False

def main():
    # 번역 파일 디렉토리
    translation_dir = "lib/translation"
    
    # 처리된 파일 카운터
    processed = 0
    skipped = 0
    failed = 0
    
    # 모든 .dart 파일 찾기
    dart_files = sorted([f for f in os.listdir(translation_dir) if f.endswith('.dart')])
    
    print(f"\n🚀 Starting to process {len(dart_files)} translation files...\n")
    
    for filename in dart_files:
        file_path = os.path.join(translation_dir, filename)
        result = add_brain_keys_to_file(file_path)
        
        if result is True:
            processed += 1
        elif result is False:
            skipped += 1
        else:
            failed += 1
    
    print(f"\n📊 Summary:")
    print(f"   ✓ Processed: {processed}")
    print(f"   ⊘ Skipped: {skipped}")
    print(f"   ✗ Failed: {failed}")
    print(f"   📁 Total: {len(dart_files)}\n")

if __name__ == "__main__":
    main()

