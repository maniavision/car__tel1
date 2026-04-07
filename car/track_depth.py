def track_depth(filename):
    with open(filename, 'r') as f:
        content = f.read()
    
    depth = 0
    lines = content.split('\n')
    for i, line in enumerate(lines, 1):
        old_depth = depth
        for char in line:
            if char in '([{':
                depth += 1
            elif char in ')]}':
                depth -= 1
        print(f"{i:3}: {old_depth:2} -> {depth:2} | {line}")

track_depth('/Users/fortuneniama/Documents/Projects/car__tel/car/lib/pages/trending_cars_page.dart')
