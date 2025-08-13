#!/usr/bin/env bash

# Configurez ici le chemin vers vos thèmes Rofi
dir="$HOME/.config/polybar/scripts/"
theme='style'

# --- Icônes Nerd Font et libellés en français ---
# Actions générales
allumer='󰂯   Allumer'
eteindre='󰂨   Éteindre'
lancer_scan='󰂰   Lancer le scan'
arreter_scan='󰂲   Arrêter le scan'
rafraichir='󰑐   Rafraîchir'

# Actions sur les appareils
connecter='󰂱   Connecter'
deconnecter='󰂲   Déconnecter'
appairer='󰅇   Appairer'
oublier='󰆴   Oublier'
marquer_fiable='󰓡   Marquer comme fiable'

# Icônes pour le statut des appareils
icon_co='󰂱  ' # Connecté
icon_app='󰅇  ' # Appairé
icon_new='󰘠  ' # Nouveau

# Boîte de confirmation
oui='󰄬   Oui'
non='   Non'

# --- Fonctions Rofi ---

# Menu principal
menu_rofi() {
    # La hauteur du menu est maintenant passée en argument
    local line_count="${1:-8}" 

    rofi -dmenu \
        -p "Bluetooth" \
        -mesg "Bluetooth Control" \
        -theme "${dir}/${theme}.rasi" \
        -theme-str "listview {lines: $line_count; }"
}

# Menu de confirmation
menu_confirmation() {
	rofi -dmenu \
        -p 'Confirmation' \
		-mesg 'Êtes-vous sûr ?' \
		-theme "${dir}/${theme}.rasi" \
		-theme-str 'listview {lines: 2; }'
}

# --- Logique du script ---

# Génère la liste principale des options et des appareils
generer_liste_principale() {
    # Options générales
    echo "$eteindre"
    if bluetoothctl show | grep -q "Discovering: yes"; then
        echo "$arreter_scan"
    else
        echo "$lancer_scan"
    fi
    echo "$rafraichir"

    # Liste des appareils
    bluetoothctl devices | sed 's/^Device //' | grep -E '^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | while read -r line; do
        mac=$(echo "$line" | awk '{print $1}')
        name=$(echo "$line" | cut -d' ' -f2-)
        
        if [[ "$name" == "$mac" ]]; then
            continue
        fi

        info=$(bluetoothctl info "$mac")
        
        if echo "$info" | grep -q "Connected: yes"; then
            echo "$icon_co $name ($mac) [Connecté]"
        elif echo "$info" | grep -q "Paired: yes"; then
            echo "$icon_app $name ($mac) [Appairé]"
        else
            echo "$icon_new $name ($mac)"
        fi
    done | sort -u
}

# Affiche le menu d'actions pour un appareil spécifique
menu_actions_appareil() {
    local appareil_selectionne="$1"
    local mac=$(echo "$appareil_selectionne" | grep -oP '(?<=\().*?(?=\))')
    local nom=$(echo "$appareil_selectionne" | awk -F'(' '{print $1}' | xargs)

    [ -z "$mac" ] && return

    local info=$(bluetoothctl info "$mac")
    local options_actions=""
    local line_count=0

    if echo "$info" | grep -q "Connected: yes"; then
        options_actions+="$deconnecter\n"; ((line_count++))
    else
        options_actions+="$connecter\n"; ((line_count++))
    fi

    if echo "$info" | grep -q "Paired: yes"; then
        if ! echo "$info" | grep -q "Trusted: yes"; then
            options_actions+="$marquer_fiable\n"; ((line_count++))
        fi
        options_actions+="$oublier"; ((line_count++))
    else
        options_actions="$appairer"; line_count=1
    fi
    
    action_choisie="$(echo -e "$options_actions" | rofi -dmenu \
        -p "$nom" \
        -mesg "Action pour $nom" \
        -theme "${dir}/${theme}.rasi" \
        -theme-str "listview {lines: $line_count; }")"

    # Exécuter l'action
    case "$action_choisie" in
        "$connecter") bluetoothctl connect "$mac"; exit 0 ;;
        "$deconnecter") bluetoothctl disconnect "$mac"; exit 0 ;;
        "$appairer") bluetoothctl pair "$mac" ;;
        "$marquer_fiable") bluetoothctl trust "$mac" ;;
        "$oublier")
            confirmation="$(echo -e "$oui\n$non" | menu_confirmation)"
            if [[ "$confirmation" == "$oui" ]]; then
                bluetoothctl remove "$mac"
            fi
            ;;
    esac
}

# --- Fonction principale ---
main() {
    while true; do
        if bluetoothctl show | grep -q "Powered: yes"; then
            liste=$(generer_liste_principale)
            
            # On calcule le nombre de lignes et on le limite à 12 max
            line_count=$(echo -e "$liste" | wc -l)
            max_lines=12
            if [[ "$line_count" -gt "$max_lines" ]]; then
                line_count="$max_lines"
            fi

            choix=$(echo -e "$liste" | menu_rofi "$line_count")

            case "$choix" in
                "") exit 0 ;;
                "$eteindre") bluetoothctl power off; exit 0 ;;
                "$lancer_scan") bluetoothctl scan on & sleep 1 ;;
                "$arreter_scan") bluetoothctl scan off ;;
                "$rafraichir") continue ;;
                *) menu_actions_appareil "$choix" ;;
            esac
        else
            choix=$(echo "$allumer" | menu_rofi 1) # Proposer un menu d'une seule ligne
            if [[ "$choix" == "$allumer" ]]; then
                bluetoothctl power on
                sleep 1
                continue
            else
                exit 0
            fi
        fi
    done
}

# Lancer le script
main
