(define (problem airo2_group_k_problem_1)   
	(:domain airo2_group_k_domain)
    
	(:objects 
		mover1 mover2 - mover ; move the crates
		loader1 loader2 - loader ; load the crates
		crate1 crate2 crate3 - crate ; crates to move
        group1 group2 - group ; groups
		loading_bay - location ; locations
	)

	(:init
        (is_empty mover1) (is_empty mover2) 
        (is_empty loader1)
        (is_empty loading_bay)

		(loader_free loader1) (loader_free loader2)
		(strong_loader loader2)

		(heavy crate1)

        (belongs_to crate1 group1)
        (belongs_to crate2 group1)
        (belongs_to crate3 group2)

        (active_group group1)

		(= (timer_loading_crate loader1) 0)
		(= (timer_loading_crate loader2) 0)

		; Fragile (or not) crates
		(= (fl-fragile-crate crate1) 0) 
		(= (fl-fragile-crate crate2) 1)  
		(= (fl-fragile-crate crate3) 0) 
		
		; Crates' weight
		(= (weight_crate crate1) 70) 
        (= (weight_crate crate2) 20)
        (= (weight_crate crate3) 20)
		
		; Groups counter
        (= (counter_group group1) 2)
        (= (counter_group group2) 1)

		; Distances between crates and loading bay
        (= (distance_cl crate1) 10)
        (= (distance_cl crate2) 20)
        (= (distance_cl crate3) 20)
        
        ; Distances at which the crates should be released if too far from the loading bay
        (= (distance_rc crate1) 0)
        (= (distance_rc crate2) 0)
        (= (distance_rc crate3) 0)
        
        
        ; Battery levels
	(= (battery_level mover1) 5)
        (= (battery_level mover2) 5)
		
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
		)
	)
)
