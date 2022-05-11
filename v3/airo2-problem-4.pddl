(define (problem airo2_group_K_problem_1)   
	(:domain airo2_group_k_domain)
    
	(:objects 
		mover1 mover2 - mover ; move the crates
		loader1 loader2 - loader ; load the crates
		crate1 crate2 crate3 crate4 crate5 crate6 - crate ; crates to move
		group1 group2 - group ; groups
        loading_bay - location ; locations
	)

	(:init
        (mover mover1) (mover mover2)
        (loader loader1) (loader loader2)
        (crate crate1) (crate crate2) (crate crate3)
        (crate crate4) (crate crate5) (crate crate6)
        (group group1) (group group2)
        (location loading_bay)

        (is_empty mover1) (is_empty mover2) 
        (is_empty loader1)
        (is_empty loading_bay)

		(loader_free loader1) (loader_free loader2)
		(strong_loader loader2)
        
        (belongs_to crate1 group1)
        (belongs_to crate2 group1)
        (belongs_to crate3 group2)
        (belongs_to crate4 group2)
        (belongs_to crate5 group2)
        (belongs_to crate6 group1)

        (active_group group1)

        (= (timer_loading_crate loader1) 0)
		(= (timer_loading_crate loader2) 0)

        ; Fragile (or not) crates
		(= (fl-fragile-crate crate1) 0) 
		(= (fl-fragile-crate crate2) 1)  
		(= (fl-fragile-crate crate3) 1) 
        (= (fl-fragile-crate crate4) 1) 
		(= (fl-fragile-crate crate5) 1)  
		(= (fl-fragile-crate crate6) 0) 

        ; Crates' weight
		(= (weight_crate crate1) 30) 
        (= (weight_crate crate2) 20)
        (= (weight_crate crate3) 30)
        (= (weight_crate crate4) 20) 
        (= (weight_crate crate5) 30)
        (= (weight_crate crate6) 20)

        ; Groups counter
        (= (counter_group group1) 3)
        (= (counter_group group2) 3)

        ; Distances between crates and loading bay
        (= (distance_cl crate1) 20)
        (= (distance_cl crate2) 20)
        (= (distance_cl crate3) 10)
        (= (distance_cl crate4) 20)
        (= (distance_cl crate5) 30)
        (= (distance_cl crate6) 10)

        ; Initialization timer
        (= (timer mover1) 0) 
        (= (timer mover2) 0)
        
		; Distances between crates and movers
        (= (distance_cm mover1) 1)
        (= (distance_cm mover2) 1)
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