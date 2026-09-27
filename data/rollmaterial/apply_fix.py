import sys

# Correct lines
l60 = "L60\tII\tDRG\t(VT 137 VS 145)\tVT 137 251 + VS 145 173\t\t\tHT\t2680\t-"
l151 = "L151\tIV\tDR\tSVT175\t175 011-6 175 411-8 175 311-0 175 5...-. 175 012-4\tBerlin\tKarlshorst\tKa\t10745-1\t-"
l152 = "L152\tIV\tDR\tSVT175\t175 009-0 175 010-8 175 309-4 175 409-2\tBerlin\tKarlshorst\tKa\t73712\t-"
l8x = [
"L81\tII\tDRG\t(C4esT-29 BC4esS-29)\tC4esT-29 + BC4esS-29\t\t\tRR\t5525001\tx",
"L82\tII\tDRG\t(C4esT-29 BC4esS-29)\tC4esT-29 + BC4esS-29\t\t\tRR\t5525001\tx",
"L83\tII\tDRG\t(C4esT-29 BC4es-29)\tC4esT-29 + BC4es-29\t\t\tAr\t0189\t-",
"L84\tII\tDRG\t(C4esT-29 BC4es-29)\tC4esT-29 + BC4es-29\t\t\tAr\t0189\t-",
"L85\tII\tDRG\t(BC4 ET C4 ET)\tC4esT-29 + BC4es-29\t\t\tRR\tRR 5525001 + Ar 0189\t-",
"L86\tII\tDRG\t(C4esT-29 BC4esS-29)\tC4esT-29 + BC4esS-29\t\t\tRR\t5525001\t-",
"L87\tII\tDRG\t(C4esT-29 BC4esS-29)\tC4esT-29 + BC4esS-29\t\t\tRR\t5525001\t-",
"L88\tII\tDRG\t(C4esT-29 BC4esS-29)\tC4esT-29 + BC4esS-29\t\t\tRR\t5525001\t-"
]
g275 = "G275\tI\tKPEV\tMagdeburg/ Stettin\t101 105/45 051\t\t\tFl\t8814\t-"

lines = open('fahrzeuge.csv', 'r', encoding='utf-8').read().split('\n')
if lines[-1] == '':
    lines.pop()

new_lines = []
skip = 0
for i, line in enumerate(lines):
    if skip > 0:
        skip -= 1
        continue
    
    if line.startswith('L174\t') and lines[i+1].startswith('156,88\tL60'):
        new_lines.append(l60)
        skip = 1
        continue
        
    if line.startswith('L151\t'):
        new_lines.append(l151)
        # Check if next line is garbage
        if lines[i+1].startswith('5teilig'):
            skip = 1
        continue
        
    if line.startswith('L152\t'):
        new_lines.append(l152)
        if lines[i+1].startswith('4teilg'):
            skip = 1
        continue
        
    if line.startswith('L175\t') and lines[i+1].startswith('L81\t'):
        # L81 to L88 block is 15 lines (L175 up to 93\tL88...)
        new_lines.extend(l8x)
        skip = 14
        continue
        
    if line.startswith('G275\t') and lines[i+1].startswith('8814\t101'):
        new_lines.append(g275)
        skip = 1
        continue
        
    new_lines.append(line)

with open('fahrzeuge.csv', 'w', encoding='utf-8', newline='\n') as f:
    f.write('\n'.join(new_lines) + '\n')

print('Replaced broken lines!')
