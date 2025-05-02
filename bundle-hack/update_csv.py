import yaml
import os

yaml = YAML()

def load_manifest(pathn):
   if not pathn.endswith(".yaml"):
      return None
   try:
      with open(pathn, "r") as f:
         return yaml.load(f)
   except FileNotFoundError:
      print("File can not found")
      exit(2)

def read_pullspec(file):
    with open(file, "w") as f:
        line = f.readline(f)

    return line

MUST_GATHER = read_pullspec("bundle-hack/must-gather.yaml")
HUB_OPERATOR = read_pullspec("bundle-hack/hub-operator.yaml")
OPERATOR = read_pullspec("bundle-hack/operator.yaml")
SIGNING = read_pullspec("bundle-hack/signing.yaml")
WEBHOOK = read_pullspec("bundle-hack/webhook.yaml")
WORKER = read_pullspec("bundle-hack/worker.yaml")



parser = argparse.ArgumentParser()
parser.add_argument('--path', default="kernel-module-management/bundle", help='path to the manifest/ directory')
parser.add_argument('--csv', default="kernel-module-management.clusterserviceversion.yaml", help='csv file name (without path)')

opt = parser.parse_args()

CSV_FILE=f"{opt.path}/manifest/{opt.csv}"

operator = load_manifest(CSV_FILE)



