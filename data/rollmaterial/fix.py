import re

with open('fahrzeuge.csv', 'r', encoding='utf-8') as f:
    text = f.read()

text = re.sub(r'\"\;([^\n]+)\n([^\n\"\t]+)\"', r';\1\n\2', text)
text = re.sub(r'\"\;([^\n]+)\n', r';\1\n', text)

with open('fahrzeuge.csv', 'w', encoding='utf-8') as f:
    f.write(text)

print('Fixed quotes')
