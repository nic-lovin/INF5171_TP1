require 'pruby'

require_relative 'planete'

# Classe modelisant un systeme planetaire, donc un groupe de planetes
# qui vont interagir entre elles en fonction de leurs masses et de
# leurs positions.
#
# Chaque planete est dotee d'une position et d'une vitesse initiale.
# L'ensemble des mouvements des planetes est ensuite simule, selon
# divers parametres.
#
class SystemePlanetaire

  # Pour activer la trace de debogage, on met '#' devant '&&'.
  DEBUG = true && false

  #####################################################################
  # Les differents modes d'execution pour le calcul des forces et le
  # deplacement des planetes.
  #####################################################################
  #
  # Les differentes modes representent des strategies differentes
  # d'execution, sequentielle ou paralleles, des deux principales
  # methodes utilisees par la methode simuler, soit celles pour le
  # calcul des forces (calculer_forces_X) et celle pour le deplacement
  # des planetes resultant de ces forces (deplacer_X).
  #

  MODES = [:seq,
    :par_fj_fin,
    :par_fj_adj,
    :par_fj_cyc,
    :par_sta,
    :par_dyn,
  ]

  MODES_AVEC_TAILLE_TACHE = [:par_fj_cyc, :par_sta, :par_dyn]

  #####################################################################
  # Parametres et methodes specifiques a des executions paralleles.
  #####################################################################

  # Mode d'execution a utiliser lors d'une simulation.
  #
  # Valeur par defaut = :seq
  #
  # @return [<MODES>]
  #
  attr_reader :mode

  # Pour specifier le mode d'execution a utiliser lors d'une
  # simulation.
  #
  # @!parse attr_writer :mode
  # @return [<MODES>]
  #
  def mode=( m )
    if m
      DBC.require MODES.include?(m), "*** Mode invalide = #{m}"
    end

    @mode = m
  end


  # Nombre de threads a utiliser lors d'une simulation parallele.
  #
  # Valeur par defaut = nil
  #
  # @return [nil, Fixnum]
  #
  attr_reader :nb_threads

  # Pour specifier le nombre de threads a utiliser pour l'execution
  # d'une simulation parallele a granularite grossiere.
  #
  # @!parse attr_writer :nb_threads
  # @return [Fixnum]
  #
  def nb_threads=( nbt )
    if nbt
      DBC.check_type nbt, Fixnum, "*** Nb. threads invalide = #{nbt}"
      DBC.require nbt > 0, "*** Nb. threads invalide = #{nbt}"
    end

    @nb_threads = nbt
  end


  # Taille par defaut des taches pour les approches a granularite
  # grossiere avec taches.
  TAILLE_TACHE_DEFAUT = 5

  # Taille des taches a utiliser lors d'une simulation parallele.
  #
  # Valeur par defaut = nil
  #
  # @return [nil, Fixnum]
  #
  attr_reader :taille_tache

  # Pour specifier la taille des taches a utiliser pour l'execution
  # d'une simulation parallele a granularite grossiere avec taches
  # (par ex., cyclique, dynamique).
  #
  # @!parse attr_writer :taille_tache
  # @return [Fixnum]
  #
  def taille_tache=( tt )
    if tt
      DBC.check_type tt, Fixnum, "*** Taille tache invalide = #{tt}"
      DBC.require tt > 0, "*** Taille tache invalide = #{tt}"
    end

    @taille_tache = tt
  end


  #####################################################################
  # Constructeurs et attributs d'un systeme planetaire.
  #####################################################################

  # Initialise un systeme planetaire.
  #
  # @param [Array<Planete>] planetes une liste de planetes composant le systeme
  #
  # @ensure self.planetes == planetes && self.nb_planetes == planetes.size
  # @ensure nb_threads == PRuby.nb_threads
  #
  def initialize( *planetes )
    @planetes = planetes
    @nb_planetes = @planetes.size
    @nb_threads = PRuby.nb_threads
    @mode = :seq
  end

  # Clone un systeme planetaire.
  #
  # @note Utile pour les tests, pour comparer deux facons differentes
  #   de faire evoluer un meme systeme et assurer que les effets sont
  #   les memes etant donne un meme systeme de depart.
  #
  # @return [SystemePlanetaire] systeme identique au systeme initial
  #   mais ou chaque planete a ete clonee
  #
  def clone
    planetes = @planetes.map(&:clone)
    SystemePlanetaire.new( *planetes )
  end

  # Nombre de planetes dans le systeme.
  #
  # @return [Fixnum]
  #
  attr_reader :nb_planetes

  # Liste des planetes dans le systeme.
  #
  # @return [Array<Planete>]
  #
  attr_reader :planetes

  # La i-eme planete du systeme.
  #
  # @param [Fixnum] i
  # @return [Planete]
  #
  # @require 0 <= i < nb_planetes
  #
  def []( i )
    @planetes[i]
  end


  #####################################################################
  # Methode de simulation des interactions entre planetes.
  #####################################################################

  # Simule l'evolution d'un groupe de planetes pendant un certain
  # nombre d'iterations (un certain nombre de 'time steps'), chacun
  # d'une certaine duree, en utilisant un mode particulier de
  # simulation (mise en oeuvre sequentielle ou parallele).
  #
  # @param [Fixnum] nb_iterations
  # @param [Float] dt temps pour chaque time step
  # @return [void]
  #
  # @require dt > 0.0
  # @ensure les diverses planetes ont ete deplacees en fonction de
  #    leurs interactions simulees
  #
  def simuler( nb_iterations, dt )
    DBC.require MODES.include?(mode), "*** Mode invalide = #{mode}"

    if MODES_AVEC_TAILLE_TACHE.include?(mode)
      DBC.require taille_tache.nil? || taille_tache == true || taille_tache > 0
      @taille_tache = taille_tache || TAILLE_TACHE_DEFAUT
    end

    puts "On simule #{mode} pour #{nb_iterations} iterations" if DEBUG

    nb_iterations.times do
      # On calcule l'ensemble des forces s'exercant sur chacune des
      # planetes (donc en fonction de toutes les autres planetes).
      forces = send "calculer_forces_#{mode}"

      # On deplace chacune des planetes selon les forces calculees.
      send "deplacer_#{mode}", forces, dt
    end
  end


  # Determine si un autre systeme planetetaire a la meme configuration
  # (memes planetes et memes position/vitesse), a un delta pres.
  #
  # Utilise pour les assertions dans les tests.
  #
  # @param [SystemePlanetaire] autre
  # @param [Float] delta
  # @return [Bool] true si position et vitesse sont les memes (delta pres)
  #                 pour chacune des plantes
  #
  def in_delta?( autre, delta = 0.001 )
    return false unless planetes.size == autre.planetes.size

    (0...planetes.size).all? { |k| self[k].in_delta? autre[k] }
  end

  private



  #################################################################
  # Calcul des forces exercees entre les diverses planetes
  #
  # @return [Array<Vector>]
  #
  # @ensure result[i] = sommes des forces exercees sur la i-eme
  #   planete par l'ensemble des autres planetes, en ignorant l'effet
  #   de la i-eme planete elle-meme.
  #
  # @note On peut utiliser equal? pour determiner si deux objets sont
  #   en fait le meme objet, i.e., equal? compare les references (les
  #   pointeurs, les identites) et non l'egalite de valeur.
  #
  #################################################################


  def calculer_forces_seq
    calculer_forces_par_fj_adj_ij(0, planetes.size-1)
  #  planetes.map { |planete| calcule_force_planet(planete) }
  end

  def calculer_forces_par_fj_fin
    futures = planetes.map { |planete| PRuby.future { calcule_force_planet(planete)} }
    futures.map(&:value)
  end

  def calculer_forces_par_fj_adj
    nb_threads = [PRuby.nb_threads || planetes.size, planetes.size].min
    futures = (0...nb_threads).map do |k|
      PRuby.future do
        bornes = bornes_tranche( k, nb_threads )
        calculer_forces_par_fj_adj_ij( bornes.begin, bornes.end)
      end
    end
    futures
      .map(&:value)
      .reduce (:+)
  end

  def calculer_forces_par_fj_adj_ij (i,j)
    (i..j).map { |index| calcule_force_planet(planetes[index]) }
  end

  def calculer_forces_par_fj_cyc
    nb_threads = [PRuby.nb_threads || planetes.size, planetes.size].min
    futures = (0...nb_threads).map do |k|
      PRuby.future do
        bornes = bornes_tranche_taille( k, nb_threads, taille_tache )
        puts "la liste de range: #{bornes} pour le thread #{k}"
        (bornes.nil? || bornes.empty?) ? 0 : bornes.reduce { |force, borne| force + calculer_forces_par_fj_adj_ij( borne.begin, borne.end) }
      end
    end
    futures
      .map(&:value)
      .reduce (:+)
  end

  def calculer_forces_par_sta
   #puts "la valeur de taille_tache: #{taille_tache}" if taille_tache == true
    planetes.pmap(static:taille_tache) { |planete| calcule_force_planet(planete) }
  end

  def calculer_forces_par_dyn
    # A REMPLACER PAR LA VERSION PARALLELE.
    planetes.pmap(dynamic:taille_tache) { |planete| calcule_force_planet(planete) }
  end

  def calcule_force_planet (planete)
    vect = Vector[0, 0] #preduce help
    planetes.each { |autre| vect += autre.force_de(planete) unless autre.equal?(planete)}
    vect
    #planetes
  #    .map { |autre| autre.force_de(planete) unless autre.equal?(planete)}
  #    .reduce (:+)
  end

  def bornes_tranche( k, nb_threads )
    (k * planetes.size / nb_threads..(k + 1) * planetes.size / nb_threads - 1)
  end

  def bornes_tranche_taille( k, nb_threads, taille_tache )
  #  puts "nombre de planetes: #{planetes.size}  nombre de thread #{nb_threads} donc saut de #{(nb_threads-1) * taille_tache}"
    depart = (k)*taille_tache
  #  return [] if depart >= planetes.size
  #  puts "le depart: #{depart} pour le thread #{k}"
    liste = (depart...planetes.size).step((nb_threads-1) * taille_tache).map { |i| i...[i+taille_tache, planetes.size].min }
  #  puts "la liste de range: #{liste} pour le thread #{k}"
  liste
  end


  #################################################################
  # Deplace un groupe de planetes selon un ensemble de vecteurs de
  # force, pour une certaine periode de temps et ce en utilisant un
  # mode specifique d'execution.
  #
  # @param [Array<Vector>] forces
  # @param [Float] dt temps de deplacement
  # @return [void]
  #
  # @require dt > 0.0
  # @ensure La i-eme planete a ete deplacee selon la force indiquee
  #   par forces[i] pour la duree indiquee
  #
  #################################################################


  def deplacer_seq( forces, dt )
    deplacer_par_fj_adj_ij( 0, planetes.size-1, forces, dt )
  end

  def deplacer_par_fj_fin( forces, dt )
    futures = planetes.each_index.map { |index| PRuby.future { deplacer_planete_index(index, forces, dt) } }
    futures.map(&:value)
  end

  def deplacer_par_fj_adj( forces, dt )
    nb_threads = [PRuby.nb_threads || planetes.size, planetes.size].min
    futures = (0...nb_threads).map do |k|
      PRuby.future do
        bornes = bornes_tranche( k, nb_threads )
        deplacer_par_fj_adj_ij( bornes.begin, bornes.end, forces, dt )
      end
    end
    futures.map(&:value)
  end

  def deplacer_par_fj_adj_ij( i, j, forces, dt )
    (i..j).each { |index| deplacer_planete_index(index, forces, dt) }
  end

  def deplacer_par_fj_cyc( forces, dt )
    # A REMPLACER PAR LA VERSION PARALLELE.
    deplacer_seq( forces, dt )
  end

  def deplacer_par_sta( forces, dt )
    planetes.peach_index(static:taille_tache) { |index| deplacer_planete_index(index, forces, dt) }
  end

  def deplacer_par_dyn( forces, dt )
    planetes.peach_index(dynamic:taille_tache) { |index| deplacer_planete_index(index, forces, dt) }
  end

  def deplacer_planete_index (index, forces, dt)
    planetes[index].deplacer( forces[index], dt ) unless forces[index].nil?
  end

end
