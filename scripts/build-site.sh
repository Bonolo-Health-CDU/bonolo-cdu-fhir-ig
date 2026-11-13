#!/usr/bin/env bash
# Builds the browsable HTML guide into site/. Open site/index.html.
# Requires SUSHI, Java 17+, Jekyll (Ruby 3+) and internet access (the publisher fetches
# its page template and checks codes against tx.fhir.org).
# The publisher jar (~200 MB) is downloaded once into input-cache/.
set -euo pipefail
cd "$(dirname "$0")/.."
jar=input-cache/publisher.jar
if [ ! -f "$jar" ]; then
  mkdir -p input-cache
  # Resumes a partial download: slow links often drop part-way.
  for attempt in 1 2 3 4 5; do
    curl -fL --http1.1 -C - --retry 3 -o "$jar.part" \
      https://github.com/HL7/fhir-ig-publisher/releases/latest/download/publisher.jar && break
    echo "Download interrupted; resuming (attempt $attempt of 5)..."
  done
  unzip -tq "$jar.part" >/dev/null   # refuse a truncated jar
  mv "$jar.part" "$jar"
fi
# The publisher assembles the final HTML with Jekyll. On a Mac, Apple's
# Ruby is too old, so look for Homebrew's Ruby and its gems as well.
if ! command -v jekyll >/dev/null; then
  for ruby_bin in /opt/homebrew/opt/ruby/bin /usr/local/opt/ruby/bin; do
    if [ -x "$ruby_bin/gem" ]; then
      PATH="$ruby_bin:$("$ruby_bin/gem" environment gemdir)/bin:$PATH"
    fi
  done
fi
if ! command -v jekyll >/dev/null; then
  echo "Jekyll not found. On a Mac: brew install ruby && \$(brew --prefix)/opt/ruby/bin/gem install jekyll" >&2
  exit 1
fi

# The publisher runs SUSHI itself before building the pages.
java -Xmx4g -jar "$jar" -ig "$PWD/ig.ini" "$@"
echo "Open site/index.html (errors and warnings: site/qa.html)"
