import os

def check_brackets(filename):
    try:
        with open(filename, 'r') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading {filename}: {e}")
        return
    
    stack = []
    lines = content.split('\n')
    for line_num, line in enumerate(lines, 1):
        for char_num, char in enumerate(line, 1):
            if char == '(':
                stack.append(('(', line_num, char_num))
            elif char == ')':
                if not stack or stack[-1][0] != '(':
                    print(f"{filename} - Unmatched ')' at {line_num}:{char_num}")
                    # return # Don't return, keep checking
                else:
                    stack.pop()
            elif char == '[':
                stack.append(('[', line_num, char_num))
            elif char == ']':
                if not stack or stack[-1][0] != '[':
                    print(f"{filename} - Unmatched ']' at {line_num}:{char_num}")
                    # return
                else:
                    stack.pop()
            elif char == '{':
                stack.append(('{', line_num, char_num))
            elif char == '}':
                if not stack or stack[-1][0] != '{':
                    print(f"{filename} - Unmatched '}}' at {line_num}:{char_num}")
                    # return
                else:
                    stack.pop()
    
    if stack:
        for char, l, c in stack:
            print(f"{filename} - Unclosed '{char}' at {l}:{c}")

test_dir = 'test'
for root, dirs, files in os.walk(test_dir):
    for file in files:
        if file.endswith('.dart'):
            check_brackets(os.path.join(root, file))
