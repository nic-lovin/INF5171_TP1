#!

taille=$1
fichier="fichier_temps_$taille.txt"
max=$(ruby temps_max.rb <$fichier)
gnuplot -persist <<EOF
set terminal png
set output 'graphe_temps_$taille.png'
set logscale x
set xlabel "Nombre de threads"
set ylabel "Temps d'execution (en sec)"
set title "Temps d'execution en fonction du nombre de threads pour $taille planetes"
set xtics (2, 4, 8, 16, 32, 64)
plot [1.8:70][0:$max] \
	 "$fichier" using 1:2 title "seq" with linespoints,\
	 "$fichier" using 1:3 title "P:S::" with linespoints,\
	 "$fichier" using 1:4 title "P:S:1:" with linespoints,\
	 "$fichier" using 1:5 title "P:S:4:" with linespoints,\
	 "$fichier" using 1:6 title "P:D:1:" with linespoints,\
	 "$fichier" using 1:7 title "P:D:4:" with linespoints,\
	 "$fichier" using 1:8 title "PFJ:S::" with linespoints,\
	 "$fichier" using 1:9 title "PFJ:S:1:" with linespoints,\
	 "$fichier" using 1:10 title "PFJ:S:4:" with linespoints
EOF

