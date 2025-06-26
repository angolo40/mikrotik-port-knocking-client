#!/bin/bash

# Script Port Knocking Client per MikroTik
# Uso: ./portknock.sh <IP_MIKROTIK>

# Configurazione
ROUTER_IP="$1"
KNOCK_PORTS=(1001 2002 3003) # Deve corrispondere alla configurazione MikroTik
KNOCK_DELAY=3 # Pausa tra i knock in secondi
CONNECTION_TIMEOUT=2 # Timeout per ogni connessione TCP
RETRY_COUNT=3 # Numero di tentativi per ogni porta

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variabile per il metodo di knocking (inizializzata a vuoto)
KNOCK_METHOD=""

# Funzione per stampare messaggi colorati
print_msg() {
echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

print_success() {
echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

print_error() {
echo -e "${RED}[$(date '+%H:%M:%S')]${NC} $1"
}

print_warning() {
echo -e "${YELLOW}[$(date '+%H:%M:%S')]${NC} $1"
}

# Verifica parametri
if [ -z "$ROUTER_IP" ]; then
print_error "Uso: $0 <IP_ROUTER_MIKROTIK>"
print_msg "Esempio: $0 192.168.1.1"
exit 1
fi

# Verifica tools disponibili e imposta il metodo di knocking
check_tools() {
print_msg "Verifica strumenti necessari (ping, timeout, e uno tra nc, telnet, curl)..."
local missing_core_tools=0
for tool in ping timeout; do
    if ! command -v $tool &>/dev/null; then
        print_error "Strumento '$tool' non trovato. Si prega di installarlo. (e.g., pkg install termux-tools)"
        missing_core_tools=1
    fi
done
if [ $missing_core_tools -eq 1 ]; then
    print_error "Alcuni strumenti essenziali mancano. Uscita."
    exit 1
fi


if command -v nc >/dev/null 2>&1; then
KNOCK_METHOD="nc"
print_msg "Usando netcat (nc) per port knocking (Metodo preferito)."
elif command -v telnet >/dev/null 2>&1; then
KNOCK_METHOD="telnet"
print_msg "Usando telnet per port knocking."
elif command -v curl >/dev/null 2>&1; then
KNOCK_METHOD="curl"
print_msg "Usando curl per port knocking."
else
KNOCK_METHOD="bash"
print_warning "Nessun tool specifico trovato. Usando bash TCP per port knocking (meno robusto)."
fi
print_success "✓ Strumenti principali trovati. Metodo di knock selezionato: $KNOCK_METHOD."
}

# Funzione per eseguire il knock su una porta (metodi specifici)
knock_port_nc() {
local port=$1
# nc con flag SYN (più affidabile per port knocking)
# Prova diversi flag di nc per massima compatibilità
timeout $CONNECTION_TIMEOUT nc -z -v $ROUTER_IP $port >/dev/null 2>&1 || \
timeout $CONNECTION_TIMEOUT nc -w 1 $ROUTER_IP $port </dev/null 2>/dev/null || \
echo "" | timeout $CONNECTION_TIMEOUT nc -w 1 $ROUTER_IP $port 2>/dev/null
return $?
}

knock_port_telnet() {
local port=$1
# telnet richiede un'interazione per chiudere la connessione
(
sleep 0.5
echo "quit"
sleep 0.5
) | timeout $CONNECTION_TIMEOUT telnet $ROUTER_IP $port >/dev/null 2>&1
return 0 # telnet ritorna 0 se riesce a connettersi, anche se poi chiusa
}

knock_port_curl() {
local port=$1
# curl in modalità telnet per una connessione rapida
timeout $CONNECTION_TIMEOUT curl -s --connect-timeout $CONNECTION_TIMEOUT "telnet://$ROUTER_IP:$port" >/dev/null 2>&1
return $?
}

knock_port_bash() {
local port=$1
# Connessione TCP pura con bash (non sempre affidabile per scopi di knocking)
timeout $CONNECTION_TIMEOUT bash -c "exec 3<>/dev/tcp/$ROUTER_IP/$port && exec 3<&-" >/dev/null 2>&1
return $?
}

# Funzione principale per il knock con retry
knock_port() {
local port=$1
local step=$2
local success=false
local result=1

print_msg "Step $step: Knocking porta $port su $ROUTER_IP"

for attempt in $(seq 1 $RETRY_COUNT); do
    case $KNOCK_METHOD in
    "nc")
        knock_port_nc $port
        result=$?
        ;;
    "telnet")
        knock_port_telnet $port
        result=$?
        ;;
    "curl")
        knock_port_curl $port
        result=$?
        ;;
    "bash")
        knock_port_bash $port
        result=$?
        ;;
    esac

    # nc -z e telnet possono tornare 0 anche se non c'è un servizio in ascolto,
    # ma indicano che la connessione TCP a basso livello è stata inviata/stabilita.
    # Questo è sufficiente per il port knocking.
    if [ $result -eq 0 ]; then
        print_success "✓ Knock inviato alla porta $port (tentativo $attempt)"
        success=true
        break
    else
        if [ $attempt -lt $RETRY_COUNT ]; then
            print_warning " Tentativo $attempt fallito per porta $port, riprovo in 1 secondo..."
            sleep 1
        fi
    fi
