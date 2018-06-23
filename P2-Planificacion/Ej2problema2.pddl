(define (problem Belkan-test1)
    (:domain Belkan-domain)
  (:objects zone1_1 zone1_2 zone1_3 zone1_4 zone1_5 - zone
            zone2_1 zone2_2 zone2_3 zone2_4 zone2_5 - zone
            zone3_1 zone3_2 zone3_3 zone3_4 zone3_5 - zone
            zone4_1 zone4_2 zone4_3 zone4_4 zone4_5 - zone
            zone5_1 zone5_2 zone5_3 zone5_4 zone5_5 - zone
            player1 - player
            princess prince witch leonardo professor - character
            apple1 apple2 oscar algorithm1 algorithm2 rose gold1 gold2 - item
            north south east west - orientation
            )
  	(:init

      ; zones
      ; zone1 - south
      (connected south zone1_1 zone2_1) (= (cost zone1_1 zone2_1 ) 10)
      (connected south zone1_2 zone2_2) (= (cost zone1_2 zone2_2 )  5)
      (connected south zone1_3 zone2_3) (= (cost zone1_3 zone2_3 ) 20)
      (connected south zone1_4 zone2_4) (= (cost zone1_4 zone2_4 ) 15)
      (connected south zone1_5 zone2_5) (= (cost zone1_5 zone2_5 ) 10)

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
      (at professor zone3_5)
      (at witch zone4_2)
      (at leonardo zone2_4)

      ; players
      (at player1 zone3_3)
      (oriented player1 north)
      (emptyhand player1)
      (= (total-cost player1) 0)

      ; objects
      (at apple1 zone1_1)
      (at apple2 zone5_1)
      (at oscar zone3_2)
      (at algorithm1 zone3_3)
      (at algorithm2 zone3_5)
      (at rose zone2_4)
      (at gold1 zone1_5)
      (at gold2 zone4_1)

	 )
  (:goal (and (not (emptyhand princess))
         (not (emptyhand prince))
         (not (emptyhand witch))
         (not (emptyhand leonardo))
         (not (emptyhand professor))
         (<= (total-cost player1) 150)
  ))
)
