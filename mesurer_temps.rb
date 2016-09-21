require 'benchmark'
require_relative 'systeme_planetaire'
require_relative 'var_env'

######################################################################
# Programme pour la mesure des temps d'execution pour les diverses
# sortes de simulation.
######################################################################

######################################################################
# PARAMETRES D'EXECUTION
######################################################################

# Plusieurs parametres d'execution peuvent etre specifies par
# l'intermediaire de variables d'environnement, et sont evidemment
# optionnels:
#
# - METHODES [methode [,methode]*] Methodes a executer
#
# - NB_PLANETES [Fixnum] Nombre de planetes a generer et traiter
# - NB_ITERATIONS [Fixnum] Nombre d'unites de temps a simuler
# - DT [Float] Duree de l'unite de temps
#
# - NB_REPETITIONS [Fixnum] Nombre de repetitions (calcul de moyennes)
#


#
# Par defaut, on execute plusieurs variantes de simulation... a moins
# que la variable d'environnement METHODES ne specifie une ou
# plusieurs versions specifiques. Ceci se fait alors avec un appel a
# make tels que les suivants:
#
# $ METHODES=PFJ:S:2:4 make temps
#
# Un tel appel specifie alors que la version suivante sera executee:
#
#   - Parallelisme fork-join
#   - Repartition statique entre les threads
#   - Taille des taches = 2
#   - Nombre de threads = 4
#
# Un champ peut etre laisse vide, auquel cas une valeur par defaut
# appropriee est utilisee, le cas echeant.
#
#
# Contraintes:
#
# - Les trois separateurs ':' doivent necessairement etre presents.
#
# - Le nombre de threads peut toujours etre omis, auquel cas on
#   utilise PRuby.nb_threads
#
# - La taille des taches peut etre omise, sauf dans le cas dynamique.
#   Lorsqu'omis dans le cas statique, ceci implique une repartition
#   par bloc d'elements adjacents -- donc, si present, une repartition
#   cyclique.
#

# Nombre de planetes a generer.
NB_PLANETES = VariableEnv.val 'NB_PLANETES', 150

# Nombre d'iterations a simuler.
NB_ITERATIONS = VariableEnv.val 'NB_ITERATIONS', 5

# Valeur de l'increment de temps.
DT = VariableEnv.val 'DT', 10

# Nombre de fois ou on repete l'execution.
NB_REPETITIONS = VariableEnv.val 'NB_REPETITIONS', 3 # Pour plus d'uniformite de moyenne

# Pour verifier les resultats produits par la version parallele: si
# true, on verifie que le resultat est le meme que pour la methode
# sequentielle. Par defaut, la verification est effectuee, puisque les
# mise en oeuvre bidon par defaut font simplement un appel a la
# version sequentielle.
AVEC_VERIFICATION = true # && false


# Methodes *paralleles* a 'benchmarker'.  La version sequentielle est
# toujours executee avant les versions paralleles et son temps imprime
# au debut de chaque ligne, pour permettre les mesures ulterieures
# d'acceleration.
METHODES_DEFAUT = [
                   "P:S::",
                   "P:S:1:",
                   "P:S:4:",
                   "P:D:1:",
                   "P:D:4:",
                   "PFJ:S::",
                   "PFJ:S:1:",
                   "PFJ:S:4:",
                  ]

METHODES = VariableEnv.val 'METHODES', METHODES_DEFAUT, ->(x) { x.split(',') }


######################################################################
# METHODES AUXILIAIRES
######################################################################

#
# Pour obtenir la valeur d'une variable qui est une chaine, donc
# devant etre convertie, mais avec une valeur par defaut si non
# specifiee.
#
# @param [String] variable La variable
# @param [Object] defaut La valeur par defaut, si variable pas specifiee
# @param [Proc] conversion La fonction de conversion, si variable specifiee
#
def valeur_var( variable, defaut = nil, conversion = ->(x) { x.to_i } )
  variable == '' ? defaut : conversion.call(variable)
end


