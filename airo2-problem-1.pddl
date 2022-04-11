(define (problem airo2_group_K_problem_1)   
	(:domain airo2_group_k_domain)
    
	(:objects 
		mover1 mover2 - obj ; move the crates
        loader1 - obj ; load the crates
        crate1 crate2 crate3 - obj ; crates to move
        loading_bay conveyor_belt - obj ; locations
	)

	(:init
        (mover mover1) (mover mover2)
        (loader loader1)
        (crate crate1) (crate crate2) (crate crate3)
        (location loading_bay) (location conveyor_belt)
        (empty mover1) (empty mover2) (empty loader1)
        (empty loading_bay)
        
        ; Crates' weight
		(= (weight_crate crate1) 70) 
        (= (weight_crate crate2) 20)
        (= (weight_crate crate3) 20)
        
        (= (timer) 0) ; initialization timer

        ; Distances between crates and loading bay
        (= (distance_cl crate1 loading_bay) 10)
        (= (distance_cl crate2 loading_bay) 20)
        (= (distance_cl crate3 loading_bay) 20)

		; Distances between crates and movers
        (= (distance_cr crate1 mover1) 10)
        (= (distance_cr crate2 mover1) 20)
        (= (distance_cr crate3 mover1) 20)

        (= (distance_cr crate1 mover2) 10)
        (= (distance_cr crate2 mover2) 20)
        (= (distance_cr crate3 mover2) 20)
	)

	(:goal
		(and 
			(at_location crate1)
            (at_location crate2)
            (at_location crate3)
		)
	)
)