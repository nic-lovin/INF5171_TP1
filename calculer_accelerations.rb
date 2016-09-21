#
# Petit programme pour calculer les accelerations a partir des temps
# d'execution produits par les benchmarks.
#
# Pour une representation plus visuelle, avec des graphes, voir les
# scripts plot-*.sh.
#

lignes = STDIN.readlines

puts "# ACCELERATIONS"
while (ligne = lignes.shift) !~ /^#\s*seq/
  puts ligne unless ligne =~ /^#\s*TEMPS/
end
puts ligne
largeur = ligne.split.map(&:size).max + 1

lignes.each do |ligne_temps|
  # On obtient les informations de la ligne.
  nb_threads, temps_seq, *temps_par = ligne_temps.split
  temps_seq = temps_seq.to_f

  # On calcule les accelerations et l'acceleration maximale.
  accs = temps_par.map do |t|
    temps_seq / t.to_f
  end
  acc_max = accs.max

  # On emet la ligne avec les temps, puis une autre avec les
  # accelerations.
  puts ligne_temps # Temps
  print " " * (9+largeur)
  accs.each do |acc|
    # On met une * a la plus grande acceleration!
    le_max = (acc - acc_max).abs < 0.01 ? "*" : " "
    print "%#{largeur}.2f#{le_max}" % acc
  end
  puts
end
