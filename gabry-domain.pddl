(define (domain airo2_group_k_domain)

    (:requirements
       :time
        :typing
        :equality
        :negative-preconditions 
        :disjunctive-preconditions
    )

    (:types
        location crate group - object
        mover loader - robot
        
    )

    (:predicates

    ;++++++++++++++++++++++++++++++ mover predicates ++++++++++++++++++++++++++++++
        (mover ?m - mover)
        (mover_busy ?m - mover) ; robot r is busy 
        (charged ?m - mover)
        (is_pointing ?m - mover) ; the mover is pointing a crate
        (mover_waiting ?m - mover)

    ;++++++++++++++++++++++++++++++ loader predicates +++++++++++++++++++++++++++++
        (loader ?l - loader)
        (strong_loader ?l - loader)
        (weak_loader ?l - loader)
        (loader_free ?l - loader)

    ;++++++++++++++++++++++++++++++ crate predicates ++++++++++++++++++++++++++++++
        (crate ?c - crate) 
        (heavy ?c - crate) ; the crate is heavy
        (on_loading_bay ?c - crate) ; the crate is on the loading bay
        (at_location ?c - crate) ; the crate is on the conveyor bel
        (is_pointed ?c - crate ?r - mover) ; the crate is pointed by the mover/loader

    ;+++++++++++++++++++++++++++++++++++ others +++++++++++++++++++++++++++++++++++
        (crate_light_reached ?c - crate ?m - mover)
        (crate_light_pointed ?c - crate ?m - mover)
        (crate_light_delivering ?c -crate ?m - mover)
        (crate_light_delivered ?c - crate ?m - mover)

        (crate_heavy_reached ?c - crate ?m - mover)
        (crate_heavy_pointed ?c - crate ?m - mover)
        (crate_heavy_delivering ?c -crate ?m - mover)
        (crate_heavy_delivered ?c - crate ?m - mover)
        (loading_bay_reached ?c - crate) ; the crate has reached the loading bay
        (location ?loc - location)
        (is_empty ?loc - location)
        
        
    )

    (:functions
        (weigth_coeff ?c - crate) - number ; light or heavy crate coefficient    

        (weight_crate ?c - crate) - number ; the weight of a certain crate
        (fl-fragile-crate ?c - crate) - number ; this can be 0 or 1 for not fragile or fragile crates respectively
        (distance_crate_loadingbay  ?c - crate) - number ; distance between the crate and the loading bay
        (distance_crate_mover  ?c - crate ?m - mover) - number ; distance between the crate and the mover
        (group_crate ?c - crate ?g - group) - number  ; for the extension concerning groups
        (total_number_crates_of_the_same_group ?g - group) - number  ; I NEED THIS FOR THE GROUP EXTENSION
        
        (battery_level ?m - mover) - number
        (full_battery ?m - mover) - number
        (timer ?r - obj) - number ; timer

        (timer_approaching_crate ?m - mover) - number
        (timer_bringing_crate ?m - mover) - number
        (timer_loading_crate ?c - crate ?l - loader) - number
        (timer_waiting_for_free_loading_bay ?m - mover) - number ; during the problem we want to minimize this --> (:metric minimize (timer_waiting_for_free_loadingbay))

        (loading_has_crate ?l - loading_bay) - number ; counter for light crates on the loading bay
        (distance_cl ?c - crate) - number ; distance between the crate and the loading bay
        (distance_cm ?m - mover) - number ; distance between the crate and the mover
    )

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ MOVER SECTION ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++;

     ;------- POINTING CRATES ------- ;
    
    ; The mover points to a light crate
    (:action pointing_light
        :parameters (?m1 - mover ?m2 - mover ?c - crate)
        :precondition (and (crate ?c) (mover ?m1) (mover ?m2)  
                        ; Movers
                        (not(= ?m1 ?m2)) ; the movers are different
                        (not(mover_busy ?m1)) ; the active mover is empty
                        (not(is_pointing ?m1)) ; the active mover is not pointing anything
                        
                        ; Crate
                        (< (weight_crate ?c) 50);(not(heavy ?c))   the crate is light
                        (not(at_location ?c)) ; the crate is not on the conveyor belt
                        (not(on_loading_bay ?c)) ; the crate has not been loaded on the loading bay
                        (not(is_pointed ?c ?m1)) ; the crate is not pointed by the active mover
                        (or (not(is_pointed ?c ?m2)) ; the other mover is not pointed the crate or
                            (and (is_pointed ?c ?m2) ; it is pointing it and
                            (= (distance_cm ?m2) (distance_cm ?m1)))) ; the distances from the crate are equals 
                        ;(> (battery_level ?m1) (+ (/(distance_cl ?c) 10) (/(*(distance_cl ?c) (weight_crate ?c)) (+ (*(fl-fragile-crate ?c) 50 ) 100))))
        ) 
        :effect (and (is_pointing ?m1) ; the mover is pointing a crate 
                     (is_pointed ?c ?m1) ; the crate is pointed by the active mover
                     (assign (distance_cm ?m1) (distance_cl ?c)) ; the distance between the mover and the crate
                                                                ; is equals to the distance between the crate and the loading bay
        ) 
    )

    ; The movers point a heavy crate 
    (:action pointing_heavy
        :parameters (?m1 - mover ?m2 - mover ?c - crate)
        :precondition (and (crate ?c) (mover ?m1) (mover ?m2)
                            ; Movers
                            (not(= ?m1 ?m2)) ; the movers are different
                            (not(mover_busy ?m1)) (not(mover_busy ?m2)) ; the movers are free
                            (not(is_pointing ?m1)) (not(is_pointing ?m2)) ; the movers are not pointing the crate
                            
                            ; Crate
                            (>= (weight_crate ?c) 50) ;(heavy ?c)  the crate is heavy
                            (not(at_location ?c)) ; the crate is not on the conveyor belt
                            (not(on_loading_bay ?c)) ; the crate is not on the loading bay
                            (not(is_pointed ?c ?m1)) (not(is_pointed ?c ?m2)) ; the crate is not pointed by the movers
                            ;(> (battery_level ?m1) (+ (/(distance_cl ?c) 10) (/(*(distance_cl ?c) (weight_crate ?c)) (+ (*(fl-fragile-crate ?c) 50 ) 100))))
                            ;(> (battery_level ?m2) (+ (/(distance_cl ?c) 10) (/(*(distance_cl ?c) (weight_crate ?c)) (+ (*(fl-fragile-crate ?c) 50 ) 100))))
        ) 
        :effect (and (is_pointing ?m1) (is_pointing ?m2) ; the movers are pointing the crate

            (is_pointed ?c ?m1) (is_pointed ?c ?m2) ; the crate is pointed by the movers 

            ; the distance between the mover and the crate is equals to the distance between the crate and the loading bay
            (assign (distance_cm ?m1) (distance_cl ?c)) (assign (distance_cm ?m2) (distance_cl ?c)) 
        )
    )

    ; ------- MOVER MOTION ------- ;

     ; The mover moves toward the crate 
    (:process move_empty
        :parameters (?m - mover ?c - crate)
        :precondition (and (mover ?m) (crate ?c) 
                            ; Mover
                            (not(crate_light_reached ?c ?m)) (not(crate_heavy_reached ?c ?m)) ; the mover still not reached the crate
                            (charged ?m)
                            ; Crate
                            (is_pointed ?c ?m) ; the crate is pointed by the active mover
        )  
        :effect (and (decrease (distance_cm ?m) (* #t 10.0))
                     (decrease (battery_level ?m) (* #t 1.0))) ; the mover moves against the crate
    )

    ; The robot moves toward the loading bay holding the crate
    (:process move_full
        :parameters (?m - mover ?c - crate)
        :precondition (and (crate ?c) (mover ?m)
            ; Mover
            (or (crate_light_reached ?m) (crate_heavy_reached ?c ?m)) ; the mover reached the crate
            (mover_busy ?m) ; the mover is holding a crate
            ;(> (timer ?m) 0) ; the mover's step is greater than 0
            (charged ?m)
            ; Crate
            (< (weight_crate ?c) 50) ; (not(heavy ?c))  the crate is light
            (is_pointed ?c ?m) ; the crate is pointed by the mover
            (not(loading_bay_reached ?c)) ; the crate still not reached the loading bay
        )
        :effect (and (decrease (timer ?m) (* #t 1.0))
                    (decrease (battery_level ?m) (* #t 1.0)))
        ;(decrease (distance_cl ?c) (* (timer ?m) #t))) ; the distance bewteen crate and loading bay decrease
    )

     ; PROCESS MOVE FULL TOGETHER
    (:process move_full_together
        :parameters (?m1 - mover ?m2 - mover ?c - crate)
        :precondition (and (mover ?m1) (mover ?m2) (crate ?c) 
            ; Movers
            (not(= ?m1 ?m2)) ; the movers are different
            (mover_busy ?m1) (mover_busy ?m2) ; the movers are not free
            (> (timer ?m1) 0.0) (> (timer ?m2) 0.0) ; the movers' step is greater than 0
            (charged ?m1) (charged ?m2)
            
            ; Crate
            (is_pointed ?c ?m1) (is_pointed ?c ?m2) ; the crate is pointed by the movers  
            (not(loading_bay_reached ?c)) ; the crate still not reached the loading bay
        )
        :effect (and (decrease (timer ?m1) (* #t 1.0))
            (decrease (timer ?m2) (* #t 1.0))
            (decrease (battery_level ?m1) (* #t 1.0))
            (decrease (battery_level ?m2) (* #t 1.0))
        )
    )

    ; ------- PICKING UP ------- ;

    ; The mover picks up the light crate
    (:action pick_up
        :parameters (?m1 - mover ?m2 - mover ?c - crate)
        :precondition (and (mover ?m1) (mover ?m2) (crate ?c)
            ; Mover 
            (not(mover_busy ?m1)) ; the mover is empty
            (crate_light_reached ?c ?m1) ; the mover reached the crate
            (not(is_pointed ?c ?m2)) ; the other mover is not pointed the crate

            ; Crate
            (< (weight_crate ?c) 50) ;(not(heavy ?c)) the crate is light
            (is_pointed ?c ?m1) ; the crate is pointed by the mover
        )
        :effect (and (mover_busy ?m1) ; the mover is not empty
            (assign (timer ?m1) (/ (* (distance_cl ?c) (weight_crate ?c)) 100)) ; set the step size 
        )
    )

    ; The movers pick up the heavy crate
    (:action pick_up_together_heavy
        :parameters (?m1 - mover ?m2 - mover ?c - crate)
        :precondition (and (crate ?c) (mover ?m1) (mover ?m2)
            ; Movers
            (not (= ?m1 ?m2)) ; the movers are different
            (not(mover_busy ?m1)) (not(mover_busy ?m2)) ; the movers are free
            (crate_heavy_reached ?c ?m1) (crate_heavy_reached ?c ?m2) ; the movers reached the crate

            ; Crate
            (>= (weight_crate ?c) 50);(heavy ?c) the crate is heavy
            (is_pointed ?c ?m1) (is_pointed ?c ?m2) ; the crate is pointed by the movers
        )
        :effect (and (mover_busy ?m1) (mover_busy ?m2) ; the movers are not free
            (assign (timer ?m1) (/(*(distance_cl ?c) (weight_crate ?c)) (+ (* (fl-fragile-crate ?c) 50) 100 ))); set the step size 
            (assign (timer ?m2) (/ (* (distance_cl ?c) (weight_crate ?c)) (+ (* (fl-fragile-crate ?c) 50) 100 ))) ; set the step size 
        )
    )

    ; The movers pick up the light crate
    (:action pick_up_together_light
        :parameters (?m1 - mover ?m2 - mover ?c - crate)
        :precondition (and (crate ?c) (mover ?m1) (mover ?m2)
            ; Movers
            (not (= ?m1 ?m2)) ; the movers are different
            (not(mover_busy ?m1)) (not(mover_busy ?m2)) ; the movers are free
            (crate_light_reached ?c ?m1) (crate_light_reached ?c ?m2) ; the movers reached the crate

            ; Crate
            (< (weight_crate ?c) 50) ;(not(heavy ?c))  the crate is light
            (is_pointed ?c ?m1) (is_pointed ?c ?m2) ; the crate is pointed by the movers
        )
        :effect (and (mover_busy ?m1) (mover_busy ?m2) ; the movers are not free
            (assign (timer ?m1) (/(*(distance_cl ?c) (weight_crate ?c)) (+ (* (fl-fragile-crate ?c) 50) 100 ))); set the step size 
            (assign (timer ?m2) (/ (* (distance_cl ?c) (weight_crate ?c)) (+ (* (fl-fragile-crate ?c) 50) 100 ))) ; set the step size 
        )
    )

    ; ------- PUTTING DOWN ------- ;

    (:action put_down
        :parameters (?m1 - mover ?m2 - mover ?c - crate ?loc - location ?l1 - loader ?l2 - loader)
        :precondition (and (mover ?m1) (mover ?m2) (crate ?c) (location ?loc) (loader ?l1) (loader ?l2) 
            ; Movers
            (not(= ?m1 ?m2)) ; the movers are different
            (mover_busy ?m1) ; the active mover is holding the crate
            (not(mover_waiting ?m1))
             ; Location
             ; the loading bay is empty and robot is not waiting or robot is waiting
            
            (is_empty ?loc)
            
            ; Loader 
            (or (loader_free ?l1) (loader_free ?l2))  ; the loader is free

            ; Crate
            (< (weight_crate ?c) 50) ;(not(heavy ?c))  the crate is light
            (is_pointed ?c ?m1) ; the crate is pointed by the active mover 
            (not (is_pointed ?c ?m2)) ; the crate is NOT pointed by the other mover
            (loading_bay_reached ?c) ; the crate reached the loading bay

                       
        )
        :effect (and (not(crate_light_reached ?c ?m1)) (not(crate_heavy_reached ?c ?m1)) ; the mover did not reached any crate
            (not(is_pointing ?m1)) ; the mover is not pointing any crate
            (not(mover_busy ?m1)) ; the mover is empty
            (assign (distance_cm ?m1) 1) ; default

            (not(is_pointed ?c ?m1)) ; the crate is not pointed by the active mover 
            (on_loading_bay ?c) ; the crate is on the loading bay

            (not(is_empty ?loc)) ; the location is not empty 
            (assign (timer_waiting_for_free_loading_bay ?m1) 0)
            (not (mover_waiting ?m1))
        )
    )

    ; If the loading bay is free, the movers put down the light/heavy crate
    (:action put_down_together
        :parameters (?m1 - mover ?m2 - mover ?c - crate ?loc - location ?l - loader)
        :precondition (and (mover ?m1) (mover ?m2) (crate ?c) (location ?loc) (loader ?l) (strong_loader ?l)
            ; Movers
            (not(= ?m1 ?m2)) ; the movers are different 
            (mover_busy ?m1) (mover_busy ?m2) ; the movers are not free
            (not(mover_waiting ?m1))
            (not(mover_waiting ?m2))
            
            ; Loader 
            (loader_free ?l) ; the loader is free

            ; Crate
            (is_pointed ?c ?m1) (is_pointed ?c ?m2) ; the crate is pointed by the movers
            (loading_bay_reached ?c) ; the crate reached the loading bay 

            ; Location
            (is_empty ?loc) ; the loading bay is free 
        )
        :effect (and (is_empty ?m1) (is_empty ?m2) ; the movers are free
            (not(is_pointing ?m1)) (not(is_pointing ?m2)) ; the movers are not pointing any crate
            (not(crate_light_reached ?c ?m1)) (not(crate_heavy_reached ?c ?m2)) ; the movers did not reach any crate
            (not(crate_light_reached ?c ?m2)) (not(crate_heavy_reached ?c ?m2))
            (not(is_pointed ?c ?m1)) (not(is_pointed ?c ?m2)) ; the crate is not pointed by any mover
            (on_loading_bay ?c) ; the crate is on the loading bay 

            (not(is_empty ?loc)) ; the loading bay is not free
            (assign (timer_waiting_for_free_loading_bay ?m1) 0)
             (assign (timer_waiting_for_free_loading_bay ?m2) 0)
        )
    )

    ; ------- WAITING LOADING BAY ------- ;

    (:process waiting_for_free_loading_bay_light_alone
    	:parameters (?m1 - mover ?m2 - mover ?c - crate ?loc - location ?l - loader)
    	:precondition (and (mover ?m1) (mover ?m2) (crate ?c) (location ?loc) (loader ?l) 
                            ; Movers
                            (not(= ?m1 ?m2)) ; the movers are different
                            (mover_busy ?m1) ; the active mover is holding the crate
                    
                            ; Crate
                            (< (weight_crate ?c) 50) ;(not(heavy ?c)) the crate is light
                            (is_pointed ?c ?m1) ; the crate is pointed by the active mover 
                            (not (is_pointed ?c ?m2)) ; the crate is NOT pointed by the other mover
                            (loading_bay_reached ?c) ; the crate reached the loading bay

                            ; Location
                            (not(is_empty ?loc)) ; the loading bay is empty            
        )
    	:effect (and (increase (timer_waiting_for_free_loading_bay ?m1) (* #t 1.0))
    			     (mover_waiting ?m1))
        )

     ; The mover puts down the light crate
    
    (:event stop_waiting_alone
        :parameters (?m - mover ?c - crate ?loc - location)
        :precondition (and (crate ?c) (mover ?m) (location ?loc)
            ; Mover
            (crate_light_reached ?c ?m) ; the mover reached the crate
            (mover_busy ?m) ; the mover is holding a crate
            (<= (timer ?m) 0.0)
            (mover_waiting ?m)
            (> (timer_waiting_for_free_loading_bay ?m) 0.0)

            ; Crate
            (is_pointed ?c ?m) ; the crate is pointed by the mover
            (not(loading_bay_reached ?c)) ; the crate still not reached the loading bay
            (< (weight_crate ?c) 50)
            
            ; Location
            (is_empty ?loc) ; the loading bay is empty   
            
        )
        :effect (and (not(mover_waiting ?m))
        		 (assign (timer_mover_waiting_for_free_loading_bay ?m) 0.0)) 
    )

    (:process waiting_for_free_loading_bay_together
    	:parameters (?m1 - mover ?m2 - mover ?c - crate ?loc - location ?l - loader)
    	:precondition (and (mover ?m1) (mover ?m2) (crate ?c) (location ?loc) (loader ?l) 
            ; Movers
            (<= (timer ?m1) 0.0)
            (<= (timer ?m2) 0.0)
            
            (not(= ?m1 ?m2)) ; the movers are different
            (mover_busy ?m1) ; the active mover is holding the crate
            (mover_busy ?m2) ; the active mover is holding the crate
      

            ; Crate
            
            (is_pointed ?c ?m1) ; the crate is pointed by the active mover 
            (is_pointed ?c ?m2) ; the crate is pointed by the active mover 
            
            (loading_bay_reached ?c) ; the crate reached the loading bay

            ; Location
            (not(is_empty ?loc)) ; the loading bay is empty            
        )
    	:effect (and (increase (timer_waiting_for_free_loading_bay ?m1) (* #t 1.0))
    	             (increase (timer_waiting_for_free_loading_bay ?m2) (* #t 1.0))
        )
    )
    
     (:event stop_waiting_together
        :parameters (?m1 - mover ?m2 - mover ?c - crate ?loc - location)
        :precondition (and (crate ?c) (mover ?m1) (mover ?m2) (location ?loc)
            ; Mover
            (not(= ?m1 ?m2)) ; the movers are different
            (mover_busy ?m1) ; the active mover is holding the crate
            (mover_busy ?m2) ; the active mover is holding the crate
            
            (or (and (crate_heavy_reached ?m1) ; the mover reached the crate
            (crate_heavy_reached ?m2)) (and (crate_light_reached ?c ?m1)
            (crate_light_reached ?c ?m2))) ; the mover reached the crate
            
            (<= (timer ?m1) 0.0)
            (<= (timer ?m2) 0.0)
            
            (mover_waiting ?m1)
            (mover_waiting ?m2)
            
            (> (timer_waiting_for_free_loading_bay ?m1) 0.0)
            (> (timer_waiting_for_free_loading_bay ?m2) 0.0)

            ; Crate
            (is_pointed ?c ?m1) ; the crate is pointed by the mover
            (is_pointed ?c ?m2) ; the crate is pointed by the mover
            
            (not(loading_bay_reached ?c)) ; the crate still not reached the loading bay
            (>= (weight_crate ?c) 50)
            
            ; Location
            (is_empty ?loc) ; the loading bay is empty   
            
        )
        :effect (and (not(mover_waiting ?m1))
                     (not(mover_waiting ?m2))
        		 (assign (timer_waiting_for_free_loading_bay ?m1) 0.0) 
        		  (assign (timer_waiting_for_free_loading_bay ?m2) 0.0) 
    		)
    )

    ; ------- DISTANCE EVENTS ------- ;

    ; The robot reached the crate
    (:event distance_cm_zero
        :parameters (?m - mover ?c - crate)
        :precondition (and (mover ?m) (crate ?c)
            ; Mover
            (or (not(crate_light_reached ?m)) (not(crate_heavy_reached ?m))) ; the mover still not reached the crate
            (<= (distance_cm ?m) 0.0) ; the distance between the mover and the crate is less or equals to zero

            ; Crate
            (is_pointed ?c ?m) ; the crate is pointed by the active mover
        )
        :effect (and (or (crate_light_reached ?c ?m) (crate_heavy_reached ?c ?m)) ; the mover reached the crate
            (assign (distance_cm ?m) 1.0) ; default
        ) 
    )

    ; The crate reached the loading bay
    (:event distance_cl_zero
        :parameters (?m - mover ?c - crate)
        :precondition (and (mover ?m) (crate ?c) 
            ; Mover
            (or (crate_light_reached ?c ?m) (crate_heavy_reached ?c ?m)) ; the mover reached the crate
            (mover_busy ?m) ; the mover is holding a crate
            (<= (timer ?m) 0.0)

            ; Crate
            (is_pointed ?c ?m) ; the crate is pointed by the mover
            (not(loading_bay_reached ?c)) ; the crate still not reached the loading bay
            ;(<= (distance_cl ?c) 0) ; the distance between the crate and the loading bay is less or equals to zero
        )
        :effect (and (loading_bay_reached ?c)) ; the crate reached the loading bay
    )

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++ BATTERY SECTION ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++;
    
    (:action activate-charger-heavy
        :parameters (?m1 - mover ?m2 - mover ?c - crate)
        :precondition (and  (mover ?m1) (mover ?m2) (crate ?c)
        		      (not(= ?m1 ?m2)) ; the movers are different
            			(not(mover_busy ?m1)) (not(mover_busy ?m2)) ; the movers are free
            			(not(is_pointing ?m1)) (not(is_pointing ?m2)) ; the movers are not pointing the crate
            
           			 ; Crate
            			(>= (weight_crate ?c) 50) ; (heavy ?c) the crate is heavy
           			    (not(at_location ?c)) ; the crate is not on the conveyor belt
            			(not(on_loading_bay ?c)) ; the crate is not on the loading bay
            			(not(is_pointed ?c ?m1)) (not(is_pointed ?c ?m2)) ; the crate is not pointed by the movers
        		      
                             (< (battery_level ?m1) (+ (/(distance_cl ?c) 10) (/(*(distance_cl ?c) (weight_crate ?c)) (+ (*(fl-fragile-crate ?c) 50 ) 100))))
                             (< (battery_level ?m2) (+ (/(distance_cl ?c) 10) (/(*(distance_cl ?c) (weight_crate ?c)) (+ (*(fl-fragile-crate ?c) 50 ) 100))))
        )
        ;refill battery_level at maximum        
        :effect (and(assign (battery_level ?m1) 20)
        		     (assign (battery_level ?m2) 20))
    )

    (:action activate-charger-light
        :parameters (?m - mover ?c - crate)
        :precondition (and  (mover ?m)  (crate ?c)
        		      ; Movers
           	           (not(mover_busy ?m)) ; the active mover is empty
            	       (is_pointing ?m) ; the active mover is not pointing anything
                       (is_pointed ?c ?m)
                	   (= (distance_cm ?m) (distance_cl ?c)) ; the distances from the crate are equals 
                       (not(charged ?m))
        )
        ;refill battery_level at maximum        
        :effect (and(assign (battery_level ?m) 20)
        		      (charged ?m))
    )

    ; --- INSTANTANEOUS CHARGING --- ;
    ; If the mover points a certain crate and sees that its battery is not sufficient to drive towards the crate and bringing it back to 
    ; the loading_bay, decides to recharge.
    (:event cheking_charged
        :parameters (?m - mover ?c - crate)
        :precondition (and  (mover ?m)  (crate ?c)
        		      ; Movers
           		      (not(mover_busy ?m)) ; the active mover is empty
            		  (is_pointing ?m) ; the active mover is not pointing anything
                      (is_pointed ?c ?m)
                	  (= (distance_cm ?m) (distance_cl ?c)) ; the distances from the crate are equals 
                      (< (battery_level ?m) (+ (/(distance_cl ?c) 10) (/(*(distance_cl ?c) (weight_crate ?c)) (+ (*(fl-fragile-crate ?c) 50 ) 100))))
                      )
         :effect (and(not(charged ?m)))
    )

    (:event check_battery_level
        :parameters (?m - mover ?c - crate)
        :precondition (and (mover ?m) (crate ?c)
                            (= (distance_cm ?m) (distance_cl ?c))
                            (not(mover_busy ?m)) ; the active mover is empty
                            (is_pointed ?c ?m)
                            (is_pointing ?m)
                            (or (not(crate_light_reached ?m)) (not(crate_heavy_reached ?c ?m)))
                            (not(charged ?m))
                            (>= (battery_level ?m) (+ (/(distance_cl ?c) 10) (/(*(distance_cl ?c) (weight_crate ?c)) (+ (*(fl-fragile-crate ?c) 50 ) 100))))
                        )
        :effect (and
            (charged ?m)
        )
    )

;+++++++++++++++++++++++++++++++++++++++++++++++++++++ LOADER SECTION +++++++++++++++++++++++++++++++++++++++++++++++++++++;

    ; The loader moves the crate from the loading bay to the conveyor belt
    (:process move_loader
        :parameters (?l - loader ?loc - location)
        :precondition (and (loader ?l) (location ?loc) 
            ; Loader
            (not(loader_free ?l)) ; the loader is not free
            
            ; Location
            (not(is_empty ?loc)) ; the location is not empty
        )
        :effect (and (decrease (timer ?l) (* #t 1.0)))
    )

    ; The loader moves the crate from the loading bay to the conveyor belt
    (:process move_strong_loader
        :parameters (?l - loader ?loc - location)
        :precondition (and (loader ?l) (strong_loader ?l) (location ?loc) 
            ; Loader
            (not(loader_free ?l)) ; the loader is not free
            
            ; Location
            (not(is_empty ?loc)) ; the location is not empty
        )
        :effect (and (decrease (timer ?l) (* #t 1.0)))
    )

    ; ------- LOADING PROCESS ------- ;

    ; The loader picks up the crate from the loading bay
    ; DEVI AGGIUNGERE IL WATING TIME:::::::::::::
    (:action load_light
        :parameters (?l - loader ?c - crate ?loc - location)
        :precondition (and (loader ?l) (crate ?c) (location ?loc)
            ; Crate
            (on_loading_bay ?c) ; the crate is on the loading bay 
            (not(is_pointed ?c ?l)) ; the crate is not pointed by the loader
            (< (weight_crate ?c) 50) ;(not (heavy ?c))
            ; Loader
            (or (strong_loader ?l) (weak_loader ?l))
            (loader_free ?l) ; the loader is free
            (<= (timer ?l) 0.0) ; default
            ; Location
            (not(is_empty ?loc)) ; the location is not empty
        )
        :effect (and (is_pointed ?c ?l) ; the crate is pointed by the loader 
                     (not(loader_free ?l)) ; the loader is not free
                     (assign (timer ?l) (+ 4.0 (* 2 (fl-fragile-crate ?c)))) ; default time to load a crate from the loading bay to the conveyor belt
        )
    )

    ; The loader is on the conveyor belt
    (:event loaded_light
        :parameters (?l - loader ?loc - location)
        :precondition (and (loader ?l) (location ?loc) 
            ; Loader
            (not(loader_free ?l)) ; the loader is not free
            (= (timer ?l) 0.0) ; the loader finished to move against the conveyor belt

            ; Location
            (not(is_empty ?loc)) ; the location is not empty
        )
        :effect (and (is_empty ?loc)) ; the loading bay is empty
    )
    
    ; The loader puts down the crate on the conveyor belt
    (:action unload_light
        :parameters (?l - loader ?c - crate ?loc - location)
        :precondition (and (loader ?l) (crate ?c) (location ?loc) 
            ; Crate
            (is_pointed ?c ?l) ; the crate is pointed by the loader

            ; Loader
            (not(loader_free ?l)) ; the loader is not free

            ; Location
            (is_empty ?loc) ; the loading bay is empty
        )
        :effect (and (not(is_pointed ?c ?l)) ; the crate is not pointed by the loader
                     (not(on_loading_bay ?c)) ; the crate is not on the loading bay
                     (at_location ?c) ; the crate is on the conveyor belt
                     (loader_free ?l) ; the loader is free 
        )
    )

    ; The loader picks up the crate from the loading bay
    (:action load_heavy
        :parameters (?l - loader ?l2 - loader ?c - crate ?loc - location)
        :precondition (and (loader ?l) (strong_loader ?l) (crate ?c) (location ?loc)
            ; Crate
            (on_loading_bay ?c) ; the crate is on the loading bay 
            (not(is_pointed ?c ?l)) ; the crate is not pointed by the loader
            (>= (weight_crate ?c) 50) ; (heavy ?c)
            
            ; Loader
            (loader_free ?l) ; the loader is free
            
            (<= (timer ?l) 0.0) ; default

            ; Location
            (not(is_empty ?loc)) ; the location is not empty
        )
        :effect (and (is_pointed ?c ?l) ; the crate is pointed by the loader 
                     (not(loader_free ?l)) ; the loader is not free
                     (assign (timer ?l) (+ 4.0 (* 2 (fl-fragile-crate ?c)))) ; default time to load a crate from the loading bay to the conveyor belt
        )
    )

    ; The loader is on the conveyor belt
    (:event loaded_heavy
        :parameters (?l - loader ?loc - location)
        :precondition (and (loader ?l) (strong_loader ?l) (location ?loc) 
            ; Loader
            (not(loader_free ?l)) ; the loader is not free
            (= (timer ?l) 0.0) ; the loader finished to move against the conveyor belt

            ; Location
            (not(is_empty ?loc)) ; the location is not empty
        )
        :effect (and (is_empty ?loc)) ; the loading bay is empty
    )
    
    ; The loader puts down the crate on the conveyor belt
    (:action unload_heavy
        :parameters (?l - loader ?c - crate ?loc - location)
        :precondition (and (loader ?l) (strong_loader ?l) (crate ?c) (location ?loc) 
            ; Crate
            (is_pointed ?c ?l) ; the crate is pointed by the loader
	        (>= (weight_crate ?c) 50) ; (heavy ?c)
	    
            ; Loader
            (not(loader_free ?l)) ; the loader is not free

            ; Location
            (is_empty ?loc) ; the loading bay is empty
        )
        :effect (and (not(is_pointed ?c ?l)) ; the crate is not pointed by the loader
                     (not(on_loading_bay ?c)) ; the crate is not on the loading bay
                     (at_location ?c) ; the crate is on the conveyor belt
                     (loader_free ?l) ; the loader is free 
        )
    )

)

