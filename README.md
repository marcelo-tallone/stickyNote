# StickyNote

App de notas flotantes para macOS. Muestra un bloc de notas amarillo que permanece visible por encima de todas las ventanas y aplicaciones, sin importar el escritorio en el que estés trabajando.

## Características

- **Siempre visible** — flota sobre todas las ventanas y aplicaciones
- **Todos los escritorios** — permanece visible al cambiar de Space
- **Sin formato** — al pegar texto (`Cmd+V`) se elimina automáticamente el formato (fuente, color, tamaño, etc.)
- **Múltiples notas** — podés tener varias abiertas a la vez
- **Historial** — al cerrar una nota se guarda automáticamente (últimas 50)
- **Barra de desplazamiento** — scroll vertical cuando el contenido supera el tamaño de la ventana
- **Redimensionable** — arrastrá las esquinas para cambiar el tamaño
- **Sin ícono en el Dock** — vive discretamente en la barra de menú (ícono 📝)
- **Auto-inicio** — se puede configurar para iniciar automáticamente con macOS

## Requisitos

- macOS 11 (Big Sur) o superior
- Apple Silicon (ARM64)
- Xcode Command Line Tools

## Instalación

### 1. Instalar Xcode Command Line Tools

Si no los tenés instalados:

```bash
xcode-select --install
```

Aparecerá un diálogo en pantalla — hacer click en **Instalar** y esperar que termine.

### 2. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/StickyNote.git
cd StickyNote
```

### 3. Compilar e instalar

```bash
bash build.sh
cp -r build/StickyNote.app /Applications/
```

### 4. Abrir la app

Buscala en Spotlight (`Cmd+Space` → "StickyNote") o desde el Finder en `/Applications`.

> **Primera vez:** macOS puede mostrar un aviso de seguridad porque la app no tiene firma de Apple Developer. Ir a **Configuración del Sistema → Privacidad y Seguridad** y hacer click en **"Abrir de todos modos"**. O alternativamente, hacer **click derecho → Abrir** la primera vez.

### 5. (Opcional) Auto-inicio al encender la Mac

Para que la app se inicie automáticamente al iniciar sesión:

```bash
cat > ~/Library/LaunchAgents/com.user.stickynote.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.stickynote</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/StickyNote.app/Contents/MacOS/StickyNote</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.user.stickynote.plist
```

Para desactivar el auto-inicio:

```bash
launchctl unload ~/Library/LaunchAgents/com.user.stickynote.plist
```

## Uso

| Acción | Resultado |
|--------|-----------|
| Click izquierdo en 📝 | Abre una nueva nota |
| Click derecho en 📝 | Menú: historial, nueva nota, salir |
| `Cmd+V` dentro de una nota | Pega texto sin formato |
| Cerrar una nota (X) | La guarda en el historial |
| Arrastrar esquina de la nota | Redimensionar |
| Arrastrar la nota | Moverla de lugar |

## Estructura del proyecto

```
StickyNote/
├── main.swift          # Código fuente principal
├── create_icon.swift   # Script que genera el ícono de la app
├── Info.plist          # Configuración del bundle de macOS
└── build.sh            # Script de compilación completo
```

## Desinstalación

```bash
# Quitar de Aplicaciones
rm -rf /Applications/StickyNote.app

# Quitar auto-inicio (si fue configurado)
launchctl unload ~/Library/LaunchAgents/com.user.stickynote.plist
rm ~/Library/LaunchAgents/com.user.stickynote.plist

# Borrar historial y preferencias guardadas
defaults delete com.user.stickynote
```
