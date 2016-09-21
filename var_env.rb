module VariableEnv

  # Obtient la valeur d'une variable d'environnement. Si pas definie,
  # alors retourne une valeur par defaut. Si definie, alors applique
  # une conversion (par defaut = to_i).
  #
  # @param variable Nom de la variable
  # @param defaut Valeur par defaut
  # @param conversion Fonction de conversion de la chaine associee
  # @return La valeur par defaut si la variable non definie, sinon valeur convertie
  #
  def self.val( variable, defaut, conversion = ->(x) { x.to_i } )
    ENV[variable] ? conversion.call(ENV[variable]) : defaut
  end
end
