(define (problem airo2_group_K_problem_1)   
	(:domain airo2_group_k_domain)
    
	(:objects 
		mover1 mover2 - obj ; move the crates
        loader1 - obj ; load the crates
        crate1 crate2 crate3 crate4 - obj ; crates to move
        loading_bay - obj ; locations
	)

	(:init
        (mover mover1) (mover mover2)
        (loader loader1)
        (crate crate1) (crate crate2) (crate crate3) (crate crate4)
        (location loading_bay)
        (is_empty mover1) (is_empty mover2) (is_empty loader1)
        (is_empty loading_bay)
        
        (heavy crate1)
        (heavy crate2)

        ; Crates' weight
		(= (weight_crate crate1) 70) 
        (= (weight_crate crate2) 80)
        (= (weight_crate crate3) 20)
        (= (weight_crate crate4) 30)
        
        ; Initialization timer
        (= (timer mover1) 0) 
        (= (timer mover2) 0)
        (= (timer loader1) 0)

        ; Distances between crates and loading bay
        (= (distance_cl crate1 loading_bay) 10)
        (= (distance_cl crate2 loading_bay) 20)
        (= (distance_cl crate3 loading_bay) 20)
        (= (distance_cl crate4 loading_bay) 10)

		; Distances between crates and movers
        (= (distance_cr crate1 mover1) 10)
        (= (distance_cr crate2 mover1) 20)
        (= (distance_cr crate3 mover1) 20)
        (= (distance_cr crate4 mover1) 10)

        (= (distance_cr crate1 mover2) 10)
        (= (distance_cr crate2 mover2) 20)
        (= (distance_cr crate3 mover2) 20)
        (= (distance_cr crate4 mover2) 10)
	)

	(:goal
		(and 
			(at_location crate1)
            (at_location crate2)
            (at_location crate3)
            (at_location crate4)
		)
	)
)