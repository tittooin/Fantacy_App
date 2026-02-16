
import os

search_term = "features/contest/domain/contest_model.dart"
exclude_dirs = {'.git', '.dart_tool', 'build'}

for root, dirs, files in os.walk('.'):
    dirs[:] = [d for d in dirs if d not in exclude_dirs]
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            try:
                with open(path, 'r', encoding='utf-8') as f:
                    if search_term in f.read():
                        print(f"FOUND in {path}")
            except:
                pass
