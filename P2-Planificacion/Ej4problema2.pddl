(define (problem Belkan-test1)
  (:domain Belkan-domain)
  (:objects ; zones
            ; normal zones
            zone1_1 zone1_2 zone1_3 zone1_4 zone1_5 - normal_zone
            zone3_1 zone3_2 zone3_3 zone3_4 zone3_5 - normal_zone
            zone5_1 zone5_2 zone5_3 zone5_4 zone5_5 - normal_zone

            ; special_zones
            zone2_4 zone4_2 - bosque
            zone2_5 zone4_1 - agua

            ; impassable zones
            zone2_1 zone2_2 zone2_3 zone4_3 zone4_4 zone4_5 - precipicio

            ; players
            player1 - player

            ; characters
            princess prince witch leonardo professor - character

            ; items
            apple1 apple2 oscar algorithm1 algorithm2 rose gold1 gold2 - deliverable_item
            zapatilla1 zapatilla2 zapatilla3 - zapatilla
            bikini1 bikini2 bikini3 - bikini

            ; orientations
            north south east west - orientation
    )

  	(:init

      ; zones
      ; zone1 - south
      (connected south zone1_1 zone2_1) (= (cost zone1_1 zone2_1) 10)
      (connected south zone1_2 zone2_2) (= (cost zone1_2 zone2_2)  5)
      (connected south zone1_3 zone2_3) (= (cost zone1_3 zone2_3) 20)
      (connected south zone1_4 zone2_4) (= (cost zone1_4 zone2_4) 15)
      (connected south zone1_5 zone2_5) (= (cost zone1_5 zone2_5) 10)

      ; zone1 - west
      (connected west zone1_2 zone1_1) (= (cost zone1_2 zone1_1) 20)
      (connected west zone1_3 zone1_2) (= (cost zone1_3 zone1_2) 15)
      (connected west zone1_4 zone1_3) (= (cost zone1_4 zone1_3) 5)
      (connected west zone1_5 zone1_4) (= (cost zone1_5 zone1_4) 10)

      ; zone1 - east
      (connected east zone1_1 zone1_2) (= (cost zone1_1 zone1_2) 10)
      (connected east zone1_2 zone1_3) (= (cost zone1_2 zone1_3) 10)
      (connected east zone1_3 zone1_4) (= (cost zone1_3 zone1_4) 15)
      (connected east zone1_4 zone1_5) (= (cost zone1_4 zone1_5) 5)

      ; zone2 - south
      (connected south zone2_1 zone3_1) (= (cost zone2_1 zone3_1) 5)
      (connected south zone2_2 zone3_2) (= (cost zone2_2 zone3_2) 15)
      (connected south zone2_3 zone3_3) (= (cost zone2_3 zone3_3) 20)
      (connected south zone2_4 zone3_4) (= (cost zone2_4 zone3_4) 20)
      (connected south zone2_5 zone3_5) (= (cost zone2_5 zone3_5) 5)

      ; zone2 - north
      (connected north zone2_1 zone1_1) (= (cost zone2_1 zone1_1) 15)
      (connected north zone2_2 zone1_2) (= (cost zone2_2 zone1_2) 15)
      (connected north zone2_3 zone1_3) (= (cost zone2_3 zone1_3) 5)
      (connected north zone2_4 zone1_4) (= (cost zone2_4 zone1_4) 15)
      (connected north zone2_5 zone1_5) (= (cost zone2_5 zone1_5) 20)

      ; zone2 - west
      (connected west zone2_2 zone2_1) (= (cost zone2_2 zone2_1) 20)
      (connected west zone2_3 zone2_2) (= (cost zone2_3 zone2_2) 10)
      (connected west zone2_4 zone2_3) (= (cost zone2_4 zone2_3) 5)
      (connected west zone2_5 zone2_4) (= (cost zone2_5 zone2_4) 10)

      ; zone2 - east
      (connected east zone2_1 zone2_2) (= (cost zone2_1 zone2_2) 10)
      (connected east zone2_2 zone2_3) (= (cost zone2_2 zone2_3) 5)
      (connected east zone2_3 zone2_4) (= (cost zone2_3 zone2_4) 10)
      (connected east zone2_4 zone2_5) (= (cost zone2_4 zone2_5) 20)

      ; zone3 - south
      (connected south zone3_1 zone4_1) (= (cost zone3_1 zone4_1) 10)
      (connected south zone3_2 zone4_2) (= (cost zone3_2 zone4_2) 10)
      (connected south zone3_3 zone4_3) (= (cost zone3_3 zone4_3) 10)
      (connected south zone3_4 zone4_4) (= (cost zone3_4 zone4_4) 10)
      (connected south zone3_5 zone4_5) (= (cost zone3_5 zone4_5) 10)

      ; zone3 - north
      (connected north zone3_1 zone2_1) (= (cost zone3_1 zone2_1) 5)
      (connected north zone3_2 zone2_2) (= (cost zone3_2 zone2_2) 20)
      (connected north zone3_3 zone2_3) (= (cost zone3_3 zone2_3) 15)
      (connected north zone3_4 zone2_4) (= (cost zone3_4 zone2_4) 10)
      (connected north zone3_5 zone2_5) (= (cost zone3_5 zone2_5) 5)

      ; zone3 - west
      (connected west zone3_2 zone3_1) (= (cost zone3_2 zone3_1) 15)
      (connected west zone3_3 zone3_2) (= (cost zone3_3 zone3_2) 10)
      (connected west zone3_4 zone3_3) (= (cost zone3_4 zone3_3) 15)
      (connected west zone3_5 zone3_4) (= (cost zone3_5 zone3_4) 5)

      ; zone3 - east
      (connected east zone3_1 zone3_2) (= (cost zone3_1 zone3_2) 20)
      (connected east zone3_2 zone3_3) (= (cost zone3_2 zone3_3) 10)
      (connected east zone3_3 zone3_4) (= (cost zone3_3 zone3_4) 10)
      (connected east zone3_4 zone3_5) (= (cost zone3_4 zone3_5) 5)

      ; zone4 - south
      (connected south zone4_1 zone5_1) (= (cost zone4_1 zone5_1) 5)
      (connected south zone4_2 zone5_2) (= (cost zone4_2 zone5_2) 20)
      (connected south zone4_3 zone5_3) (= (cost zone4_3 zone5_3) 5)
      (connected south zone4_4 zone5_4) (= (cost zone4_4 zone5_4) 5)
      (connected south zone4_5 zone5_5) (= (cost zone4_5 zone5_5) 20)

      ; zone4 - north
      (connected north zone4_1 zone3_1) (= (cost zone4_1 zone3_1) 5)
      (connected north zone4_2 zone3_2) (= (cost zone4_2 zone3_2) 15)
      (connected north zone4_3 zone3_3) (= (cost zone4_3 zone3_3) 15)
      (connected north zone4_4 zone3_4) (= (cost zone4_4 zone3_4) 5)
      (connected north zone4_5 zone3_5) (= (cost zone4_5 zone3_5) 10)

      ; zone4 - west
      (connected west zone4_2 zone4_1) (= (cost zone4_2 zone4_1) 15)
      (connected west zone4_3 zone4_2) (= (cost zone4_3 zone4_2) 15)
      (connected west zone4_4 zone4_3) (= (cost zone4_4 zone4_3) 5)
      (connected west zone4_5 zone4_4) (= (cost zone4_5 zone4_4) 15)

      ; zone4 - east
      (connected east zone4_1 zone4_2) (= (cost zone4_1 zone4_2) 10)
      (connected east zone4_2 zone4_3) (= (cost zone4_2 zone4_3) 5)
      (connected east zone4_3 zone4_4) (= (cost zone4_3 zone4_4) 20)
      (connected east zone4_4 zone4_5) (= (cost zone4_4 zone4_5) 20)

      ; zone5 - south
      (connected north zone5_1 zone4_1) (= (cost zone5_1 zone4_1) 5)
      (connected north zone5_2 zone4_2) (= (cost zone5_2 zone4_2) 15)
      (connected north zone5_3 zone4_3) (= (cost zone5_3 zone4_3) 20)
      (connected north zone5_4 zone4_4) (= (cost zone5_4 zone4_4) 10)
      (connected north zone5_5 zone4_5) (= (cost zone5_5 zone4_5) 20)

      ; zone5 - west
      (connected west zone5_2 zone5_1) (= (cost zone5_2 zone5_1) 5)
      (connected west zone5_3 zone5_2) (= (cost zone5_3 zone5_2) 5)
      (connected west zone5_4 zone5_3) (= (cost zone5_4 zone5_3) 5)
      (connected west zone5_5 zone5_4) (= (cost zone5_5 zone5_4) 5)

      ; zone5 - east
      (connected east zone5_1 zone5_2) (= (cost zone5_1 zone5_2) 15)
      (connected east zone5_2 zone5_3) (= (cost zone5_2 zone5_3) 5)
      (connected east zone5_3 zone5_4) (= (cost zone5_3 zone5_4) 20)
      (connected east zone5_4 zone5_5) (= (cost zone5_4 zone5_5) 5)

      ; characters
      (emptyhand princess)
      (emptyhand prince)
      (emptyhand witch)
      (emptyhand leonardo)
      (emptyhand professor)

      (at princess zone1_1)
      (at prince zone5_3)
      (at professor zone2_5)
      (at witch zone3_1)
      (at leonardo zone5_3)

      ; players
      (at player1 zone5_2)
      (oriented player1 north)
      (emptyhand player1)
      (emptybag player1)
      (= (total-cost player1) 0)
      (= (total-points player1) 0)

      ; items
      (is-apple apple1)
      (is-apple apple2)
      (is-oscar oscar)
      (is-algorithm algorithm1)
      (is-algorithm algorithm2)
      (is-rose rose)
      (is-gold gold1)
      (is-gold gold2)

      (at apple1 zone1_5)
      (at apple2 zone4_2)
      (at oscar zone5_4)
      (at algorithm1 zone3_5)
      (at algorithm2 zone5_5)
      (at rose zone1_1)
      (at gold1 zone1_3)
      (at gold2 zone5_1)
      (at zapatilla1 zone3_2)
      (at zapatilla2 zone4_1)
      (at zapatilla3 zone1_4)
      (at bikini1 zone2_4)
      (at bikini2 zone5_5)
      (at bikini3 zone1_4)

      (= (points-oscar leonardo)  10)
      (= (points-oscar princess)  5)
      (= (points-oscar witch)     4)
      (= (points-oscar professor) 3)
      (= (points-oscar prince)    1)

      (= (points-rose leonardo)  1)
      (= (points-rose princess)  10)
      (= (points-rose witch)     5)
      (= (points-rose professor) 4)
      (= (points-rose prince)    3)

      (= (points-apple leonardo)  3)
      (= (points-apple princess)  1)
      (= (points-apple witch)     10)
      (= (points-apple professor) 5)
      (= (points-apple prince)    4)

      (= (points-algorithm leonardo)  4)
      (= (points-algorithm princess)  3)
      (= (points-algorithm witch)     1)
      (= (points-algorithm professor) 10)
      (= (points-algorithm prince)    5)

      (= (points-gold leonardo)  5)
      (= (points-gold princess)  4)
      (= (points-gold witch)     3)
      (= (points-gold professor) 1)
      (= (points-gold prince)    10)

	)

  (:goal (and (>= (total-points player1) 66)
         (<= (total-cost player1) 500))
  )
)
