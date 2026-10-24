#!/usr/bin/env python3
import re
import subprocess
import json

version_file = "VERSION.json"
version_id = ""
version_godot_id = ""

def replace_text(filename, old_pattern, new_pattern):
    with open(filename, 'r', encoding='utf-8') as file:
        content = file.read()
    
    updated_content = re.sub(old_pattern, new_pattern, content)
    print(updated_content)
    
    with open(filename, 'w', encoding='utf-8') as file:
        file.write(updated_content)


with open(version_file, 'r') as f:
    data = json.load(f)
    version_id = data["plugin-version"]
    version_godot_id = data["godot-version"]

#with open(version_file, 'r', encoding='utf-8') as file:
#    version_id = file.read()

replace_text("godot/addons/cyclops_level_builder/plugin.cfg", r"(version\s*=\s*).*", "\\1\"" + version_id + "\"")

replace_text(".github/workflows/build_addon.yml", r"(\s*PLUGIN_VERSION\s*:).*", "\\1 " + version_id)
replace_text(".github/workflows/build_addon.yml", r"(\s*GODOT_VERSION\s*:).*", "\\1 " + version_godot_id)

#print(r"(\s*PLUGIN_VERSION\s*:\s*).*")
#print(version_id)

# subprocess.run(["git", "add", "-A"])
# subprocess.run(["git", "commit", "-m", "Updating version to " + version_id])
# subprocess.run(["git", "tag", "v" + version_id])

input("Press Enter to continue...")
