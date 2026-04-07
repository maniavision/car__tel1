import sys

def check_brackets(filename):
    with open(filename, 'r') as f:
        content = f.read()
    
    stack = []
    lines = content.split('\n')
    for line_num, line in enumerate(lines, 1):
        for char_num, char in enumerate(line, 1):
            if char == '(':
                stack.append(('(', line_num, char_num))
            elif char == ')':
                if not stack or stack[-1][0] != '(':
                    print(f"Unmatched ')' at {line_num}:{char_num}")
                    return
                stack.pop()
            elif char == '[':
                stack.append(('[', line_num, char_num))
            elif char == ']':
                if not stack or stack[-1][0] != '[':
                    print(f"Unmatched ']' at {line_num}:{char_num}")
                    return
                stack.pop()
            elif char == '{':
                stack.append(('{', line_num, char_num))
            elif char == '}':
                if not stack or stack[-1][0] != '{':
                    print(f"Unmatched '}}' at {line_num}:{char_num}")
                    return
                stack.pop()
    
    if stack:
        for char, l, c in stack:
            print(f"Unclosed '{char}' at {l}:{c}")

check_brackets('/Users/fortuneniama/Documents/Projects/car__tel/car/lib/pages/trending_cars_page.dart')
