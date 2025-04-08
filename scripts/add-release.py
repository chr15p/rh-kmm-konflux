import json
from copy import deepcopy

newver="2.4.0"
release="4.14"
package="kernel-module-management"
TEMPLATE=f"v{release}/catalog-template.json"
OUTPUT=f"v{release}/catalog-template.json.new"

with open(TEMPLATE) as json_data:
    schema=json.load(json_data)

for k in schema["entries"]:
    if k.get('name') == 'stable':
        prev = k['entries'][-1]
        prevver = prev['name'].split('v')[1]
        
        newentry = {"name": f"{package}.v{newver}",
                    "replaces": prev['name'],
                    "skipRange": f"\u003e=0.0.0 \u003c{prevver}"}

        print(newentry)

        k['entries'].append(newentry) 


        newchannel=deepcopy(k) 
        newchannel['name'] = f"{package}.v{newver}"
    
        schema["entries"].append(newchannel) 
        print(schema)
        with open(OUTPUT,"w") as json_data:
            json.dump(schema, json_data, indent = 4)
        exit(0) 
