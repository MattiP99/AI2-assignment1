(define (domain airo2_group_k_domain)

    (:requirements
        :adl
        :typing
        :fluents
        ;:time
    )

    (:types 
		obj - Object
	)

    (:predicates
        (mover ?r - obj)
        (loader ?r - obj)
        (crate ?c - obj) 
        (location ?l - obj)
        (empty ?rb - obj) ; robot r and/or loading bay b is empty 
        (at_location ?c - obj) ; crate c is at location 
        (is_pointed ?c - obj ?r - obj) ; crate c is pointed by robot r
        (is_busy ?r - obj) ; robot r is busy 
    )

    (:functions
        (weight_crate ?c - obj) - number
        ; (battery_level)
        (timer ?r - obj) - number
        (distance_cl ?c - obj ?lb - obj) - number; distance between the crate and the loading bay
        (distance_cr ?c - obj ?r - obj) - number; distance between the crate and the robot
    )
    
    ; --- ACTIONS --- ;
    
    ; The mover picks up the crate when it has reached it
    (:action pick_up
        :parameters (?m - obj ?c - obj)
        :precondition (and (crate ?c) (mover ?m)
                        (= (distance_cr ?c ?m) 0)
                    )
        :effect (and (not(empty ?m)))
    )
    
    ; If the loading bay if free, the mover puts down the crate
    (:action put_down
        :parameters (?m - obj ?l - obj ?c - obj ?loc - obj)
        :precondition (and (mover ?m) (loader ?l) (crate ?c) (location ?loc)
                        (empty ?loc) (empty ?l)
                        (= (distance_cl ?c ?loc) 0)
                    )
        :effect (and (empty ?m) (not(empty ?loc)) (not(is_busy ?m)))
    )
    
    ; The loader pick up the crate from the loading bay
    (:action load
        :parameters (?l - obj ?loc - obj)
        :precondition (and (loader ?l) (location ?loc)
                        (not(empty ?loc)) (empty ?l)
                        (= (timer ?l) 4)
                    )
        :effect (and (empty ?loc) (not(empty ?l)))
    )
    
    ; The loader put down the crate on the conveyor belt
    (:action unload
        :parameters (?l - obj ?c - obj)
        :precondition (and (loader ?l) (crate ?c)
                        (not(empty ?l)) (= (timer ?l) 0)
                    )
        :effect (and (empty ?l) (at_location ?c))
    )
    
    ; --- EVENTS --- ; 
    
    ; The mover points to a light crate
    (:event pointing_light
        :parameters (?m - obj ?c - obj)
        :precondition (and (crate ?c) (mover ?m)
                        (empty ?m) (not(is_busy ?m)) ; (not(is_pointed ?c ?m2))
                        (> (distance_cr ?c ?m) 0)
                        (< (weight_crate ?c) 50)
                        (= (timer ?m) 0)
                    ) 
        :effect (and (assign (timer ?m) 10) (is_busy ?m) (is_pointed ?c ?m))
    )
    
    ; The mover points to a heavy crate ONLY IF also the other mover is free
    (:event pointing_heavy
        :parameters (?m1 - obj ?m2 - obj ?c - obj)
        :precondition (and (crate ?c) (mover ?m1) (mover ?m2)
                        (empty ?m1) (not(is_busy ?m1))
                        (empty ?m2) (not(is_busy ?m2))
                        (> (distance_cr ?c ?m1) 0)
                        (> (distance_cr ?c ?m2) 0)
                        (>= (weight_crate ?c) 50)
                        (= (timer ?m1) 0)
                        (= (timer ?m2) 0)
                    ) 
        :effect (and (assign (timer ?m1) 10) (assign (timer ?m2) 10)
                    (is_busy ?m1) (is_busy ?m2)
                    (is_pointed ?c ?m1) (is_pointed ?c ?m2)
                )
    )
    
    ; The mover reached the crate
    (:event reached_crate
        :parameters (?m - obj ?c - obj ?loc - obj)
        :precondition (and (crate ?c) (location ?loc) (mover ?m)
                        (= (distance_cr ?c ?m) 0)
                        (> (distance_cl ?c ?loc) 0)
                        (= (timer ?m) 10)
                    ) 
        :effect (and (assign (timer ?m) (/(*(distance_cl ?c ?loc)(weight_crate ?c)) 100)))
    )
    
    ; The mover reached the loading bay with the crate
    (:event reached_loading_bay
        :parameters (?m - obj ?c - obj ?loc - obj)
        :precondition (and (crate ?c) (location ?loc) (mover ?m)
                        (= (distance_cl ?c ?loc) 0)
                        (> (timer ?m) 0)
                    ) 
        :effect (and (assign (timer ?m) 0))
    )
    
    ; The loading bay is full
    (:event start_loader
        :parameters (?l - obj ?loc - obj)
        :precondition (and (loader ?l) (location ?loc) 
                        (not(empty ?loc)) (= (timer ?l) 0)
                    )
        :effect (and (assign (timer ?l) 4))
    )
    
    ; --- PROCESSES --- ;
    
    ; The mover moves against the crate 
    (:process move_empty
        :parameters (?m - obj ?c - obj)
        :precondition (and (crate ?c) (mover ?m) 
                        (empty ?m) (is_pointed ?c ?m)
                        (> (distance_cr ?c ?m) 0)
                        (< (weight_crate ?c) 50)
                        (> (timer ?m) 0)
                    )  
        :effect (and (decrease (distance_cr ?c ?m) (* #t (timer))))
    )
    
    ; After the pick_up, the robot start to move against the loading bay
    (:process move_full
        :parameters (?m - obj ?c - obj ?loc - obj)
        :precondition (and (crate ?c) (mover ?m) (location ?loc)
                        (not(empty ?m)) 
                        (> (distance_cl ?c ?loc) 0)
                        (> (timer ?m) 0)
                    )
        :effect (and (decrease (distance_cl ?c ?loc) (* #t (timer ?m))))
    )
    
    ; The loader moves the crate from the loading bay to the conveyor belt
    (:process move_loader
        :parameters (?l - obj ?loc - obj)
        :precondition (and (loader ?l) (location ?loc)
                        (> (timer ?l) 0)
                    )
        :effect (and (decrease (timer ?l) (* #t 1)))
    )
)