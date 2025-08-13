#!/bin/sh

# Main theme color (green-gray)
MAIN='#77977ecc'       # Semi-transparent for rings
MAIN_TEXT='#77977eff'  # Solid for text
BLANK='#00000000'      # Fully transparent
CLEAR='#ffffff22'      # Slightly transparent white
WRONG='#aa4444cc'      # Muted red for wrong password
VERIFYING='#77977ecc'  # Main color for verifying
KEYHL='#88b099ff'      # Lighter main color for keypress
BSHL='#c47a7aff'       # Warm tone for backspace

i3lock \
--insidever-color=$CLEAR       \
--ringver-color=$VERIFYING     \
\
--insidewrong-color=$CLEAR     \
--ringwrong-color=$WRONG       \
\
--inside-color=$BLANK          \
--ring-color=$MAIN             \
--line-color=$BLANK            \
--separator-color=$MAIN        \
\
--verif-color=$MAIN_TEXT       \
--wrong-color=$WRONG           \
--time-color=$MAIN_TEXT        \
--date-color=$MAIN_TEXT        \
--layout-color=$MAIN_TEXT      \
--keyhl-color=$KEYHL           \
--bshl-color=$BSHL             \
\
--screen 1                     \
--blur 5                       \
--clock                        \
--indicator                    \
--time-str="%H:%M:%S"          \
--date-str="%A, %Y-%m-%d"      \
--keylayout 1

