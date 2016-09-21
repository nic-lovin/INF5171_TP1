require 'pruby'
require 'vector'
require 'matrix'
require_relative 'vector'

# Classe modelisant une planete.
#
#  Pour plus de details, des explications sur ce genre de calculs sont
#  presentes dans l'article "The approximation tower in computational
#  science: Why testing scientific software is difficult", K. Hinsen,
#  Computing in Science & Engineering Volume 17, Issue 4, p. 72-77.
#  http://ieeexplore.ieee.org/xpl/articleDetails.jsp?arnumber=7131419
#
class Planete

  #
  # La constante de gravitation universelle.
  # https://fr.wikipedia.org/wiki/Constante_gravitationnelle
  #
  G = 6.67384E-11 # m**3 kg**-1 s**-2;

  #####################################################################
  # Constructeurs et attributs.
  #####################################################################

  # Constructeur d'un objet Planete.
  #
  # @param [String] nom
  # @param [Fixnum] taille
  # @param [Float] masse
  # @param [Vector] position
  # @param [Vector] vitesse
  #
  # @require taille > 0
  #
  def initialize( nom, taille, masse, position, vitesse )
    @nom = nom # String
    @taille = taille # Fixnum
    @masse = masse # Float
    @position = position # Vector
    @vitesse = vitesse # Vector
  end

  # Nom de la planete.
  #
  # @return [String]
  #
  attr_reader :nom


  # Masse de la planete, en kg.
  #
  # @return [Float]
  #
  attr_reader :masse

  # Position dans l'espace 2D, sous forme vectorielle.
  #
  # @return [Vector]
  #
  attr_reader :position

  # Vitesse de deplacement, sous forme vectorielle.
  #
  # @return [Vector]
  #
  attr_reader :vitesse


  # Taille, pour l'affichage avec Processing.
  #
  # @return [Fixnum]
  #
  # Taille pour l'affichage, avec Processing.  Le rapport entre les
  # tailles n'est pas necessairement le meme que celui entre les
  # masses... parce que sinon cela pourrait etre trop petit pour
  # s'afficher correctement a l'ecran.
  #
  attr_reader :taille

  # Chaine identifiant la planete.
  #
  # Pour cette mise en oeuvre, seul le nom est indique.
  #
  # @return [String]
  #
  def to_s
    nom
  end

  #####################################################################
  # Methodes.
  #####################################################################

  # Force exercee par une autre planete.
  #
  # @note p1.force_de( p2 ) = -1 * p2.force_de( p1 )
  #
  # @param [Planete] autre l'autre planete
  # @return [Vector]
  #
  def force_de( autre )
    dist = (position - autre.position).magnitude
    f = ( G * masse * autre.masse ) / ( dist * dist )

    (f / dist) * (autre.position - position)
  end


  # Deplace la planete en fonction d'une certaine force et une
  # certaine periode de temps.
  #
  # @param [Vector] force
  # @param [Float] dt intervalle de temps
  #
  # @require dt > 0.0
  #
  # @return [self]
  #
  def deplacer( force, dt )
    # Acceleration : F = ma => a = F/m
    acc = force / masse

    # Changement de vitesse durant l'intervalle.
    dvit = dt * acc

    # Changement de position: on prend la vitesse au milieu de
    # l'intervalle, i.e., moyenne entre la vitesse au debut et vitesse
    # a la fin:  vit + (vit + dvit)) / 2 = vit + dvit/2
    dpos = (vitesse + 0.5 * dvit) * dt

    # Mise a jour de la vitesse et de la position.
    @vitesse += dvit
    @position += dpos

    self
  end

  # Distance par rapport a une autre planete.
  #
  # @param [Planete] autre
  #
  # @return [Vector] distance entre self et autre
  #
  def distance( autre )
    position.distance(autre.position)
  end

  # Determine si une autre planete a la meme position et vitesse, a un
  # delta pres.
  #
  # Utilise pour les assertions dans les tests.
  #
  # @param [Planete] autre
  # @param [Float] delta
  # @return [Bool] true si position et vitesse sont les memes (delta pres)
  #
  def in_delta?( autre, delta = 0.001 )
    position.distance(autre.position) < delta &&
      vitesse.distance(autre.vitesse) < delta
  end
end
