#!

taille=$1 max=$2
fichier="fichier_temps_$taille.txt"
gnuplot -persist <<EOF
set terminal png
set output 'graphe_acc_$taille.png'
set logscale x
set xlabel "Nombre de threads"
set ylabel "Acceleration absolue"
set title "Acceleration en fonction du nombre de threads pour $taille planetes"
set xtics (2, 4, 8, 16, 32, 64)
plot [1.8:70][0:$max] \
  "$fichier" using 1:(\$2/\$3) title "P:S::" with linespoints,\
  "$fichier" using 1:(\$2/\$4) title "P:S:1:" with linespoints,\
  "$fichier" using 1:(\$2/\$5) title "P:S:4:" with linespoints,\
  "$fichier" using 1:(\$2/\$6) title "P:D:1:" with linespoints,\
  "$fichier" using 1:(\$2/\$7) title "P:D:4:" with linespoints,\
  "$fichier" using 1:(\$2/\$8) title "PFJ:S::" with linespoints,\
  "$fichier" using 1:(\$2/\$9) title "PFJ:S:1:" with linespoints,\
  "$fichier" using 1:(\$2/\$10) title "PFJ:S:4:" with linespoints
EOF

