(define (domain airo2_group_k_domain)
    (   :requirements 
        :adl 
    	:typing 
    	:equality
    	:fluents
    	:time 
     	:negative-preconditions  
        :disjunctive-preconditions
    )
    

    (:types
        robot location crate group - object
        mover loader - robot
    )

    (:predicates
        (mover ?m - obj)
        (loader ?l - obj)
        (crate ?c - obj) 
        (location ?loc - obj)
        (group ?g - obj)
     
    ; ++++++++++++++++++++++++++++ group predicates +++++++++++++++++++++++++++++

        (active_group ?g - group)
        (belongs_to ?c - crate ?g - group)
      
    ;++++++++++++++++++++++++++++++ mover predicates ++++++++++++++++++++++++++++++
        
        (mover_busy ?m - mover) ; robot r is busy 
        (is_pointing ?m - mover) ; the mover is pointing a crate
        (mover_waiting ?m - mover)

    ;++++++++++++++++++++++++++++++ loader predicates +++++++++++++++++++++++++++++
        
        (strong_loader ?l - loader)
        (loader_free ?l - loader)
        (loader_pointed ?c - crate ?l - loader)
        (on_conveyor_belt ?l - loader)

    ;++++++++++++++++++++++++++++++ crate predicates ++++++++++++++++++++++++++++++
       
        (heavy ?c - crate) ; the crate is heavy
        (on_loading_bay ?c - crate) ; the crate is on the loading bay
        (at_location ?c - crate) ; the crate is on the conveyor bel
        (is_pointed ?c - crate ?m - mover) ; the crate is pointed by the mover/loader

    ;+++++++++++++++++++++++++++++++++++ others +++++++++++++++++++++++++++++++++++
        (crate_reached ?c - crate ?m - mover)
        (loading_bay_reached ?c - crate) ; the crate has reached the loading bay
        (is_empty ?loc - location)
    )

    (:functions
        (weight_crate ?c - crate)  ; the weight of a certain crate
        (fl-fragile-crate ?c - crate) ; this can be 0 or 1 for not fragile or fragile crates respectively

        (counter_group ?g - group)
        (timer ?m - mover) - number ; timer
        (timer_loading_crate  ?l - loader) 
        (timer_waiting_for_free_loading_bay ?m - mover)
        (distance_cl ?c - crate) ; distance between the crate and the loading bay
        (distance_cm ?m - mover) ; distance between the crate and the mover
    )

; ++++++++++++++++++++++++++++++++++++++++++++++++++ GROUP SECTION ++++++++++++++++++++++++++++++++++++++++++++++++++ ;

    (:event choose_next_group
        :parameters (?g1 - group ?g2 - group)
        :precondition (and 
            (active_group ?g1)
            (= (counter_group ?g1) 0)
            (not(active_group ?g2))
            (> (counter_group ?g2) 0)
        )
        :effect (and (active_group ?g2)
            (not(active_group ?g1))
        )
    )

; ++++++++++++++++++++++++++++++++++++++++++++++++++ MOVER SECTION ++++++++++++++++++++++++++++++++++++++++++++++++++ ;

    ; ------- POINTING CRATES ------- ;
    
    ; The mover points to a light crate
    (:action pointing_light
        :parameters (?m1 - mover ?m2 - mover ?c - crate ?g - group)
        :precondition (and (mover ?m1) (mover ?m2) (crate ?c) (group ?g)
            ; Movers
            (not(= ?m1 ?m2)); the movers are different
            (not(mover_busy ?m1)) ; the active mover is empty
            (not(is_pointing ?m1)) ; the active mover is not pointing anything
            (not(is_pointed ?c ?m1)) ; the crate is not pointed by the active mover
 
            ; Crate
            (< (weight_crate ?c) 50) (not(heavy ?c)) ; the crate is light
            (not(loading_bay_reached ?c))
            ;(not(at_location ?c)) ; the crate is not on the conveyor belt
            (not(on_loading_bay ?c)) ; the crate has not been loaded on the loading bay
            (not(is_pointed ?c ?m1)) ; the crate is not pointed by the active mover
            (or (not(is_pointed ?c ?m2)) ; the other mover is not pointed the crate or
                (and (is_pointed ?c ?m2) ; it is pointing it and
                (= (distance_cm ?m2) (distance_cm ?m1)))) ; the distances from the crate are equals 
                        
            (belongs_to ?c ?g)
            (active_group ?g)
        ) 
        :effect (and (is_pointing ?m1) ; the mover is pointing a crate 
            (is_pointed ?c ?m1) ; the crate is pointed by the active mover
            (assign (distance_cm ?m1) (distance_cl ?c)) ; the distance between the mover and the crate
                                                        ; is equals to the distance between the crate and the loading bay
        ) 
    )

    ; The movers point a heavy crate 
    (:action pointing_heavy
        :parameters (?m1 - mover ?m2 - mover ?c - crate ?g - group)
        :precondition (and (mover ?m1) (mover ?m2) (crate ?c) (group ?g)
            ; Movers
            (not(= ?m1 ?m2)) ; the movers are different
            (not(mover_busy ?m1)) (not(mover_busy ?m2)) ; the movers are free
            (not(is_pointing ?m1)) (not(is_pointing ?m2)) ; the movers are not pointing the crate
            
            ; Crate
            (>= (weight_crate ?c) 50) ;(heavy ?c) the crate is heavy
            (not(loading_bay_reached ?c))
            (belongs_to ?c ?g)
            (active_group ?g)

            ;(not(at_location ?c)) ; the crate is not on the conveyor belt
            (not(on_loading_bay ?c)) ; the crate is not on the loading bay
            (not(is_pointed ?c ?m1)) (not(is_pointed ?c ?m2)) ; the crate is not pointed by the movers 
        ) 
        :effect (and (is_pointing ?m1) (is_pointing ?m2) ; the movers are pointing the crate

            (is_pointed ?c ?m1) (is_pointed ?c ?m2) ; the crate is pointed by the movers 

            ; the distance between the mover and the crate is equals to the distance between the crate and the loading bay
            (assign (distance_cm ?m1) (distance_cl ?c)) (assign (distance_cm ?m2) (distance_cl ?c)) 
        )
    )

    ; ------- MOVING TOWARD THE CRATES ------- ;

    ; The mover moves toward the crate 
    (:process move_empty
        :parameters (?m - mover ?c - crate)
        :precondition (and (mover ?m) (crate ?c)
            ; Mover
            (not(crate_reached ?c ?m)) ; the mover still not reached the crate

            ; Crate
            (is_pointed ?c ?m) ; the crate is pointed by the active mover
        )  
        :effect (and (decrease (distance_cm ?m) (* #t 10.0)) ; the mover moves against the crate
        )
    )

    ; The robot reached the crate
    (:event distance_cm_zero
        :parameters (?m - mover ?c - crate)
        :precondition (and (mover ?m) (crate ?c)
            ; Mover
            (not(crate_reached ?c ?m)) ; the mover still not reached the crate
            (<= (distance_cm ?m) 0.0) ; the distance between the mover and the crate is less or equals to zero

            ; Crate
            (is_pointed ?c ?m) ; the crate is pointed by the active mover
        )
        :effect (and (crate_reached ?c ?m) ; the mover reached the crate
            (assign (distance_cm ?m) 1.0) ; default
        ) 
    )

    ; ------- PICKING UP THE CRATES ------- ;

    ; The mover picks up the light crate
    (:action pick_up
        :parameters (?m1 - mover ?m2 - mover ?c - crate)
        :precondition (and (mover ?m1) (mover ?m2) (crate ?c)
            ; Mover 
            (not(mover_busy ?m1)) ; the mover is empty
            (crate_reached ?c ?m1) ; the mover reached the crate
            (not(is_pointed ?c ?m2)) ; the other mover is not pointed the crate
  
            ; Crate
            (< (weight_crate ?c) 50) 
            (not(heavy ?c)) ;the crate is light
            (is_pointed ?c ?m1) ; the crate is pointed by the mover
        )
        :effect (and (mover_busy ?m1) ; the mover is not empty
            (assign (timer ?m1) (/ (* (distance_cl ?c) (weight_crate ?c)) 100)) ; set the step size 
        )
    )

    ; The movers pick up the heavy crate
    (:action pick_up_together_heavy
        :parameters (?m1 - mover ?m2 - mover ?c - crate)
        :precondition (and (mover ?m1) (mover ?m2) (crate ?c)
            ; Movers
            (not (= ?m1 ?m2)) ; the movers are different
            (not(mover_busy ?m1)) (not(mover_busy ?m2)) ; the movers are free
            (crate_reached ?c ?m1) (crate_reached ?c ?m2) ; the movers reached the crate

            ; Crate
            (>= (weight_crate ?c) 50) (heavy ?c) ;the crate is heavy
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
        :precondition (and (mover ?m1) (mover ?m2) (crate ?c)
            ; Movers
            (not(= ?m1 ?m2)) ; the movers are different
            (not(mover_busy ?m1)) (not(mover_busy ?m2)) ; the movers are free
            (crate_reached ?c ?m1) (crate_reached ?c ?m2) ; the movers reached the crate

            ; Crate
            (< (weight_crate ?c) 50) 
            (not(heavy ?c)) ; the crate is light
            (is_pointed ?c ?m1) (is_pointed ?c ?m2) ; the crate is pointed by the movers
        )
        :effect (and (mover_busy ?m1) (mover_busy ?m2) ; the movers are not free
            (assign (timer ?m1) (/(*(distance_cl ?c) (weight_crate ?c)) (+ (* (fl-fragile-crate ?c) 50) 100 ))); set the step size 
            (assign (timer ?m2) (/ (* (distance_cl ?c) (weight_crate ?c)) (+ (* (fl-fragile-crate ?c) 50) 100 ))) ; set the step size 
        )
    )

    ; ------- MOVING WITH THE CRATES ------- ;

    ; The robot moves toward the loading bay holding the crate
    (:process move_full
        :parameters (?m - mover ?c - crate)
        :precondition (and (mover ?m) (crate ?c)
            ; Mover
            (crate_reached ?c ?m) ; the mover reached the crate
            (mover_busy ?m) ; the mover is holding a crate
            (< (weight_crate ?c) 50) ; (not(heavy ?c)) the crate is light
            (is_pointed ?c ?m) ; the crate is pointed by the mover
            (not(loading_bay_reached ?c)) ; the crate still not reached the loading bay
        )
        :effect (and (decrease (timer ?m) (* #t 1.0)) ; the distance bewteen crate and loading bay decrease
        ) 
    ) 

    ; The movers move holding a crate together
    (:process move_full_together
        :parameters (?m1 - mover ?m2 - mover ?c - crate)
        :precondition (and (mover ?m1) (mover ?m2) (crate ?c)
            ; Movers
            (not(= ?m1 ?m2)) ; the movers are different
            (mover_busy ?m1) (mover_busy ?m2) ; the movers are not free
            (> (timer ?m1) 0.0) (> (timer ?m2) 0.0) ; the movers' step is greater than 0
            ; Crate
            (is_pointed ?c ?m1) (is_pointed ?c ?m2) ; the crate is pointed by the movers  
            (not(loading_bay_reached ?c)) ; the crate still not reached the loading bay
        )
        :effect (and (decrease (timer ?m1) (* #t 1.0))
            (decrease (timer ?m2) (* #t 1.0))
        )
    )   

    ; The crate reached the loading bay
    (:event distance_cl_zero
        :parameters (?m - mover ?c - crate)
        :precondition (and (mover ?m) (crate ?c)
            ; Mover
            (crate_reached ?c ?m) ; the mover reached the crate
            (mover_busy ?m) ; the mover is holding a crate
            (<= (timer ?m) 0.0)

            ; Crate
            (is_pointed ?c ?m) ; the crate is pointed by the mover
            (not(loading_bay_reached ?c)) ; the crate still not reached the loading bay
            ;(<= (distance_cl ?c) 0) ; the distance between the crate and the loading bay is less or equals to zero
        )
        :effect (and (loading_bay_reached ?c)) ; the crate reached the loading bay
    )
    
    ; ------- PUTTING DOWN THE CRATE ------- ;

    (:action put_down
        :parameters (?m1 - mover ?m2 - mover ?c - crate ?loc - location ?l1 - loader ?l2 - loader ?g - group)
        :precondition (and (mover ?m1) (mover ?m2) (crate ?c) (location ?loc) (loader ?l1) (loader ?l2) (group ?g)
            ; Movers
            (not(= ?m1 ?m2)) ; the movers are different
            (mover_busy ?m1) ; the active mover is holding the crate
            ;(not(mover_waiting ?m1))
             
            ; Location
            (is_empty ?loc)
            
            ; Loader 
            (not(= ?l1 ?l2))
            (or (loader_free ?l1) (loader_free ?l2)) ; one loader is free

            ; Crate
            (< (weight_crate ?c) 50) (not(heavy ?c)) ; the crate is light
            (is_pointed ?c ?m1) ; the crate is pointed by the active mover 

            (belongs_to ?c ?g)
            (active_group ?g)

            (not (is_pointed ?c ?m2)) ; the crate is NOT pointed by the other mover
            (loading_bay_reached ?c) ; the crate reached the loading bay           
        )
        :effect (and (not(crate_reached ?c ?m1)) ; the mover did not reached any crate
            (not(is_pointing ?m1)) ; the mover is not pointing any crate
            (not(mover_busy ?m1)) ; the mover is empty
            (assign (distance_cm ?m1) 1) ; default

            (not(is_pointed ?c ?m1)) ; the crate is not pointed by the active mover 
            (on_loading_bay ?c) ; the crate is on the loading bay
            (decrease (counter_group ?g) 1)


            (not(is_empty ?loc)) ; the location is not empty 
            (assign (timer_waiting_for_free_loading_bay ?m1) 0)
            (not (mover_waiting ?m1))
        )
    )

    ; If the loading bay is free, the movers put down the light/heavy crate
    (:action put_down_together
        :parameters (?m1 - mover ?m2 - mover ?c - crate ?loc - location ?l - loader ?g - group)
        :precondition (and (mover ?m1) (mover ?m2) (crate ?c) (location ?loc) (loader ?l) (group ?g)
            ; Movers
            (not(= ?m1 ?m2)) ; the movers are different 
            (mover_busy ?m1) (mover_busy ?m2) ; the movers are not free
            (not(mover_waiting ?m1))
            (not(mover_waiting ?m2))
            
            ; Loader
            (strong_loader ?l) ; the loader can move heavy crate
            (loader_free ?l) ; the loader is free
            
            ; Crate
            (is_pointed ?c ?m1) (is_pointed ?c ?m2) ; the crate is pointed by the movers
            (loading_bay_reached ?c) ; the crate reached the loading bay 
            (belongs_to ?c ?g)
            (active_group ?g)

            ; Location
            (is_empty ?loc) ; the loading bay is free 
        )
        :effect (and (not(mover_busy ?m1)) (not(mover_busy ?m2)) ; the movers are free
            (not(is_pointing ?m1)) (not(is_pointing ?m2)) ; the movers are not pointing any crate
            (not(crate_reached ?c ?m1)) (not(crate_reached ?c ?m2)) ; the movers did not reach any crate
            (not(is_pointed ?c ?m1)) (not(is_pointed ?c ?m2)) ; the crate is not pointed by any mover
            (on_loading_bay ?c) ; the crate is on the loading bay 

            (not(is_empty ?loc)) ; the loading bay is not free
             (decrease (counter_group ?g) 1)
            ;(assign (timer_waiting_for_free_loading_bay ?m1) 0)
            ;(assign (timer_waiting_for_free_loading_bay ?m2) 0)
        )
    )	
	
; ++++++++++++++++++++++++++++++++++++++++++++++++++ LOADER SECTION ++++++++++++++++++++++++++++++++++++++++++++++++++ ; 

    ; ------- LOADING PROCESS ------- ;

    ; The loader picks up the crate from the loading bay
    (:action load_light
        :parameters (?l1 - loader ?l2 - loader ?c - crate ?loc - location)
        :precondition (and (loader ?l1) (loader ?l2) (crate ?c) (location ?loc)
            ; Crate
            (< (weight_crate ?c) 50) (not (heavy ?c)) ; the crate is heavy
            (on_loading_bay ?c)

            ; Loader
            (not(= ?l1 ?l2)) ; the loaders are different
            (not(loader_pointed ?c ?l1)) ; the crate is not pointed by the loader
            (loader_free ?l1) ; the loader is free
            (= (timer_loading_crate ?l1) 0) ; default
            (not(loader_pointed ?c ?l2))

            ; Location
            (not(is_empty ?loc)) ; the location is not empty
        )
        :effect (and (loader_pointed ?c ?l1) ; the crate is pointed by the loader 
                    (not(loader_free ?l1)) ; the loader is not free
                    (is_empty ?loc)
                    (not(on_loading_bay ?c))
                    (assign (timer_loading_crate ?l1) (+ 4.0 (* 2 (fl-fragile-crate ?c))))
                )      
        )
        
    ; The loader picks up the crate from the loading bay
    (:action load_heavy
        :parameters (?l - loader ?c - crate ?loc - location)
        :precondition (and (loader ?l) (crate ?c) (location ?loc)
            ; Crate
            (loading_bay_reached ?c) ; the crate is on the loading bay
            (not(loader_pointed ?c ?l)) ; the crate is not pointed by the loader
            (>= (weight_crate ?c) 50) (heavy ?c)
            
            ; Loader
            (loader_free ?l) ; the loader is free
            (strong_loader ?l)
            (= (timer_loading_crate ?l) 0) ; default

            ; Location
            (not(is_empty ?loc)) ; the loading bay is not empty
        )
        :effect (and (loader_pointed ?c ?l) ; the crate is pointed by the loader 
        	        (is_empty ?loc)
                    (not(loader_free ?l)) ; the loader is not free
                    (not (on_loading_bay ?c))
                    (assign (timer_loading_crate ?l) (+ 4.0 (* 2 (fl-fragile-crate ?c)))) ; default time to load a crate from the loading bay to the conveyor belt
        )
    )

	; The loader moves the crate from the loading bay to the conveyor belt
    (:process move_loader
        :parameters (?l - loader ?c - crate)
        :precondition (and (loader ?l) (crate ?c)
            ; Loader
            (not(on_conveyor_belt ?l))
            (not(loader_free ?l)) ; the loader is not free
            (loader_pointed ?c ?l)
            (< (weight_crate ?c) 50) (not(heavy ?c)) ; the crate is light
        )
        :effect (and (decrease (timer_loading_crate ?l) (* #t 1.0)))
    )

    ; The loader moves the crate from the loading bay to the conveyor belt
    (:process move_strong_loader
        :parameters (?l - loader ?c - crate )
        :precondition (and (loader ?l) (crate ?c)
            ; Loader
            (not(on_conveyor_belt ?l))
            (not(loader_free ?l)) ; the loader is not free
            (loader_pointed ?c ?l)
            (strong_loader ?l)
            
            ;Crate
            (>= (weight_crate ?c) 50) (heavy ?c) ; the crate is heavy
        )
        :effect (and (decrease (timer_loading_crate ?l) (* #t 1.0)))
    )
    
    ; The loader is on the conveyor belt
    (:event loaded_light
        :parameters (?l - loader)
        :precondition (and  
            ; Loader
            (not(on_conveyor_belt ?l))
            (not(loader_free ?l)) ; the loader is not free
            (<= (timer_loading_crate ?l) 0.0) ; the loader finished to move against the conveyor belt
        )
        
        :effect (and (assign (timer_loading_crate ?l) 0) (on_conveyor_belt ?l)) ; the loading bay is empty
    )
    
    ; The loader is on the conveyor belt
    (:event loaded_heavy
        :parameters (?l - loader ); ?loc - location
        :precondition (and (loader ?l)
            ; Loader
            (not(on_conveyor_belt ?l))
            (strong_loader ?l)
            (not(loader_free ?l)) ; the loader is not free
            (<= (timer_loading_crate ?l) 0.0) ; the loader finished to move against the conveyor belt
        )
        :effect (and (assign (timer_loading_crate ?l) 0) (on_conveyor_belt ?l)); the loading bay is empty
    )
    
    ; The loader puts down the crate on the conveyor belt
    (:action unload_light
        :parameters (?l - loader ?c - crate) 
        :precondition (and (loader ?l) (crate ?c)
            ; Loader
            (on_conveyor_belt ?l)
            (loader_pointed ?c ?l) ; the crate is pointed by the loader
            (not(loader_free ?l)) ; the loader is not free
            (< (weight_crate ?c) 50)
            ;(= (timer_loading_crate ?l) -1)
        )
        :effect (and (not(loader_pointed ?c ?l)) ; the crate is not pointed by the loader
            (not(on_conveyor_belt ?l))
            (at_location ?c) ; the crate is on the conveyor belt
            (loader_free ?l) ; the loader is free 
        )
    )

    ; The loader puts down the crate on the conveyor belt
    (:action unload_heavy
        :parameters (?l - loader ?c - crate )
        :precondition (and (loader ?l) (crate ?c)
        	; Loader
            (on_conveyor_belt ?l)
            (loader_pointed ?c ?l) ; the crate is pointed by the loader
            (not(loader_free ?l)) ; the loader is not free
            (strong_loader ?l)  
            
            (>= (weight_crate ?c) 50) (heavy ?c) ; the crate is heavy
            ;(= (timer_loading_crate ?l) -1)
        )
        :effect (and (not(loader_pointed ?c ?l)) ; the crate is not pointed by the loader
            (not(on_conveyor_belt ?l))
            (at_location ?c) ; the crate is on the conveyor belt
            (loader_free ?l) ; the loader is free 
        )
    )
)