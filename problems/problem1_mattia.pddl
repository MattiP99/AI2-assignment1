(define (problem airo2_group_k_problem1)   
	(:domain airo2_group_k_domain)
    
	(:objects 
		mover1 mover2 - mover 
        	loader1 loader2 - loader 
        	loader2 - strong_loader
        	loading_bay - location
        	crate1 crate2 crate3 - crate 
        
	)

	(:init
        	(not(mover_busy mover1)) 
        	(not(mover_busy mover2))
        
        	(not(mover_need_help crate1 mover1))
        	(not(mover_need_help crate2 mover1))
        	(not(mover_need_help crate3 mover1))
        
        	(not(mover_need_help crate1 mover2))
        	(not(mover_need_help crate2 mover2))
        	(not(mover_need_help crate3 mover2))
        	
        	(not(equal mover1 mover2))
        	(not(equal mover2 mover1))
        
        
        
        	(loader_free loader1) 
        	(loader_free loader2)

        
		; Crates' weight
		(= (weight_crate crate1) 70) 
        	(= (weight_crate crate2) 20)
        	(= (weight_crate crate3) 20)
	
		(= (fl-fragile-crate crate1) 0)
		(= (fl-fragile-crate crate2) 1)
		(= (fl-fragile-crate crate3) 0)
		
		(not (at-destination-crate crate1))
        	(not(at-destination-crate crate2))
        	(not(at-destination-crate crate3))
        	
        	(different_crate crate1 crate2) (different_crate crate1 crate2)
        	(different_crate crate1 crate3) (different_crate crate3 crate1)
        	(different_crate crate2 crate3) (different_crate crate3 crate2)
        
        	; Initialization timer
        	(= (timer_approaching_crate mover1) 0) 
        	(= (timer_approaching_crate mover2) 0) 
        
        	(= (timer_bringing_crate mover1) 0) 
        	(= (timer_bringing_crate mover2) 0)
        
        	(= (timer_waiting_for_free_loadingbay mover1) 0)
        	(= (timer_waiting_for_free_loadingbay mover2) 0)
        
        	(= (timer_loading_crate loader1) 0) 
        	(= (timer_loading_crate loader2) 0)

        	; Distances between crates and loading bay
        	(= (distance_cl crate1) 10)
        	(= (distance_cl crate2) 20)
        	(= (distance_cl crate3) 20)

		(= (loading_has_crate laoding_bay) 0)
	
		; Battery Level
		
		(= (battery_level mover1) 20) 
		(= (battery_level mover2) 20)
	)
	

	(:goal
		(and 
	    (at-destination-crate crate1)
            (at-destination-crate crate2)
            (at-destination-crate crate3)
            )
            )
       (:metric minimize #t)
  )
