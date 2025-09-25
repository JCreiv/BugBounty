#!/bin/bash

# Author: Javi (adaptado)

set -euo pipefail

###############
#  CONFIGURACIÓN (edita si hace falta)
###############
DIR="results"   # base para resultados
DOMAIN="$1"   # dominio objetivo
# formato timestamp sin segundos: YYYYMMDD
TIME=$(date "+%Y%m%d")
###############


usage() {
  cat <<EOF
Uso:
  $0 dominio.tld

Genera:
  ${DIR}/<dominio>/<YYYYMMDD>/domains/
  ${DIR}/<dominio>/<YYYYMMDD>/urls/

EOF
  exit 1
}

# comprobar argumentos
if [ $# -eq 0 ]; then
  usage
fi

# Crear directorios

TARGET_DIR="$DIR/$DOMAIN/$TIME"

mkdir -p $TARGET_DIR/domains/raw
mkdir -p $TARGET_DIR/domains/clean
mkdir -p $TARGET_DIR/urls/raw
mkdir -p $TARGET_DIR/urls/clean



# -----------------------------------
# Recolección de dominios/subdominios
# -----------------------------------

# -----------------------------------
# Ejecutar findomain

if [ -f $TARGET_DIR/domains/raw/findomain_raw.txt ]; then
    rm $TARGET_DIR/domains/raw/findomain_raw.txt
fi


findomain -t $DOMAIN -r -u $TARGET_DIR/domains/raw/findomain_raw.txt

sort -u $TARGET_DIR/domains/raw/findomain_raw.txt > $TARGET_DIR/domains/clean/findomain_clean.txt


# -----------------------------------
# Ejecutar sublist3r

if [ -f $TARGET_DIR/domains/raw/sublist3r_raw.txt ]; then
    rm $TARGET_DIR/domains/raw/sublist3r_raw.txt
fi

sublist3r -d $DOMAIN -o $TARGET_DIR/domains/raw/sublist3r_raw.txt

sort -u $TARGET_DIR/domains/raw/sublist3r_raw.txt > $TARGET_DIR/domains/clean/sublist3r_clean.txt


# -----------------------------------
# Ejecutar subfinder

if [ -f $TARGET_DIR/domains/raw/subfinder_raw.txt ]; then
    rm $TARGET_DIR/domains/raw/subfinder_raw.txt
fi

subfinder -d $DOMAIN -o $TARGET_DIR/domains/raw/subfinder_raw.txt

sort -u $TARGET_DIR/domains/raw/subfinder_raw.txt > $TARGET_DIR/domains/clean/subfinder_clean.txt

# -----------------------------------
# Ejecutar cero

if [ -f $TARGET_DIR/domains/raw/cero_raw.txt ]; then
    rm $TARGET_DIR/domains/raw/cero_raw.txt
fi

cero -d $DOMAIN > $TARGET_DIR/domains/raw/cero_raw.txt

sort -u $TARGET_DIR/domains/raw/cero_raw.txt > $TARGET_DIR/domains/clean/cero_clean.txt

# -----------------------------------
# Combinar resultados

cat $TARGET_DIR/domains/clean/*_clean.txt | sort -u > $TARGET_DIR/domains/${1}_domains_all_clean.txt

dnsx -l $TARGET_DIR/domains/${1}_domains_all_clean.txt -o $TARGET_DIR/domains/${1}_domains_all_dnsx.txt


if [ -f $TARGET_DIR/domains/${1}_domains_all_dnsx.txt ]; then
  rm $TARGET_DIR/domains/${1}_domains_all_dnsx.txt
fi

if [ -f $TARGET_DIR/domains/${1}_domains_all_clean.txt ]; then
  rm $TARGET_DIR/domains/${1}_domains_all_clean.txt
fi

# -----------------------------------
# Crawling y filtrado de URLs
# -----------------------------------

# -----------------------------------
# Ejecutar gau con httpx

gau --threads 50 \
    --blacklist "jpg,jpeg,png,gif,svg,css,js,ico,pdf,zip,tar,gz" \
    $DOMAIN \
    --o $TARGET_DIR/urls/raw/gau_raw.txt $(cat $TARGET_DIR/domains/${1}_domains_all_dnsx.txt)

httpx -l $TARGET_DIR/urls/raw/gau_raw.txt -t 100 -sc \
      -mc 200,201,204,301,302,307,401,403,405,500 \
      -o $TARGET_DIR/urls/raw/gau_httpx_raw.txt

if [ -f $TARGET_DIR/urls/raw/gau_raw.txt ]; then
  rm $TARGET_DIR/urls/raw/gau_raw.txt
fi


sort -u "$TARGET_DIR/urls/raw/gau_httpx_raw.txt" | while read -r line; do
    code=$(echo "$line" | sed -r 's/\x1B\[[0-9;]*[mK]//g' | awk -F'[][]' '{print $2}')
    url=$(echo "$line" | awk '{print $1}')

    case $code in
        200) echo "$url" > "$TARGET_DIR/urls/clean/url_200.txt";;
        302) echo "$url" > "$TARGET_DIR/urls/clean/url_302.txt";;
        403) echo "$url" > "$TARGET_DIR/urls/clean/url_403.txt";;
    esac
done

# -----------------------------------
# Ejecutar katana

katana 