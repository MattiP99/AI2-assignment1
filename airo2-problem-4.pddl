(define (problem airo2_group_K_problem_1)   
	(:domain airo2_group_k_domain)
    
	(:objects 
		mover1 mover2 - obj ; move the crates
        loader1 - obj ; load the crates
        crate1 crate2 crate3 crate4 crate5 crate6 - obj ; crates to move
        loading_bay - obj ; locations
	)

	(:init
        (mover mover1) (mover mover2)
        (loader loader1)
        (crate crate1) (crate crate2) (crate crate3) (crate crate4) (crate crate5) (crate crate6)
        (location loading_bay)
        (is_empty mover1) (is_empty mover2) (is_empty loader1)
        (is_empty loading_bay)

        ; Crates' weight
		(= (weight_crate crate1) 30) 
        (= (weight_crate crate2) 20)
        (= (weight_crate crate3) 30)
        (= (weight_crate crate4) 20) 
        (= (weight_crate crate5) 30)
        (= (weight_crate crate6) 20)
        
        ; Initialization timer
        (= (timer mover1) 0) 
        (= (timer mover2) 0)
        (= (timer loader1) 0)

        ; Distances between crates and loading bay
        (= (distance_cl crate1 loading_bay) 20)
        (= (distance_cl crate2 loading_bay) 20)
        (= (distance_cl crate3 loading_bay) 10)
        (= (distance_cl crate4 loading_bay) 20)
        (= (distance_cl crate5 loading_bay) 30)
        (= (distance_cl crate6 loading_bay) 10)

		; Distances between crates and movers
        (= (distance_cr crate1 mover1) 20)
        (= (distance_cr crate2 mover1) 20)
        (= (distance_cr crate3 mover1) 10)
        (= (distance_cr crate4 mover1) 20)
        (= (distance_cr crate5 mover1) 30)
        (= (distance_cr crate6 mover1) 10)

        (= (distance_cr crate1 mover2) 20)
        (= (distance_cr crate2 mover2) 20)
        (= (distance_cr crate3 mover2) 10)
        (= (distance_cr crate4 mover2) 20)
        (= (distance_cr crate5 mover2) 30)
        (= (distance_cr crate6 mover2) 10)
	)

	(:goal
		(and 
			(at_location crate1)
            (at_location crate2)
            (at_location crate3)
            (at_location crate4)
            (at_location crate5)
            (at_location crate6)
		)
	)
)