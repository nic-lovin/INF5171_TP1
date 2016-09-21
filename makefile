###############################################################
#
# Makefile pour le devoir 1 INF5171-20, automne 2016.
#
###############################################################

###############################################################
# Constante a completer pour la remise de votre travail:
#  - CODES_PERMANENTS
###############################################################

### Vous devez completer l'une ou l'autre des definitions.   ###

# Deux etudiants:
# Si vous etes deux etudiants: Indiquer vos codes permanents.
CODES_PERMANENTS='ABCD01020304,GHIJ11121314'


# Un etudiant:
# Si vous etes seul: Supprimer le diese en debut de ligne et
# indiquer votre code permanent (sans changer le nom de la variable).
#CODES_PERMANENTS='ABCD01020304'


FICHIERS_A_REMETTRE=systeme_planetaire.rb

###############################################################
# Cible par defaut: tests pour version sequentielle.
TEST=tests_seq

# Cibles pour tester une version parallele specifique (tests_par).
# Pour ce faire, il suffit de supprimer le '#' en debut de ligne
# devant le test desire.

#TEST=tests_par_fj_fin
#TEST=tests_par_fj_adj
#TEST=tests_par_fj_cyc
#TEST=tests_par_sta
#TEST=tests_par_dyn
#TEST=tests_par


default: $(TEST)



##################################
# Tests.
##################################

# Tests pour la version sequentielle.
tests_seq:
	ruby systeme_planetaire_spec.rb

# Tests pour les diverses versions paralleles.
tests_par_fj_fin:
	MODE=par_fj_fin ruby systeme_planetaire_par_spec.rb

tests_par_fj_adj:
	MODE=par_fj_adj ruby systeme_planetaire_par_spec.rb

tests_par_fj_cyc:
	MODE=par_fj_cyc ruby systeme_planetaire_par_spec.rb

tests_par_sta:
	MODE=par_sta ruby systeme_planetaire_par_spec.rb

tests_par_dyn:
	MODE=par_dyn ruby systeme_planetaire_par_spec.rb

# Tests pour toutes les versions paralleles.
tests_par: tests_par_fj_fin tests_par_fj_adj tests_par_fj_cyc tests_par_sta tests_par_dyn


# Tests pour la classe Planete.
tests_planete:
	ruby planete_spec.rb

# Tests pour tout!
tests tests_all: tests_planete tests_seq tests_par

##################################
# Simulation graphique.
##################################

SYSTEME=terre_lune

afficher:
	SYSTEME=$(SYSTEME) rp5 run afficher_systeme_planetaire.rb


##############################################################
# Mesures des temps d'execution et generation des graphes.
##############################################################

temps_%: 
	NB_PLANETES=$* ruby mesurer_temps.rb >fichier_temps_$*.txt

.SECONDARY: fichier_temps_5.txt fichier_temps_10.txt fichier_temps_50.txt fichier_temps_100.txt fichier_temps_150.txt

fichier_temps_%.txt: systeme_planetaire.rb
	NB_PLANETES=$* ruby mesurer_temps.rb >fichier_temps_$*.txt

acc_%: fichier_temps_%.txt
	ruby calculer_accelerations.rb <fichier_temps_$*.txt

#
# REMARQUE: Si votre acceleration depasse 6 (!?), il faut modifier la
# constante qui suit pour avoir un graphique qui remplit mieux la page
# (et non pas une courbe trop 'ecrasee').
#
# Exemple si votre acceleration ne depasse pas 4:
#   $ make graphes_100 MAX_ACC=4
#
MAX_ACC=6

graphes_%: fichier_temps_%.txt
	./gnuplot-temps.sh $*
	./gnuplot-acc.sh $* $(MAX_ACC)

########################################################################
########################################################################

BOITE=INF5171

remise:
	PWD=$(shell pwd)
	ssh oto.labunix.uqam.ca oto rendre_tp tremblay_gu $(BOITE) $(CODES_PERMANENTS) $(PWD)/$(FICHIERS_A_REMETTRE)
	ssh oto.labunix.uqam.ca oto confirmer_remise tremblay_gu $(BOITE) $(CODES_PERMANENTS)

