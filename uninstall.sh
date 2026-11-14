#!/usr/bin/env bash
# Remove o video-whatsapp do usuário atual. Os vídeos (originais e cópias) não são apagados.

set -euo pipefail

rm -f "$HOME/.local/bin/video-whatsapp"
rm -f "$HOME/.local/share/kio/servicemenus/video-whatsapp.desktop"
echo "video-whatsapp removido (seus vídeos não foram mexidos)."
