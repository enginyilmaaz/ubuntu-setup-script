#!/usr/bin/env bash
# Sync README.md + ubuntu-setup.sh into the public Gist that https://bit.ly/... resolves to.
# Uses the logged-in `gh` account (needs the `gist` scope).
#
#   ./publish.sh              # sanity-check, then update the gist
#   ./publish.sh --check-only # only syntax-check, touch no network
#   ./publish.sh --diff       # show what the gist currently differs by, change nothing
#
# The gist is the artefact users actually run, so it must never drift from the repo.
# The payload is sent through `jq --rawfile`, which keeps the files byte-exact UTF-8 —
# publishing by hand from PowerShell has mangled the README's emoji into "??" before.
set -euo pipefail
cd "$(dirname "$0")"

GIST_ID="deb328012eaa1d74e050724db74d2377"
DESC="Ubuntu Post-Installation Setup Script — curl -fsSL https://bit.ly/ubuntu-ey | bash"
FILES=(README.md ubuntu-setup.sh)

bash -n ubuntu-setup.sh && echo "ubuntu-setup.sh: syntax ok"
[ "${1:-}" = "--check-only" ] && exit 0

# The gist is the source users curl; refuse to overwrite a copy that is AHEAD of the
# repo (someone published a fix straight to the gist without committing it).
remote_newer=0
for f in "${FILES[@]}"; do
  # Normalise CRLF and the trailing newline the gist API appends, so only real
  # content differences are reported.
  gh api "/gists/$GIST_ID" --jq ".files[\"$f\"].content" 2>/dev/null | sed 's/\r$//' > "/tmp/.gist-$f.$$" || continue
  if ! diff -q <(sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba' "/tmp/.gist-$f.$$") \
                <(sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba' "$f") >/dev/null 2>&1; then
    echo "differs from the gist: $f"
    [ "${1:-}" = "--diff" ] && diff -u "$f" "/tmp/.gist-$f.$$" | head -60
    remote_newer=1
  fi
  rm -f "/tmp/.gist-$f.$$"
done
[ "${1:-}" = "--diff" ] && exit 0
[ "$remote_newer" = 0 ] && { echo "gist already matches the repo — nothing to do."; exit 0; }

echo
read -r -p "Overwrite the gist with the repo's copy? [y/N] " ans
case "$ans" in y|Y|yes|YES|Yes) ;; *) echo "aborted — the gist was not touched."; exit 1 ;; esac

jq -n --arg d "$DESC" --rawfile r README.md --rawfile s "ubuntu-setup.sh" \
   '{description:$d, files:{"README.md":{content:$r},"ubuntu-setup.sh":{content:$s}}}' \
  | gh api -X PATCH "/gists/$GIST_ID" --input - >/dev/null
echo "gist updated: https://gist.github.com/enginyilmaaz/$GIST_ID"
