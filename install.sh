#!/usr/bin/env bash
# Instala o video-whatsapp para o usuário atual (não precisa de sudo):
#   - o comando em ~/.local/bin/video-whatsapp
#   - no KDE, a opção "Converter para WhatsApp" no botão direito do Dolphin
# Rodar de novo atualiza a instalação.

set -euo pipefail

AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINDIR="$HOME/.local/bin"
MENUDIR="$HOME/.local/share/kio/servicemenus"

echo "Instalando o video-whatsapp…"

# 1. dependências (só avisa; não instala nada sozinho)
faltando=()
command -v ffmpeg >/dev/null || faltando+=("ffmpeg")
command -v ffprobe >/dev/null || faltando+=("ffmpeg (ffprobe)")
if [[ ${#faltando[@]} -gt 0 ]]; then
  echo "ERRO: falta instalar: ${faltando[*]}"
  echo "  Debian/Ubuntu: sudo apt install ffmpeg"
  exit 1
fi
if ! command -v kdialog >/dev/null || ! { command -v qdbus6 >/dev/null || command -v qdbus >/dev/null; }; then
  echo "AVISO: sem kdialog/qdbus6 — vai funcionar só pelo terminal (sem janela de progresso)."
  echo "  Debian/Ubuntu: sudo apt install kdialog qdbus-qt6"
fi

# 2. comando
install -Dm755 "$AQUI/bin/video-whatsapp" "$BINDIR/video-whatsapp"
echo "  ✓ comando: $BINDIR/video-whatsapp"

# 3. menu do botão direito do Dolphin (KDE Plasma 6; no 5 a pasta é a mesma)
mkdir -p "$MENUDIR"
sed "s|@BINDIR@|$BINDIR|g" "$AQUI/kde/video-whatsapp.desktop.in" > "$MENUDIR/video-whatsapp.desktop"
chmod +x "$MENUDIR/video-whatsapp.desktop"   # o KDE só mostra menus marcados como executáveis
echo "  ✓ menu do Dolphin: $MENUDIR/video-whatsapp.desktop"

case ":$PATH:" in
  *":$BINDIR:"*) ;;
  *) echo "AVISO: $BINDIR não está no PATH — adicione no ~/.bashrc ou ~/.zshrc:"
     echo "  export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

echo "Pronto. Se a opção não aparecer no botão direito, feche e abra o Dolphin."
