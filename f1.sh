#!/bin/bash


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear

echo -e "${BLUE}=== CONFIGURARE SIMULATOR F1 ===${NC}"

# =========================
# INPUT UTILIZATOR
# =========================
echo "Alege vremea:"
echo "1 - Uscat"
echo "2 - Ploaie usoara"
echo "3 - Potop"
read -r VREME

echo
echo "Alege starea asfaltului:"
echo "1 - Grippy"
echo "2 - Alunecos"
echo "3 - Ud"
read -r ASFALT

echo
echo "--------------------------------------------------"
echo "Introdu tipul de pneu pentru piloti:"
echo "(Soft, Medium, Hard, Intermediate, Wet)"
echo "--------------------------------------------------"

# =========================
# DATE PILOTI
# =========================
PILOTI=("Verstappen" "Hamilton" "Leclerc" "Norris")
PNEURI=()
PERF_PILOT=(95 91 92 92)

# Citire pneuri
for pilot in "${PILOTI[@]}"; do
    echo "Pneu pentru $pilot:"
    read -r pneu
    PNEURI+=("$pneu")
done

clear

echo -e "${YELLOW}=== CALIFICĂRILE AU ÎNCEPUT ===${NC}"
echo "Vreme cod: $VREME | Asfalt cod: $ASFALT"
echo "--------------------------------------------------"

# =========================
# TIMER SIMULARE
# =========================
START=$(date +%s)

# =========================
# FISIERE TEMPORARE
# =========================
REZULTATE_TMP=$(mktemp)
LOCK_FILE="/tmp/f1.lock"

# =========================
# FUNCTIE SIMULARE TUR
# =========================
simuleaza_tur() {

    local nume=$1
    local performanta_baza=$2
    local pneu=$3

    echo -e "${BLUE}[PID $$]${NC} $nume a intrat pe circuit."

    # =========================
    # SCOR PNEU
    # =========================
    local scor_pneu=50

    if [ "$VREME" -eq 1 ]; then

        # USCAT
        [[ "$pneu" == "Soft" ]] && scor_pneu=100
        [[ "$pneu" == "Medium" ]] && scor_pneu=85
        [[ "$pneu" == "Hard" ]] && scor_pneu=70
        [[ "$pneu" == "Intermediate" ]] && scor_pneu=30
        [[ "$pneu" == "Wet" ]] && scor_pneu=10

    elif [ "$VREME" -eq 2 ]; then

        # PLOAIE USOARA
        [[ "$pneu" == "Intermediate" ]] && scor_pneu=100
        [[ "$pneu" == "Wet" ]] && scor_pneu=70
        [[ "$pneu" == "Medium" ]] && scor_pneu=50
        [[ "$pneu" == "Soft" ]] && scor_pneu=30
        [[ "$pneu" == "Hard" ]] && scor_pneu=25

    else

        # PLOAIE PUTERNICA
        [[ "$pneu" == "Wet" ]] && scor_pneu=100
        [[ "$pneu" == "Intermediate" ]] && scor_pneu=40
        [[ "$pneu" == "Medium" ]] && scor_pneu=20
        [[ "$pneu" == "Hard" ]] && scor_pneu=10
        [[ "$pneu" == "Soft" ]] && scor_pneu=5
    fi

    # =========================
    # FACTOR HAOS
    # =========================
    local haos=$(( RANDOM % 50 ))

    if [ "$ASFALT" -eq 2 ]; then
        haos=$(( haos * 2 ))
    elif [ "$ASFALT" -eq 3 ]; then
        haos=$(( haos + 20 ))
    fi

    # =========================
    # INCIDENT / DNF
    # =========================
    local incident=$(( RANDOM % 100 ))

    if [ "$incident" -lt 10 ]; then

        {
            flock -x 200
            echo "999.999 s -> DNF -> $nume" >> "$REZULTATE_TMP"
        } 200>"$LOCK_FILE"

        echo -e "${RED}$nume a abandonat!${NC}"
        return
    fi

    # =========================
    # CALCUL SCOR
    # =========================
    local scor_total=$(( performanta_baza + scor_pneu - haos ))

    local secunde=$(( 85 - (scor_total / 15) ))
    local milisecunde=$(( RANDOM % 1000 ))


    sleep 1

    # =========================
    # SECTIUNE CRITICA CU MUTEX
    # =========================
    {
        flock -x 200
        printf "%d.%03d s -> %s\n" \
            "$secunde" \
            "$milisecunde" \
            "$nume" >> "$REZULTATE_TMP"
    } 200>"$LOCK_FILE"

    echo -e "${GREEN}$nume a terminat turul.${NC}"
}

# ==============================================================================
# FORK / PROCESE PARALELE
# ==============================================================================

for i in "${!PILOTI[@]}"; do

    simuleaza_tur \
        "${PILOTI[$i]}" \
        "${PERF_PILOT[$i]}" \
        "${PNEURI[$i]}" &

done

echo
echo "Se așteaptă finalizarea tuturor proceselor..."
echo

# =========================
# SINCRONIZARE
# =========================
wait

# =========================
# CLASAMENT FINAL
# =========================
echo
echo -e "${GREEN}=== GRILA DE START ===${NC}"

# Puncte FIA
PUNCTE=(25 18 15 12 0)

pozitie=0

sort -n "$REZULTATE_TMP" | while read -r linie; do

    if [[ "$linie" == *DNF* ]]; then
        nume_pilot=$(echo "$linie" | awk -F'->' '{print $3}' | xargs)
        echo -e "${RED}DNF -> $nume_pilot | Puncte FIA: 0${NC}"
        continue
    fi

    pozitie=$((pozitie + 1))

    puncte=0

    if [ "$pozitie" -le 4 ]; then
        puncte=${PUNCTE[$((pozitie-1))]}
    fi

    echo -e "${YELLOW}$pozitie.${NC} $linie | Puncte FIA: $puncte"

done | tee clasament_final.txt

# =========================
# TIMP TOTAL EXECUTIE
# =========================
END=$(date +%s)

echo
echo -e "${BLUE}Simularea a durat $((END - START)) secunde.${NC}"

# =========================
# CURATARE
# ========================= 
rm "$REZULTATE_TMP"
rm -f "$LOCK_FILE"

echo
echo -e "${GREEN}Clasamentul a fost salvat în: clasament_final.txt${NC}"
echo -e "${GREEN}=== SIMULARE FINALIZATA ===${NC}"
