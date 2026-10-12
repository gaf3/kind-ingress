"""Split `helm template --include-crds` output on stdin into crds.yaml and traefik.yaml under kubernetes/base."""
import sys

crds, rest = [], []
for doc in sys.stdin.read().split("\n---\n"):
    doc = doc.strip("\n")
    if not doc.strip() or all(l.startswith("#") or not l.strip() for l in doc.splitlines()):
        continue
    (crds if "\nkind: CustomResourceDefinition" in "\n" + doc else rest).append(doc)

def write(path, docs):
    with open(path, "w") as out:
        out.write("\n---\n".join(docs) + "\n")

write("kubernetes/base/crds.yaml", crds)
write("kubernetes/base/traefik.yaml", rest)
print(f"{len(crds)} crds, {len(rest)} other")
