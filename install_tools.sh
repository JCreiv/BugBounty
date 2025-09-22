#!/bin/bash

# ===================================
# Instalador de herramientas BugBounty
# ===================================


DRY_RUN=false  # Cambia a true para simular sin ejecutar comandos

if [[ $1 == "--dry-run" ]]; then
    DRY_RUN=true
fi

if [[ $DRY_RUN == true ]]; then
		sudo() { echo "[SIMULADO] sudo $*"; }
		rm()   { echo "[SIMULADO] rm $*"; }
		apt()  { echo "[SIMULADO] apt $*"; }
		cd()   { echo "[SIMULADO] cd $*"; }
		git()  { echo "[SIMULADO] git $*"; }
		wget() { echo "[SIMULADO] wget $*"; }
	    cp()   { echo "[SIMULADO] cp $*"; }
	    tar()  { echo "[SIMULADO] tar $*"; }
	    go() { echo "[SIMULADO] go $*"; } 
        pipx() { echo "[SIMULADO] pipx $*"; }
        curl() { echo "[SIMULADO] curl $*"; }
        sh () { echo "[SIMULADO] sh $*"; }
        source() { echo "[SIMULADO] source $*"; }
fi


GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

DIR=$(pwd)

log_info() { echo -e "${GREEN}[INFO]${RESET} $1"; }

# -----------------------------------
# Actualización del sistema
# -----------------------------------
log_info "Actualizando sistema..."

# -----------------------------------
#Comprobar el OS

os_name=$(grep '^NAME=' /etc/os-release | awk '{print $1 }' | tr '="' ' ' | awk '{print $2 }')


if [ "$os_name" = "Parrot" ]; then
    log_info "Detected OS: Parrot"
    sudo apt update -y && sudo parrot-upgrade -y
else
    sudo apt update -y && sudo apt upgrade -y
fi

# -----------------------------------
# Dependencias comunes
# -----------------------------------

log_info "Instalando dependencias..."
sudo apt install -y git wget unzip python3 python3-pip build-essential curl autoconf make automake libtool pkg-config pipx


# Instalar cargo
if ! command -v cargo &> /dev/null; then
    log_info "Instalando Cargo..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env

    # Detectar shell y añadir PATH al archivo correspondiente
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    else
        SHELL_RC="$HOME/.bashrc"
    fi

    if ! grep -q 'export PATH="$HOME/.cargo/bin:$PATH"' "$SHELL_RC"; then
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$SHELL_RC"
        log_info "Se añadió Cargo al PATH en $SHELL_RC"
    fi
else
    log_info "Cargo ya está instalado: $(cargo --version)"
fi


# -----------------------------------
# Instalación de Go desde el tar.gz oficial
# -----------------------------------
GO_VERSION="1.25.1"
GO_ARCHIVE="go${GO_VERSION}.linux-amd64.tar.gz"
GO_URL="https://go.dev/dl/${GO_ARCHIVE}"

if ! command -v go &> /dev/null; then
    log_info "Go no está instalado. Instalando Go $GO_VERSION..."

    # Descargar Go si no existe
    if [ ! -f "$DIR/$GO_ARCHIVE" ]; then
        wget "$GO_URL" -O "$DIR/$GO_ARCHIVE"
    fi

    # Eliminar instalación previa y extraer la nueva
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "$DIR/$GO_ARCHIVE"

    # Hacer que go y gofmt estén disponibles para todos los usuarios
    sudo ln -sf /usr/local/go/bin/go /usr/local/bin/go
    sudo ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

    # Añadir Go al PATH del usuario
    if [[ ":$PATH:" != *":/usr/local/go/bin:"* ]]; then
        log_info "Añadiendo /usr/local/go/bin al PATH"
        echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.profile"
        export PATH=$PATH:/usr/local/go/bin
    fi

    # Verificar instalación
    go version
else
    log_info "Go ya está instalado: $(go version)"
fi

# -----------------------------------
# Findomain
if ! command -v findomain &> /dev/null; then
    log_info "Instalando Findomain..."
    git clone https://github.com/findomain/findomain.git
    cd findomain
    cargo build --release
    sudo cp target/release/findomain /usr/bin/
    cd "$DIR"
else
    log_info "Findomain ya instalado."
fi

# -----------------------------------
# Amass
if ! command -v amass &> /dev/null; then
    log_info "Instalando Amass..."
    CGO_ENABLED=0 go install -v github.com/owasp-amass/amass/v5/cmd/amass@main
else
    log_info "Amass ya instalado."
fi

# -----------------------------------
# Subfinder
if ! command -v subfinder &> /dev/null; then
    log_info "Instalando Subfinder..."
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
else
    log_info "Subfinder ya instalado."
fi

# -----------------------------------
# Sublist3r
if ! command -v sublist3r &> /dev/null; then
    log_info "Instalando Sublist3r..."
    git clone https://github.com/aboul3la/Sublist3r.git
    cd Sublist3r
    pipx install .
    pipx ensurepath
    cd "$DIR"
else
    log_info "Sublister ya instalado."
fi

# -----------------------------------
# Dnsx
if ! command -v dnsx &> /dev/null; then
    log_info "Instalando Dnsx..."
    go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest
else
    log_info "Dnsx ya instalado."
fi

# -----------------------------------
# Httpx
if ! command -v httpx &> /dev/null; then
    log_info "Instalando Httpx..."
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
else
    log_info "Httpx ya instalado."
fi

# -----------------------------------
# Cero

if ! command -v cero &> /dev/null; then
    log_info "Instalando Cero..."
    go install github.com/glebarez/cero@latest
else
    log_info "Cero ya instalado."
fi

# -----------------------------------
# Gowitness

if ! command -v gowitness &> /dev/null; then
    log_info "Instalando Gowitness..."
    go install github.com/sensepost/gowitness@latest
else
    log_info "Gowitness ya instalado."
fi

# -----------------------------------
# Katana

if ! command -v katana &> /dev/null; then
    log_info "Instalando Katana..."
    CGO_ENABLED=1 go install github.com/projectdiscovery/katana/cmd/katana@latest
else
    log_info "Katana ya instalado."
fi

# -----------------------------------
# Gau

if ! command -v gau &> /dev/null; then
    log_info "Instalando Gau..."
    go install github.com/lc/gau/v2/cmd/gau@latest
else
    log_info "Gau ya instalado."
fi


# -----------------------------------
# Actualizar PATH para herramientas Go

if [[ ":$PATH:" != *":$HOME/go/bin:"* ]]; then
    echo 'export PATH=$HOME/go/bin:$PATH' >> "$HOME/.zshrc"
    export PATH=$HOME/go/bin:$PATH
    log_info "Añadido $HOME/go/bin al PATH"
fi


# -----------------------------------
# Nuclei

if ! command -v nuclei &> /dev/null; then
    log_info "Instalando Nuclei..."
    go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest

    log_info "Actualizando templates de Nuclei..."
    nuclei -update-templates
else
    log_info "Nuclei ya instalado."
fi




