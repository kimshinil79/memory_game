#!/usr/bin/env python3

# item_list.dart에서 itemList만 남기고 언어 맵들 제거
with open("lib/item_list.dart", "r", encoding="utf-8") as f:
    content = f.read()

# itemList 배열의 끝을 찾기
lines = content.split('\n')
item_list_end = -1

for i, line in enumerate(lines):
    if line.strip() == '];':
        # 이전 줄들을 확인해서 itemList의 끝인지 확인
        for j in range(i-1, max(0, i-10), -1):
            if 'itemList' in lines[j]:
                item_list_end = i
                break
        if item_list_end != -1:
            break

if item_list_end != -1:
    # itemList만 남기고 나머지 제거
    new_content = '\n'.join(lines[:item_list_end + 1])
    
    with open("lib/item_list.dart", "w", encoding="utf-8") as f:
        f.write(new_content)
    
    print(f"Cleaned item_list.dart - kept {item_list_end + 1} lines")
else:
    print("Could not find itemList end")
