(define (domain Belkan-domain)
  (:requirements :strips :equality :typing :fluents)
  (:types locatable zone orientation - object
    ; zones
    special_zone passable_zone impassable_zone - zone
    special_zone normal_zone - passable_zone
    bosque agua - special_zone
    piedra arena - normal_zone
    precipicio - impassable_zone

    ; locatables
    item actor - locatable

    ; items
    special_item deliverable_item - item
    zapatilla bikini - special_item

    ; actors
    player character - actor
  )

  (:predicates

	    (oriented ?p - player ?o - orientation)
	    (at ?l - locatable ?z - passable_zone)

      ; bag
      (has-in-bag ?p - player ?i - item)
      (emptybag ?p - player)

      ; hand
      (has-in-hand ?a - actor ?i - item) ; actor has item in hand
      (emptyhand ?a - actor)

      ; zone
      (connected ?o - orientation ?z1 ?z2 - zone) ; you can go from ?z1 to ?z2 via ?o
                                                    ; or from ?z1, at ?o, it is ?z2
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

  (:action GO ; normal zones (without special requirements)
    :parameters (?p - player ?z1 - passable_zone ?z2 - normal_zone ?o - orientation)
    :precondition   (and (at ?p ?z1)
                         (connected ?o ?z1 ?z2)
                         (oriented ?p ?o)
                    )
    :effect (and (at ?p ?z2)
                (not (at ?p ?z1))
                (increase (total-cost ?p) (cost ?z1 ?z2))
            )
  )

  (:action GO ; bosque (needs zapatilla)
    :parameters (?p - player ?z1 - passable_zone ?z2 - bosque ?o - orientation ?i - zapatilla)
    :precondition (and (at ?p ?z1)
                       (connected ?o ?z1 ?z2)
                       (oriented ?p ?o)
                       (or (has-in-hand ?p ?i) (has-in-bag ?p ?i))
                  )
    :effect (and (at ?p ?z2)
                 (not (at ?p ?z1))
                 (increase (total-cost ?p) (cost ?z1 ?z2))
            )
  )

  (:action GO ; agua (needs bikini)
    :parameters (?p - player ?z1 - passable_zone ?z2 - agua ?o - orientation ?i - bikini)
    :precondition (and (at ?p ?z1)
                       (connected ?o ?z1 ?z2)
                       (oriented ?p ?o)
                       (or (has-in-hand ?p ?i) (has-in-bag ?p ?i))
                  )
    :effect (and (at ?p ?z2)
                 (not (at ?p ?z1))
                 (increase (total-cost ?p) (cost ?z1 ?z2))
            )
  )

  (:action TAKE-ITEM-HAND
    :parameters (?p - player ?i - item ?z - passable_zone)
  	:precondition (and (at ?p ?z) (at ?i ?z) (emptyhand ?p))
  	:effect (and (has-in-hand ?p ?i)
                 (not (emptyhand ?p))
                 (not (at ?i ?z))
            )
  )

  (:action LEAVE-HAND-ITEM
    :parameters (?p - player ?i - item ?z - passable_zone)
  	:precondition (and (at ?p ?z) (has-in-hand ?p ?i) (not (emptyhand ?p)))
  	:effect (and (not (has-in-hand ?p ?i))
                 (emptyhand ?p)
                 (at ?i ?z)
            )
  )

  (:action PUT-IN-BAG
    :parameters (?p - player ?i - item)
    :precondition (and (not (emptyhand ?p))
                       (has-in-hand ?p ?i)
                       (emptybag ?p)
                  )
    :effect (and (has-in-bag ?p ?i)
                 (not (emptybag ?p))
                 (emptyhand ?p)
                 (not (has-in-hand ?p ?i))
    )
  )

  (:action TAKE-BAG-ITEM ; take out bag's item into player's hand
    :parameters (?p - player ?i - item)
    :precondition (and (not (emptybag ?p))
                       (has-in-bag ?p ?i)
                       (emptyhand ?p)
                  )
    :effect (and (has-in-hand ?p ?i)
                 (not (emptyhand ?p))
                 (emptybag ?p)
                 (not (has-in-bag ?p ?i))
            )
  )

  (:action DELIVER-ITEM
    :parameters (?p - player ?i - deliverable_item ?c - character ?z - passable_zone)
  	:precondition (and (at ?p ?z) (at ?c ?z) (has-in-hand ?p ?i))
  	:effect (and (not (has-in-hand ?p ?i))
                 (emptyhand ?p)
                 (has-in-hand ?c ?i)
                 (not (emptyhand ?c))
            )
  )
)
