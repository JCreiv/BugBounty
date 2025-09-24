#!/bin/bash

# Author: Javi (adaptado)

set -euo pipefail

###############
#  CONFIGURACIÓN (edita si hace falta)
###############
DIR="results"   # base para resultados
# formato timestamp sin segundos: YYYYMMDD
TIME=$(date "+%Y%m%d")
###############


usage() {
  cat <<EOF
Uso:
  $0 dominio.tld

Genera:
  ${DIR}/<dominio>/<YYYYMMDD>/raw/
  ${DIR}/<dominio>/<YYYYMMDD>/clean/

El script espera que 'findomain' esté en PATH.
EOF
  exit 1
}

# comprobar argumentos
if [ $# -eq 0 ]; then
  usage
fi

# comprobar findomain
if ! command -v findomain >/dev/null 2>&1; then
  echo "ERROR: 'findomain' no encontrado en PATH. Instálalo e inténtalo de nuevo." >&2
  exit 2
fi

# Crear directorios

TARGET_DIR="$DIR/$1/$TIME"

mkdir -p $TARGET_DIR/domains/raw
mkdir -p $TARGET_DIR/domains/clean
mkdir -p $TARGET_DIR/urls/raw
mkdir -p $TARGET_DIR/urls/clean

# -----------------------------------
# Ejecutar findomain

if [ -f $TARGET_DIR/domains/raw/findomain_raw.txt ]; then
    rm $TARGET_DIR/domains/raw/findomain_raw.txt
fi


findomain -t $1 -r -u $TARGET_DIR/domains/raw/findomain_raw.txt

sort -u $TARGET_DIR/domains/raw/findomain_raw.txt > $TARGET_DIR/domains/clean/findomain_clean.txt


# -----------------------------------
# Ejecutar sublist3r

if [ -f $TARGET_DIR/domains/raw/sublist3r_raw.txt ]; then
    rm $TARGET_DIR/domains/raw/sublist3r_raw.txt
fi

sublist3r -d $1 -o $TARGET_DIR/domains/raw/sublist3r_raw.txt

sort -u $TARGET_DIR/domains/raw/sublist3r_raw.txt > $TARGET_DIR/domains/clean/sublist3r_clean.txt


# -----------------------------------
# Ejecutar subfinder

if [ -f $TARGET_DIR/domains/raw/subfinder_raw.txt ]; then
    rm $TARGET_DIR/domains/raw/subfinder_raw.txt
fi

subfinder -d $1 -o $TARGET_DIR/domains/raw/subfinder_raw.txt

sort -u $TARGET_DIR/domains/raw/subfinder_raw.txt > $TARGET_DIR/domains/clean/subfinder_clean.txt

# -----------------------------------
# Ejecutar cero

if [ -f $TARGET_DIR/domains/raw/cero_raw.txt ]; then
    rm $TARGET_DIR/domains/raw/cero_raw.txt
fi

cero -d $1 > $TARGET_DIR/domains/raw/cero_raw.txt

sort -u $TARGET_DIR/domains/raw/cero_raw.txt > $TARGET_DIR/domains/clean/cero_clean.txt

# -----------------------------------
# Combinar resultados

cat $TARGET_DIR/domains/clean/*_clean.txt | sort -u > $TARGET_DIR/domains/${1}_domains_all_clean.txt

dnsx -l $TARGET_DIR/domains/${1}_domains_all_clean.txt -o $TARGET_DIR/domains/${1}_domains_all_dnsx.txt

# -----------------------------------
# Ejecutar gau

if [ -f $TARGET_DIR/urls/raw/gau_raw.txt ]; then
  rm $TARGET_DIR/urls/raw/gau_raw.txt
fi

gau --threads 50 \
    --blacklist "jpg,jpeg,png,gif,svg,css,js,ico,pdf,zip,tar,gz" \
    $1 \
    --o $TARGET_DIR/urls/raw/gau_raw.txt $(cat $TARGET_DIR/domains/${1}_domains_all_clean.txt)

httpx -l $TARGET_DIR/urls/raw/gau_raw.txt -t 100 -sc \
      -mc 200,201,204,301,302,307,401,403,405,500 \
      -o $TARGET_DIR/urls/raw/gau_httpx_raw.txt



