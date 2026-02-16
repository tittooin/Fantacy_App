
files = [
    r'g:\Fantacy_App\lib\features\wallet\data\wallet_repository.dart',
    r'g:\Fantacy_App\lib\features\contest\presentation\match_detail_screen.dart',
    r'g:\Fantacy_App\lib\features\team\presentation\team_builder_screen.dart'
]

for f in files:
    try:
        content = open(f, 'r', encoding='utf-8').read()
        open_braces = content.count('{')
        close_braces = content.count('}')
        print(f"{f}: {open_braces} {{, {close_braces} }}")
    except Exception as e:
        print(f"Error reading {f}: {e}")