done

if [ "$success" = false ]; then
    print_error "✗ Tutti i tentativi per porta $port falliti. Controlla la porta o la connettività."
    return 1
fi

return 0
}

# Funzione per testare la connettività ai servizi post-knock
test_port() {
local port=$1
local service=$2
print_msg "Testando $service (porta $port)..."
if timeout 3 nc -z "$ROUTER_IP" $port >/dev/null 2>&1; then
    print_success "✓ $service (porta $port) è ora raggiungibile."
    return 0
else
    print_error "✗ $service (porta $port) non è raggiungibile. Verifica le regole firewall o lo stato del servizio sul MikroTik."
    return 1
fi
}

# --- Inizio Esecuzione Script ---

print_msg "Inizio Port Knocking per MikroTik: $ROUTER_IP"
echo

# Verifica connettività base
print_msg "Verificando raggiungibilità di $ROUTER_IP tramite ping..."
if ping -c 1 -W 3 "$ROUTER_IP" >/dev/null 2>&1; then
    print_success "✓ Router raggiungibile via ping."
else
    print_warning "Router non risponde al ping (normale se ICMP è bloccato sul MikroTik). Procedo con i controlli degli strumenti."
fi
echo

# Controlla tools disponibili e seleziona il metodo
check_tools
echo

# Esegui la sequenza di port knocking con delay ottimizzato
print_msg "Iniziando sequenza Port Knocking..."
print_msg "Sequenza porte: ${KNOCK_PORTS[*]}"
print_msg "Ritardo tra knock: $KNOCK_DELAY secondi"
echo

for i in "${!KNOCK_PORTS[@]}"; do
    local current_port="${KNOCK_PORTS[$i]}"
    local step_number=$((i+1))

    if ! knock_port "$current_port" "$step_number"; then
        print_error "Sequenza interrotta: Fallimento alla porta $current_port."
        print_msg "Controlla la configurazione delle porte o la connettività."
        exit 1
    fi

    # Pausa tra i knock (eccetto l'ultimo)
    if [ $i -lt $((${#KNOCK_PORTS[@]}-1)) ]; then
        print_msg "Attendo $KNOCK_DELAY secondi prima del prossimo knock..."
        for countdown in $(seq $KNOCK_DELAY -1 1); do
            printf "\r${BLUE}[$(date '+%H:%M:%S')]${NC} Countdown: $countdown secondi..."
            sleep 1
        done
        printf "\r${BLUE}[$(date '+%H:%M:%S')]${NC} Pronto per prossimo knock... \n"
    fi
done
echo
print_success "✓ Sequenza Port Knocking completata!"
print_msg "Il tuo IP dovrebbe ora essere autorizzato per 1 ora sul MikroTik."

# Attendi un po' prima del test
print_msg "Attendo 3 secondi per la propagazione delle regole firewall sul MikroTik..."
sleep 3

# Test di connettività immediato
print_msg "Testando immediatamente la connettività ai servizi comuni..."
test_port 22 "SSH"
test_port 80 "HTTP"
test_port 443 "HTTPS"
test_port 8291 "WinBox"
echo

print_msg "Port knocking completato!"
print_msg "Se non riesci ancora ad accedere, prova:"
print_msg "1. Aumenta KNOCK_DELAY nel client e/o address-list-timeout sul MikroTik."
print_msg "2. Controlla i log del MikroTik: /log print (cerca 'firewall,info' o 'firewall,debug')."
print_msg "3. Verifica le regole firewall del MikroTik: /ip firewall filter print (ordine e timeout sono cruciali)."
