# video-whatsapp

Cria uma **cópia leve de um vídeo para mandar pelo WhatsApp**. Foi feito para gravações de tela (OBS), como os vídeos do Portal Fiscal.

- O vídeo **original não é alterado**. A cópia sai na mesma pasta, como `<nome> (WhatsApp).mp4`.
- Mantém **Full HD (1920x1080)** para o texto das telas continuar legível.
- Se a cópia passar de **15 MB** (limite do WhatsApp: 16 MB), refaz em **720p**. Se ainda passar, calcula a qualidade para caber. Se nem assim couber (vídeo muito longo), avisa para mandar como **Documento**.
- Mostra uma **janela com barra de progresso** e botão **Cancelar** (no KDE), e a porcentagem no terminal.

Exemplo real: uma gravação de 2 minutos com **38,5 MB** virou **4,5 MB** em Full HD.

---

## Como usar

### Pelo botão direito (KDE / Dolphin)

1. Abra a pasta do vídeo no Dolphin.
2. Clique com o **botão direito** no vídeo e escolha **"Converter para WhatsApp"**.
3. Acompanhe a barra. No fim aparece o aviso "Pronto", com o tamanho final.

Dá para selecionar vários vídeos de uma vez.

### Pelo terminal

```bash
video-whatsapp                          # converte o vídeo mais novo de ~/Vídeos/Portal Fiscal
video-whatsapp "meu video.mp4"          # converte um vídeo específico
video-whatsapp video1.mp4 video2.mkv    # vários de uma vez
```

### Quando fica em Full HD e quando cai para 720p

| Duração (gravação de tela) | Resultado |
|---|---|
| até uns **6 minutos** | **Full HD** (1920x1080) |
| acima de uns 6–7 minutos | 720p, para caber no WhatsApp |
| muito longo (dezenas de minutos) | 720p com qualidade reduzida para caber; se nem assim couber, o aviso final pede para mandar como Documento |

O limite é aproximado: telas paradas (formulários) gastam pouco, e rolar listas ou abrir muitas janelas gasta mais. Para vídeos longos em Full HD, mande pelo WhatsApp como **documento** (📎 → Documento, até 2 GB).

---

## Em qual sistema roda

| Sistema | Funciona? | Observação |
|---|---|---|
| **Linux com KDE Plasma** (Debian, Ubuntu/Kubuntu, Fedora KDE, openSUSE…) | ✅ Completo | Botão direito no Dolphin + janela de progresso |
| **Linux com outro ambiente** (GNOME, XFCE, Cinnamon…) | ✅ Só pelo terminal | Sem o menu do Dolphin; a janela de progresso aparece se `kdialog` e `qdbus6` estiverem instalados |
| **macOS** | ⚠️ Só pelo terminal | Precisa de `bash` 4+ e `ffmpeg` (Homebrew); o `stat -c` do script é do Linux e precisaria de ajuste |
| **Windows** | ❌ Não | Usar pelo WSL (como no Linux, só pelo terminal) |

Testado em: **Debian 13 (trixie)**, KDE Plasma 6.3.6, Wayland, bash 5.2, ffmpeg 7.1, kdialog 25.04.

---

## O que precisa (dependências)

| Programa | Para quê | Obrigatório? | Pacote Debian/Ubuntu |
|---|---|---|---|
| `bash` 4 ou mais novo | roda o script | ✅ Sim | `bash` (já vem instalado) |
| `ffmpeg` e `ffprobe` | converte o vídeo e lê a duração | ✅ Sim | `ffmpeg` |
| `kdialog` | janela de progresso e avisos | Não (sem ele, só terminal) | `kdialog` |
| `qdbus6` (ou `qdbus`) | atualiza a barra de progresso | Não (sem ele, só terminal) | `qdbus-qt6` |
| `coreutils`, `findutils`, `gawk`/`mawk` | `stat`, `find`, `awk` | ✅ Sim | já vêm no sistema |

Instalar tudo no Debian/Ubuntu:

```bash
sudo apt install ffmpeg kdialog qdbus-qt6
```

Codecs usados (vêm no `ffmpeg` do Debian): vídeo **H.264** (`libx264`), áudio **AAC**.

