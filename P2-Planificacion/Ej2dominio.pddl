(define (domain Belkan-domain)	       ; Comment: adding location caused fail
  (:requirements :strips :equality :typing :fluents)
  (:types locatable zone orientation - object
    item actor - locatable
    player character - actor
  )

  (:predicates
	       (connected ?o - orientation ?z1 ?z2 - zone) ; you can go from ?z1 to ?z2 via ?o
                                                    ; or from ?z1, at ?o, it is ?z2
	       (oriented ?p - player ?o - orientation)
	       (at ?l - locatable ?z - zone)
         (has ?a - actor ?i - item)
         (emptyhand ?a - actor)
  )

  (:functions
    (cost ?z1 ?z2 - zone)
    (total-cost ?p - player)
  )

  (:action TURN-LEFT
     :parameters (?p - player)
     :effect
     (and
          (when (oriented ?p north)
            (and (not (oriented ?p north)) (oriented ?p west) )
          )

          (when (oriented ?p south)
            (and (not (oriented ?p south)) (oriented ?p east) )
          )

          (when (oriented ?p east)
            (and (not (oriented ?p east)) (oriented ?p north) )
          )

          (when (oriented ?p west)
            (and (not (oriented ?p west)) (oriented ?p south) )
          )
     )
  )

  (:action TURN-RIGHT
     :parameters (?p - player)
     :effect
     (and
          (when (oriented ?p north)
            (and (not (oriented ?p north)) (oriented ?p east) )
          )

          (when (oriented ?p south)
            (and (not (oriented ?p south)) (oriented ?p west) )
          )

          (when (oriented ?p east)
            (and (not (oriented ?p east)) (oriented ?p south) )
          )

          (when (oriented ?p west)
            (and (not (oriented ?p west)) (oriented ?p north) )
          )
     )
  )

  (:action GO ; from z1 to z2 connected with orientation ?o
    :parameters (?p - player ?z1 ?z2 - zone ?o - orientation)
    :precondition (and (at ?p ?z1)
                       (connected ?o ?z1 ?z2)
                       (oriented ?p ?o)
                  )
    :effect (and (at ?p ?z2)
                 (not (at ?p ?z1))
                 (increase (total-cost ?p) (cost ?z1 ?z2))
            )
  )

  (:action TAKE-ITEM
    :parameters (?p - player ?i - item ?z - zone)
  	:precondition (and (at ?p ?z) (at ?i ?z) (emptyhand ?p))
  	:effect (and (has ?p ?i)
                 (not (emptyhand ?p))
                 (not (at ?i ?z))
            )
  )

  (:action LEAVE-ITEM
    :parameters (?p - player ?i - item ?z - zone)
  	:precondition (and (at ?p ?z) (not (emptyhand ?p)))
  	:effect (and (not (has ?p ?i))
                 (emptyhand ?p)
                 (at ?i ?z)
            )
  )

  (:action DELIVER-ITEM
    :parameters (?p - player ?i - item ?c - character ?z - zone)
  	:precondition (and (at ?p ?z) (at ?c ?z) (not (emptyhand ?p)) (has ?p ?i))
  	:effect (and (not (has ?p ?i))
                 (emptyhand ?p)
                 (has ?c ?i)
                 (not (emptyhand ?c))
            )
  )
)
