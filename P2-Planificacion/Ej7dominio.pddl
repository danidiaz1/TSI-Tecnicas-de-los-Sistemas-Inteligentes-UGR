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
    item player character - locatable

    ; players
    character-interactive - player ; player that can only deliver items to characters,
                           ; leave items on the floor and receive items from other players
    floor-interactive - player ; player that can only take items from/leave items on the floor and
                          ; deliver them to other players

    ; items
    special_item deliverable_item - item
    zapatilla bikini - special_item
  )

  (:predicates

	    (oriented ?p - player ?o - orientation)
	    (at ?l - locatable ?z - passable_zone)

      ; bag
      (has-in-bag ?p - player ?i - item)
      (emptybag ?p - player)

      ; hand
      (has-in-hand ?p - player ?i - item) ; player has item in hand
      (emptyhand ?p - player)

      ; zone
      (connected ?o - orientation ?z1 ?z2 - zone) ; you can go from ?z1 to ?z2 via ?o
                                                    ; or from ?z1, at ?o, it is ?z2

      ; items
      (is-apple ?i - deliverable_item)
      (is-oscar ?i - deliverable_item)
      (is-algorithm ?i - deliverable_item)
      (is-rose ?i - deliverable_item)
      (is-gold ?i - deliverable_item)

  )

  (:functions
    (cost ?z1 ?z2 - zone) ; cost of going from z1 to z2
    (total-cost ?p - player) ; total cost of distance traveled by player p

    (points-apple     ?c - character)
    (points-algorithm ?c - character)
    (points-oscar     ?c - character)
    (points-rose      ?c - character)
    (points-gold      ?c - character)

    (total-points ?p - character-interactive) ; total delivery points of player p

    (max-items ?c - character) ; max number of items holded by a character
    (total-items ?c - character) ; total items holded by character c
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

  (:action TAKE-ITEM-FLOOR
    :parameters (?p - floor-interactive ?i - item ?z - passable_zone)
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

  (:action DELIVER-ITEM-TO-PLAYER
    :parameters (?p1 - floor-interactive ?p2 - character-interactive ?i - item ?z - passable_zone)
    :precondition (and (at ?p1 ?z)
                       (at ?p2 ?z)
                       (not (emptyhand ?p1))
                       (has-in-hand ?p1 ?i)
                       (emptyhand ?p2)
                       (not (has-in-hand ?p2 ?i))
                  )
    :effect (and (emptyhand ?p1)
                (not (emptyhand ?p2))
                (not (has-in-hand ?p1 ?i))
                (has-in-hand ?p2 ?i)
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

  (:action DELIVER-ITEM-TO-CHARACTER
    :parameters (?p - character-interactive ?i - deliverable_item ?c - character ?z - passable_zone)
  	:precondition (and (at ?p ?z)
                      (at ?c ?z)
                      (has-in-hand ?p ?i)
                      (not (emptyhand ?p))
                      (< (total-items ?c) (max-items ?c))
                  )
  	:effect (and (not (has-in-hand ?p ?i))
                 (emptyhand ?p)
                 (increase (total-items ?c) 1)
                 (when (is-oscar ?i)
                    (increase (total-points ?p) (points-oscar ?c)))
                 (when (is-algorithm ?i)
                    (increase (total-points ?p) (points-algorithm ?c)))
                 (when (is-rose ?i)
                    (increase (total-points ?p) (points-rose ?c)))
                 (when (is-gold ?i)
                    (increase (total-points ?p) (points-gold ?c)))
                 (when (is-apple ?i)
                    (increase (total-points ?p) (points-apple ?c)))
            )
  )
)
