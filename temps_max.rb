#
# Petit programme pour calculer la valeur maximum apparaissant dans un
# fichier de temps d'execution produits par les benchmarks.
#
# Utile pour produire un graphe bien mis en page.
#

lignes = STDIN.readlines

while (ligne = lignes.shift) !~ /^#\s*seq/
  # On ignore la ligne
end

max = 0.0
lignes.each do |ligne_temps|
  # On obtient les informations de la ligne.
  _, temps_seq, *temps_par = ligne_temps.split

  max = [max, temps_seq, *temps_par].map(&:to_f).max
end
puts max