#
# Generation aleatoire d'un systeme planetaire avec n planetes.
# @parame [Fixnum] n Nombre de planetes
# @return [SystemePlanetaire] le systeme genere, comportant n planetes
#
def mk_systeme( n )
  planetes = (0...n).map do |i|
    Planete.new( "#{i}",
                 0,
                 rand(10E+15),
                 Vector[rand(10E+10), rand(10E+10)],
                 Vector[rand(10E+10), rand(10E+10)]
                 )
  end

  SystemePlanetaire.new( *planetes )
end

#
# Pour configurer les parametres d'execution d'un SystemePlanetaire,
# notamment a partir des valeurs de la variable METHODES qui peut
# avoir ete specifiee.
#
# @param version [SystemePlanetaire] Le systeme planetaire a configurer
# @param version [String] La chaine fournie specifiant les parametres de la version a tester
#
def configurer_version( systeme, version )
  version =~ /(\w+)\:(\w*)\:(\d*):(\d*)/
  mode, repartition, taille_tache, nb_threads = $1, $2, $3, $4

  systeme.taille_tache = valeur_var taille_tache
  systeme.nb_threads = valeur_var nb_threads, PRuby.nb_threads
  systeme.mode = le_mode( mode, valeur_var( repartition, "S", ->(x){x} ), systeme.taille_tache )
end

#
# Identifie la bonne methode de simulation a partir des differents
# parametres
#
# @param [String] mode
# @param [String] repartition
# @param [Fixnum] taille_tache
# @return [Symbol] symbole representant la methode de simulation
#
def le_mode( mode, repartition, taille_tache )
  return :seq if mode == "S"

  if mode == "P"
    repartition == "S" ? :par_sta : :par_dyn
  else
    DBC.assert mode == "PFJ"
    DBC.assert repartition == "S"
    taille_tache ? :par_fj_cyc : :par_fj_adj
  end
end

#
# Execute de facon repetitive un bloc pour calculer une moyenne de
# temps d'execution.
# @param [Fixnum] nb_fois
# @yieldparam [void]
# @yieldreturn [void]
# @return [Float] temps moyen d'execution
#
def temps_moyen( nb_fois, &block )
  return 0.0 if nb_fois == 0

  tot = 0
  nb_fois.times do
    tot += (Benchmark.measure &block).real
  end

  tot / nb_fois
end

###############################################################
# Le programme principal.
###############################################################

# On imprime l'information sur la taille du probleme et les divers
# autres parametres d'execution.
puts "# TEMPS"
puts "#"
puts "# NB_PLANETES = #{NB_PLANETES} "
puts "# NB_ITERATIONS = #{NB_ITERATIONS}"
puts "# DT = #{DT}"
puts "# NB_REPETITIONS = #{NB_REPETITIONS}"

# On imprime les en-tetes de colonnes.
largeur = METHODES.map(&:size).max + 2
print "# nb.th."
puts
print "#       "
["seq", *METHODES].each do |x|
  print x.rjust(largeur)
end
puts

[1, 2, 4, 8, 16, 32, 64].each do |nb_threads|
  # On execute avec un thread pour "rechauffer" la VM.
  PRuby.nb_threads = nb_threads

  print "%8d" % nb_threads unless nb_threads == 1

  systeme_init = mk_systeme( NB_PLANETES )

  # On mesure le temps de la version sequentielle, qui servira de
  # reference pour calculer l'acceleration de chacune des versions
  # paralleles.
  systeme_seq = systeme_init.clone
  temps_seq = temps_moyen(NB_REPETITIONS) { systeme_seq.simuler( NB_ITERATIONS, DT ) }
  print "%#{largeur}.3f" % temps_seq unless nb_threads == 1

  # On mesure le temps des diverses versions paralleles.
  METHODES.each do |methode|
    PRuby.nb_threads = nb_threads
    systeme_par = systeme_init.clone
    configurer_version( systeme_par, methode )

    temps_par = temps_moyen(NB_REPETITIONS) { systeme_par.simuler( NB_ITERATIONS, DT ) }

    DBC.require systeme_seq.in_delta?(systeme_par) if AVEC_VERIFICATION

    print "%#{largeur}.3f" % temps_par unless nb_threads == 1
  end
  puts unless nb_threads == 1
end
