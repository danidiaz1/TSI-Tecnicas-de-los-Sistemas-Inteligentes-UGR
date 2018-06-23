(define (domain zeno-travel)


(:requirements
  :typing
  :fluents
  :derived-predicates
  :negative-preconditions
  :universal-preconditions
  :disjuntive-preconditions
  :conditional-effects
  :htn-expansion

  ; Requisitos adicionales para el manejo del tiempo
  :durative-actions
  :metatags
 )

(:types aircraft person city - object)
(:predicates (at ?x - (either person aircraft) ?c - city)
             (in ?p - person ?a - aircraft)
             (destino ?p - person ?c - city)
             (different ?x ?y) (igual ?x ?y)
             (hay-fuel-vuelo-rapido ?a - aircraft ?c1 - city ?c2 - city)
             (no-supero-limite-vuelo-rapido ?a - aircraft ?c1 - city ?c2 - city)
             (hay-fuel-vuelo-lento ?a - aircraft ?c1 - city ?c2 - city)
             (no-supero-limite-vuelo-lento ?a - aircraft ?c1 - city ?c2 - city)
             (no-supero-duracion-vuelo-rapido ?a - aircraft ?c1 - city ?c2 - city)
             (no-supero-duracion-vuelo-lento ?a - aircraft ?c1 - city ?c2 - city)
)
(:functions (fuel ?a - aircraft)
            (distance ?c1 - city ?c2 - city)
            (slow-speed ?a - aircraft)
            (fast-speed ?a - aircraft)
            (slow-burn ?a - aircraft)
            (fast-burn ?a - aircraft)
            (capacity ?a - aircraft)
            (refuel-rate ?a - aircraft)
            (total-fuel-used ?a - aircraft)
            (boarding-time)
            (debarking-time)
            (fuel-limit ?a - aircraft)
            (passengers-aboard ?a - aircraft)
            (max-passengers ?a - aircraft)
            (max-duration ?a - aircraft)
)

;; el consecuente "vacío" se representa como "()" y significa "siempre verdad"
(:derived
  (igual ?x ?x) ()
)

(:derived
  (different ?x ?y) (not (igual ?x ?y))
)

;comprueba si tiene fuel para ir de c1 a c2 mediante vuelo rápido
(:derived
  (hay-fuel-vuelo-rapido ?a - aircraft ?c1 - city ?c2 - city)
  (>= (fuel ?a) (* (distance ?c1 ?c2) (fast-burn ?a)))
)

;comprueba si tiene fuel para ir de c1 a c2 mediante vuelo lento
(:derived
  (hay-fuel-vuelo-lento ?a - aircraft ?c1 - city ?c2 - city)
  (>= (fuel ?a) (* (distance ?c1 ?c2) (slow-burn ?a)))
)

;comprueba si el avión no supera el límite total de fuel consumido si fuese
;de una ciudad a otra mediante vuelo rápido
(:derived
  (no-supero-limite-vuelo-rapido ?a - aircraft ?c1 - city ?c2 - city)
  (<= (+ (total-fuel-used ?a)
        (* (distance ?c1 ?c2) (fast-burn ?a))
     )
     (fuel-limit ?a)
  )
)

;comprueba si el avión no supera el límite total de fuel consumido si fuese
;de una ciudad a otra mediante vuelo lento
(:derived
  (no-supero-limite-vuelo-lento ?a - aircraft ?c1 - city ?c2 - city)
  (<= (+ (total-fuel-used ?a)
        (* (distance ?c1 ?c2) (slow-burn ?a))
     )
     (fuel-limit ?a)
  )
)

;comprueba si el avión no supera el límite de duración al ir de c1 a c2
; en vuelo rapido
(:derived
  (no-supero-duracion-vuelo-rapido ?a - aircraft ?c1 - city ?c2 - city)
   (<= (/ (distance ?c1 ?c2) (fast-speed ?a)) (max-duration ?a))
)

;comprueba si el avión no supera el límite de duración al ir de c1 a c2
;en vuelo lento
(:derived
  (no-supero-duracion-vuelo-lento ?a - aircraft ?c1 - city ?c2 - city)
   (<= (/ (distance ?c1 ?c2) (slow-speed ?a)) (max-duration ?a))
)

(:task transport-person
	:parameters (?p - person ?c - city)

  (:method Case1 ; si la persona est� en la ciudad no se hace nada
	 :precondition (at ?p ?c)
	 :tasks ()
  )


   (:method Case2 ;si no est� en la ciudad destino, pero avion y persona est�n en la misma ciudad
	  :precondition (and (at ?p - person ?c1 - city)
			                 (at ?a - aircraft ?c1 - city)
                  )

	  :tasks (
	  	      (board-multiple ?a ?c1)
		        (mover-avion ?a ?c1 ?c)
		        (debark-multiple ?a ?c)
           )
    )

    (:method Case3 ;si avión y persona están en ciudades diferentes
 	  :precondition (and (at ?p - person ?c1 - city)
 			                 (at ?a - aircraft ?c2 - city)
                       (different ?c1 ?c2)
                  )
 	  :tasks (
            (mover-avion ?a ?c2 ?c1)
 	  	      (board-multiple ?a ?c1)
 		        (mover-avion ?a ?c1 ?c)
 		        (debark-multiple ?a ?c)
           )
    )
	)

(:task mover-avion
 :parameters (?a - aircraft ?c1 - city ?c2 -city)

 (:method fuel-suficiente-vuelo-rapido
  :precondition (and (hay-fuel-vuelo-rapido ?a ?c1 ?c2)
                     (no-supero-limite-vuelo-rapido ?a ?c1 ?c2)
                     (no-supero-duracion-vuelo-rapido ?a ?c1 ?c2)
                )
  :tasks (zoom ?a ?c1 ?c2)
 )

 (:method fuel-insuficiente-vuelo-rapido
  :precondition (and (not (hay-fuel-vuelo-rapido ?a ?c1 ?c2))
                     (no-supero-limite-vuelo-rapido ?a ?c1 ?c2)
                     (no-supero-duracion-vuelo-rapido ?a ?c1 ?c2)
                )
  :tasks (
          (refuel ?a ?c1)
          (zoom ?a ?c1 ?c2)
         )
  )

  (:method fuel-suficiente-vuelo-lento
   :precondition (and (hay-fuel-vuelo-lento ?a ?c1 ?c2)
                      (no-supero-limite-vuelo-lento ?a ?c1 ?c2)
                      (no-supero-duracion-vuelo-lento ?a ?c1 ?c2)
                 )
   :tasks (fly ?a ?c1 ?c2)
  )

  (:method fuel-insuficiente-vuelo-lento
   :precondition (and (not (hay-fuel-vuelo-lento ?a ?c1 ?c2))
                      (no-supero-limite-vuelo-lento ?a ?c1 ?c2)
                      (no-supero-duracion-vuelo-lento ?a ?c1 ?c2)
                 )
   :tasks (
           (refuel ?a ?c1)
           (fly ?a ?c1 ?c2)
          )
   )
)

(:task board-multiple
 :parameters (?a - aircraft ?c - city)

 (:method recurre1-board
  :precondition (and (at ?p ?c) ;persona en ciudad
                     (at ?a ?c) ;avion en misma ciudad
                     (not (destino ?p ?c)) ;el destino de la persona no es la propia ciudad
                     (< (passengers-aboard ?a) (max-passengers ?a)) ;hay sitio en el avión
                )
  :tasks (
          (board ?p ?a ?c)
          (board-multiple ?a ?c)
         )
 )

 (:method caso-base-board
   :precondition()
   :tasks()
 )
)

(:task debark-multiple
 :parameters (?a - aircraft ?c - city)

 (:method recurre1-debark
  :precondition (and (at ?a ?c) ;avión en ciudad
                     (in ?p ?a) ;persona en avión
                     (destino ?p ?c) ;el destino de la persona es la propia ciudad
                )
  :tasks (
          (debark ?p ?a ?c)
          (debark-multiple ?a - aircraft ?c - city)
         )
 )

 (:method caso-base-debark
   :precondition()
   :tasks()
 )
)

(:import "Primitivas-Zenotravel.pddl")
)
