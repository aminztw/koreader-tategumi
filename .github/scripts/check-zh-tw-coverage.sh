#!/usr/bin/env bash
set -euo pipefail

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

make -f make/gettext.mk pot TEMPLATE_DIR="$tmp_dir"
msgfmt --check --no-hash -o "$tmp_dir/koreader.mo" l10n_custom/zh_TW/koreader.po
msgunfmt "$tmp_dir/koreader.mo" -o "$tmp_dir/compiled.po"
msgunfmt l10n_custom/zh_TW/koreader.mo -o "$tmp_dir/shipped.po"
diff -u "$tmp_dir/compiled.po" "$tmp_dir/shipped.po"
msgcmp --no-fuzzy-matching "$tmp_dir/shipped.po" "$tmp_dir/koreader.pot"
