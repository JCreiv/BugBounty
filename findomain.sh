#!/bin/bash

# Script para enumerar subdominios usando findomain
# Requisitos: findomain (https://github.com/Findomain/Findomain)
# Author: Javi (adaptado)

set -euo pipefail

###############
#  CONFIGURACIÓN (edita si hace falta)
###############
DIR="results"   # base para resultados
# formato timestamp sin segundos: YYYYMMDD_HH
TIME=$(date "+%Y%m%d")
###############


usage() {
  cat <<EOF
Uso:
  $0 dominio.tld
  $0 -i fichero_dominios.txt

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

TARGET_DIR="$DIR/$1/$TIME"

mkdir -p $TARGET_DIR/raw
mkdir -p $TARGET_DIR/clean

if [ -f $TARGET_DIR/raw/findomain_raw.txt ]; then
    rm $TARGET_DIR/raw/findomain_raw.txt
fi

findomain -t $1 -r -u $TARGET_DIR/raw/findomain_raw.txt

sort -u $TARGET_DIR/raw/findomain_raw.txt > $TARGET_DIR/clean/findomain_clean.txt