---

## Instalar e desinstalar

```bash
cd /home/suporte/workspace/projetos/video-whatsapp
./install.sh      # instala (ou atualiza) só para o seu usuário — não precisa de sudo
./uninstall.sh    # remove (seus vídeos não são apagados)
```

O `install.sh` coloca:

| Arquivo | Destino |
|---|---|
| `bin/video-whatsapp` | `~/.local/bin/video-whatsapp` |
| `kde/video-whatsapp.desktop.in` | `~/.local/share/kio/servicemenus/video-whatsapp.desktop` (menu do Dolphin) |

Depois de mudar o código, rode `./install.sh` de novo para atualizar a versão instalada.

---

## Como funciona (para quem for mexer no código)

Tudo está em [`bin/video-whatsapp`](bin/video-whatsapp), um script bash.

1. **Escolhe o vídeo:** os arquivos passados como argumento ou, sem argumento, o mais novo de `~/Vídeos/Portal Fiscal` (variável `PASTA_PADRAO`). Ignora arquivos que já são `(WhatsApp)`.
2. **Lê a duração** com `ffprobe`, para calcular a porcentagem.
3. **Converte** com `ffmpeg`:
   - vídeo: `libx264`, `-preset slow`, `-crf 23`, `-tune stillimage` (bom para tela parada), `yuv420p` / perfil `high`, que toca em qualquer celular;
   - áudio: AAC 96 kbps, mono (voz);
   - `-movflags +faststart`: o vídeo começa a tocar antes de baixar inteiro.
4. **Progresso:** o `ffmpeg` roda com `-progress pipe:1`. O script lê o `out_time_us` e atualiza a janela do `kdialog --progressbar` via D-Bus (`qdbus6`). Se o usuário clicar em **Cancelar**, o `ffmpeg` é encerrado e a cópia pela metade é apagada.
5. **Limite:** se a cópia passar de `LIMITE_MB` (15), refaz com `-vf scale=-2:720` e `-crf 26`. Se ainda passar, faz uma 3ª passada em 720p com a taxa calculada para caber: `92% do limite × 8 ÷ duração − 96 kbps do áudio`, com `-b:v`/`-maxrate`. Se a taxa ficar abaixo de 150 kbps (vídeo longo demais), não tenta e avisa para mandar como Documento.

Ajustes mais comuns:

| O que mudar | Onde |
|---|---|
| Pasta padrão dos vídeos | `PASTA_PADRAO` |
| Tamanho máximo antes de cair para 720p | `LIMITE_MB` |
| Qualidade (menor = melhor e maior) | `-crf 23` (Full HD) e `-crf 26` (720p) |

Detalhe: o script força `LC_NUMERIC=C`. Em português, o `awk` escreveria "4,5" em vez de "4.5" e a comparação com o limite daria errado.

---

## Estrutura

```
video-whatsapp/
├── bin/video-whatsapp            # o script
├── kde/video-whatsapp.desktop.in # menu do botão direito do Dolphin (modelo)
├── install.sh                    # instala para o usuário
├── uninstall.sh                  # remove
├── LICENSE                       # licença MIT
└── README.md                     # esta documentação
```

---

## Licença

[MIT](LICENSE): livre para usar, copiar, modificar e distribuir, inclusive para uso comercial, desde que o aviso de copyright e a licença acompanhem o código.

---

## Testes feitos (14/11/2026)

| Teste | Resultado |
|---|---|
| Gravação real do Portal, 2 min, 38,5 MB, sem argumento | ✅ 4,5 MB em Full HD |
| Vídeo "pesado" (ruído em tela cheia), 10 s, 375 MB | ✅ Full HD 233 MB → 720p 44,9 MB → ajustado para **13,6 MB** |
| Arquivo que já é `(WhatsApp)` | ✅ Avisa e não converte |
| Arquivo inexistente | ✅ Mensagem de erro, código de saída 1 |
| Vários vídeos de uma vez (`.mp4` e `.mkv`) | ✅ Converte os dois |
| Barra de progresso | ✅ Chega a 99% em cada etapa e fecha em 100% |
| Botão Cancelar e menu do Dolphin | Precisa de clique: testar à mão |
