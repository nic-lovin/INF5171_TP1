gem 'minitest'
require 'minitest/autorun'

#########################################
# Operations pour ignorer certains tests.
##########################################

class Object
  # Pour ignorer temporairement certains tests.

  def _describe( test )
    puts "--- On ignore les tests \"#{test}\" ---"
  end

  def _it( test )
    puts "--- On ignore les tests \"#{test}\" ---"
  end

  # Pour donner look RSpec
  alias :context :describe
  alias :_context :_describe
  alias :it_ :_it
end

def assert_planete_in_delta( p1, p2 )
  assert p1.in_delta?( p2 )
end

def assert_systeme_planetaire_in_delta( s1, s2 )
  assert s1.in_delta? s2
end
