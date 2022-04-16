(define (domain airo2_group_k_domain)

    (:requirements
        :time
        :typing
        :equality
        :negative-preconditions 
        :disjunctive-preconditions
    )

    (:types 
		obj - Object ; general type
	)

    (:predicates
        (heavy ?c)

        (mover ?m - obj)
        (loader ?l - obj)
        (crate ?c - obj) 
        (location ?loc - obj)
        
        (on_load ?c) ; the crate is on the loading bay
        (at_location ?c - obj) ; crate c is at location 
        (is_pointed ?c - obj ?r - obj) ; crate c is pointed by robot r
        (is_pointing ?m) ; the mover is pointing a crate
        (reached ?r - obj) ; robot r reached the crate 
        (is_empty ?rb - obj) ; robot r and/or loading bay b is empty 
    )

    (:functions
        (weight_crate ?c - obj) - number ; weight of the crate
        (timer ?r - obj) - number ; step/timer size
        (distance_cl ?c - obj) - number ; distance between the crate and the loading bay
        (distance_cm ?m - obj) - number ; distance between the crate and the mover
    )

    ; --- LIGHT CRATE --- ; 
    
    ; The mover points to a light crate
    (:action pointing_light
        :parameters (?m1 - obj ?m2 - obj ?c - obj)
        :precondition (and (crate ?c) (mover ?m1) (mover ?m2)  
            ; Movers
            (not(= ?m1 ?m2)) ; the movers are different
            (is_empty ?m1) ; the active mover is empty
            (not(is_pointing ?m1)) ; the active mover is not pointing anything
            
            ; Crate
            (not(heavy ?c)) ; (< (weight_crate ?c) 50) the crate is light
            (not(on_load ?c)) ; the crate has not been loaded on the loading bay
            (not(is_pointed ?c ?m1)) ; the crate is not pointed by the active mover
            (or (not(is_pointed ?c ?m2)) ; the other mover is not pointed the crate or
                (and (is_pointed ?c ?m2) ; it is pointing it and
                (= (distance_cm ?m2) (distance_cm ?m1)))) ; the distances from the crate are equals 
        ) 
        :effect (and (is_pointing ?m1) ; the mover is pointing a crate 
                (is_pointed ?c ?m1) ; the crate is pointed by the active mover
                (assign (distance_cm ?m1) (distance_cl ?c)) ; the distance between the mover and the crate
                                                            ; is equals to the distance between the crate and the loading bay
        ) 
    )

    ; The mover moves against the crate 
    (:process move_empty
        :parameters (?m - obj ?c - obj)
        :precondition (and (mover ?m) (crate ?c) 
            ; Mover
            (is_pointing ?m) ; the mover is pointing a crate
            (not(reached ?m)) ; the mover still not reached the crate

            ; Crate
            (is_pointed ?c ?m) ; the crate is pointed by the active mover
        )  
        :effect (and (decrease (distance_cm ?m) (* #t 10))) ; the mover moves against the crate
    )

    ; The robot reached the crate
    (:event distance_cm_zero
        :parameters (?m - obj ?c - obj)
        :precondition (and (mover ?m) (crate ?c)
            ; Mover
            (is_pointing ?m) ; the mover is pointing a crate
            (not(reached ?m)) ; the mover still not reached the crate
            (<= (distance_cm ?m) 0) ; the distance between the mover and the crate is less or equals to zero

            ; Crate
            (is_pointed ?c ?m) ; the crate is pointed by the active mover
        )
        :effect (and (reached ?m)) ; the mover reached the crate
    )
    
    ; The mover picks up the light crate
    (:action pick_up
        :parameters (?m - obj ?c - obj)
        :precondition (and (mover ?m) (crate ?c)
            ; Mover 
            (is_empty ?m) ; the mover is empty
            (reached ?m) ; the mover reached the crate

            ; Crate
            (not(heavy ?c)) ; (< (weight_crate ?c) 50) ; the crate is light
            (is_pointed ?c ?m) ; the crate is pointed by the mover
        )
        :effect (and (not(is_empty ?m)) ; the mover is not empty
            (assign (timer ?m) (/ (* (distance_cl ?c) (weight_crate ?c)) 100)) ; set the step size 
        )
    )

    ; The robot moves against the loading bay holding the crate
    (:process move_full
        :parameters (?m - obj ?c - obj)
        :precondition (and (crate ?c) (mover ?m)
            ; Mover
            (not(is_empty ?m)) ; the mover is holding a crate
            (> (timer ?m) 0) ; the mover's step is greater than 0
            
            ; Crate
            (not(heavy ?c)) ; the crate il light
            (is_pointed ?c ?m)  ; the crate is pointed by the mover
            (not(reached ?c)) ; the crate still not reached the loading bay
            
        )
        :effect (and (decrease (distance_cl ?c) (* (timer ?m) #t))) ; the distance bewteen crate and loading bay decrease
    )

    ; The crate reached the loading bay
    (:event distance_cl_zero
        :parameters (?c - obj)
        :precondition (and (crate ?c)
            (not(reached ?c)) ; the crate still not reached the loading bay
            (<= (distance_cl ?c) 0) ; the distance between the crate and the loading bay is less or equals to zero
        )
        :effect (and (reached ?c)) ; the crate reached the loading bay
    )

    ; The mover puts down the light crate
    (:action put_down
        :parameters (?m1 - obj ?m2 - obj ?c - obj ?loc - obj ?l - obj)
        :precondition (and (mover ?m1) (mover ?m2) (crate ?c) (location ?loc) (loader ?l) 
            ; Movers
            (not(= ?m1 ?m2)) ; the movers are different
            (not(is_empty ?m1)) ; the active mover is holding the crate
            
            ; Loader 
            (is_empty ?l) ; the loader is free

            ; Crate
            (not(heavy ?c)) ; the crate is light
            (is_pointed ?c ?m1) ; the crate is pointed by the active mover 
            (not (is_pointed ?c ?m2)) ; the crate is NOT pointed by the other mover
            (reached ?c) ; the crate reached the loading bay

            ; Location
            (is_empty ?loc) ; the loading bay is empty            
        )
        :effect (and (not(reached ?m1)) ; the mover did not reached any crate
            (not(is_pointing ?m1)) ; the mover is not pointing any crate
            (is_empty ?m1) ; the mover is empty
            (assign (distance_cm ?m1) 1) ; default

            (not(is_pointed ?c ?m1)) ; the crate is not pointed by the active mover 
            (on_load ?c) ; the crate is on the loading bay

            (not(is_empty ?loc)) ; the location is not empty 
        )
    )

    ; The loader picks up the crate from the loading bay
    (:action load
        :parameters (?l - obj ?c - obj ?loc - obj)
        :precondition (and (loader ?l) (crate ?c) (location ?loc)
            ; Crate
            (on_load ?c) ; the crate is on the loading bay 
            (not(is_pointed ?c ?l)) ; the crate is not pointed by the loader
            
            ; Loader
            (is_empty ?l) ; the loader is free
            (= (timer ?l) 0) ; default

            ; Location
            (not(is_empty ?loc)) ; the location is not empty
        )
        :effect (and (is_pointed ?c ?l) ; the crate is pointed by the loader 
            
            (not(is_empty ?l)) ; the loader is not free
            (assign (timer ?l) 4) ; default time to load a crate from the loading bay to the conveyor belt
        )
    )

    ; The loader moves the crate from the loading bay to the conveyor belt
    (:process move_loader
        :parameters (?l - obj ?loc - obj)
        :precondition (and (loader ?l) (location ?loc) 
            ; Loader
            (not(is_empty ?l)) ; the loader is not free
            
            ; Location
            (not(is_empty ?loc)) ; the location is not empty
        )
        :effect (and (decrease (timer ?l) #t))
    )

    ; The loader is on the conveyor belt
    (:event loaded
        :parameters (?l - obj ?loc - obj)
        :precondition (and (loader ?l) (location ?loc) 
            ; Loader
            (not(is_empty ?l)) ; the loader is not free
            (= (timer ?l) 0) ; the loader finished to move against the conveyor belt

            ; Location
            (not(is_empty ?loc)) ; the location is not empty
        )
        :effect (and (is_empty ?loc)) ; the loading bay is empty
    )
    
    ; The loader puts down the crate on the conveyor belt
    (:action unload
        :parameters (?l - obj ?c - obj ?loc - obj)
        :precondition (and (loader ?l) (crate ?c) (location ?loc) 
            ; Crate
            (is_pointed ?c ?l) ; the crate is pointed by the loader

            ; Loader
            (not(is_empty ?l)) ; the loader is not free

            ; Location
            (is_empty ?loc) ; the loading bay is empty
        )
        :effect (and (not(is_pointed ?c ?l)) ; the crate is not pointed by the loader
            (at_location ?c) ; the crate is on the conveyor belt
        
            (is_empty ?l) ; the loader is free 
        )
    )

    ; --- HEAVY CRATE --- ;

    ; The movers point a heavy crate 
    (:action pointing_heavy
        :parameters (?m1 - obj ?m2 - obj ?c - obj)
        :precondition (and (crate ?c) (mover ?m1) (mover ?m2)
            ; Movers
            (not(= ?m1 ?m2)) ; the movers are different
            (is_empty ?m1) (is_empty ?m2) ; the movers are free
            (not(is_pointing ?m1)) (not(is_pointing ?m2)) ; the movers are not pointing the crate
            
            ; Crate
            (heavy ?c) ; (>= (weight_crate ?c) 50) ; the crate is heavy
            (not(on_load ?c)) ; the crate is not on the loading bay
            (not(is_pointed ?c ?m1)) (not(is_pointed ?c ?m2)) ; the crate is not pointed by the movers
        ) 
        :effect (and (is_pointing ?m1) (is_pointing ?m2) ; the movers are pointing the crate

            (is_pointed ?c ?m1) (is_pointed ?c ?m2) ; the crate is pointed by the movers 

            ; the distance between the mover and the crate is equals to the distance between the crate and the loading bay
            (assign (distance_cm ?m1) (distance_cl ?c)) (assign (distance_cm ?m2) (distance_cl ?c)) 
        )
    )

    ; The movers pick up the light/heavy crate
    (:action pick_up_together
        :parameters (?m1 - obj ?m2 - obj ?c - obj)
        :precondition (and (crate ?c) (mover ?m1) (mover ?m2)
            ; Movers
            (not (= ?m1 ?m2)) ; the movers are different
            (is_empty ?m1) (is_empty ?m2) ; the movers are free
            (reached ?m1) (reached ?m2) ; the movers reached the crate

            ; Crate
            (is_pointed ?c ?m1) (is_pointed ?c ?m2) ; the crate is pointed by the movers
        )
        :effect (and (not(is_empty ?m1)) (not(is_empty ?m2)) ; the movers are not free
            (assign (timer ?m1) (/ (* (distance_cl ?c) (weight_crate ?c)) 100)) ; set the step size 
            (assign (timer ?m2) (/ (* (distance_cl ?c) (weight_crate ?c)) 100)) ; set the step size 
        )
    )

    ; PROCESS MOVE FULL TOGETHER
    (:process move_full_together
        :parameters (?m1 - obj ?m2 - obj ?c - obj)
        :precondition (and (mover ?m1) (mover ?m2) (crate ?c) 
            ; Movers
            (not(= ?m1 ?m2)) ; the movers are different
            (not(is_empty ?m1)) (not(is_empty ?m2)) ; the movers are not free
            (> (timer ?m1) 0) (> (timer ?m2) 0) ; the movers' step is greater than 0

            ; Crate
            (is_pointed ?c ?m1) (is_pointed ?c ?m2) ; the crate is pointed by the movers  
            (not(reached ?c)) ; the crate still not reached the loading bay
        )
        :effect (and (decrease (distance_cl ?c) (* #t (timer ?m1)))) ; the distance bewteen crate and loading bay decrease
    )

    ; If the loading bay is free, the movers put down the light/heavy crate
    (:action put_down_together
        :parameters (?m1 - obj ?m2 - obj ?c - obj ?loc - obj ?l - obj)
        :precondition (and (mover ?m1) (mover ?m2) (crate ?c) (location ?loc) (loader ?l) 
            ; Movers
            (not(= ?m1 ?m2)) ; the movers are different 
            (not(is_empty ?m1)) (not(is_empty ?m2)) ; the movers are not free
            
            ; Loader 
            (is_empty ?l) ; the loader is free

            ; Crate
            (is_pointed ?c ?m1) (is_pointed ?c ?m2) ; the crate is pointed by the movers
            (reached ?c) ; the crate reached the loading bay 

            ; Location
            (is_empty ?loc) ; the loading bay is free 
        )
        :effect (and (is_empty ?m1) (is_empty ?m2) ; the movers are free
            (not(is_pointing ?m1)) (not(is_pointing ?m2)) ; the movers are not pointing any crate
            (not(reached ?m1)) (not(reached ?m2)) ; the movers did not reach any crate

            (not(is_pointed ?c ?m1)) (not(is_pointed ?c ?m2)) ; the crate is not pointed by any mover
            (on_load ?c) ; the crate is on the loading bay 

            (not(is_empty ?loc)) ; the loading bay is not free
        )
    )
)