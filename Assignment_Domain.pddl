(define (domain Assignment_Domain)

    (:requirements
        :durative-actions
        :equality
        :negative-preconditions
        :numeric-fluents
        :object-fluents
        :typing
    )

    (:types
        
    )
    
    (:constants
        
    )

    (:predicates
        (mover ?r)
        (loader ?r)
        (crate ?c) 
        (location ?l)
        (empty ?rb) ; robot r and/or loading bay b is empty 
        (at_location ?c) ; crate c is at location 
        (is_pointed ?c ?r) ; crate c is pointed by robot r
        (is_busy ?r) ; robot r is busy 
    )

    (:functions
        (weight_crate) - number 
        (battery_level) - number
        (time ?r) - number
        (distance_cl  ?c ?lb) - number ; distance between the crate and the loading bay
        (distance_cr  ?c ?r) - number ; distance between the crate and the robot
    )
    
    ; --- ACTIONS --- ;
    
    ; The mover picks up the crate when it has reached it
    (:action pick_up
        :parameters (?m ?c)
        :precondition (and (crate ?c) (mover ?m)
                        (= (distance_cr ?c ?r) 0)
                    )
        :effect (and (not(empty ?m)))
    )
    
    ; If the loading bay if free, the mover puts down the crate
    (:action put_down
        :parameters (?m ?load ?c ?l)
        :precondition (and (mover ?m) (loader ?load) (crate ?c) (location ?l)
                        (empty ?l) (empty ?load)
                        (= (distance_cl ?c ?l) 0)
                    )
        :effect (and (empty ?m) (not(empty ?l)) (not(is_busy ?m)))
    )
    
    ; The loader pick up the crate from the loading bay
    (:action load
        :parameters (?load ?l)
        :precondition (and (loader ?load) (location ?l)
                        (not(empty ?l)) (empty ?load)
                        (= (time ?load) 4)
                    )
        :effect (and (empty ?l) (not(empty ?load)))
    )
    
    ; The loader put down the crate on the conveyor belt
    (:action unload
        :parameters (?load ?c)
        :precondition (and (loader ?load) (crate ?c)
                        (not(empty ?load)) (= (time ?load) 0)
                    )
        :effect (and (empty ?load) (at_location ?c))
    )
    
    ; --- EVENTS --- ; 
    
    ; The mover points to a light crate
    (:event pointing_light
        :parameters (?m ?c ?l)
        :precondition (and (crate ?c) (location ?l) (mover ?m)
                        (empty ?m) (not(is_busy ?m)) ; (not(is_pointed ?c ?m2))
                        (> (distance_cr ?c ?m) 0)
                        (< (weight_crate) 50)
                        (= (time ?m) 0)
                    ) 
        :effect (and (assign (time ?m) 10) (is_busy ?m) (is_pointed ?c ?m))
    )
    
    ; The mover points to a heavy crate ONLY IF also the other mover is free
    (:event pointing_heavy
        :parameters (?m1 ?m2 ?c ?l)
        :precondition (and (crate ?c) (location ?l)
                        (mover ?m1) (empty ?m1) (not(is_busy ?m1))
                        (mover ?m2) (empty ?m2) (not(is_busy ?m2))
                        (> (distance_cr ?c ?m1) 0)
                        (> (distance_cr ?c ?m2) 0)
                        (>= (weight_crate) 50)
                        (= (time ?m1) 0)
                        (= (time ?m2) 0)
                    ) 
        :effect (and (assign (time ?m1) 10) (assign (time ?m2) 10)
                    (is_busy ?m1) (is_busy ?m2)
                    (is_pointed ?c ?m1) (is_pointed ?c ?m2)
                )
    )
    
    ; The mover reached the crate
    (:event reached_crate
        :parameters (?m ?c ?l)
        :precondition (and (crate ?c) (location ?l) (mover ?m)
                        (= (distance_cr ?c ?m) 0)
                        (> (distance_cl ?c ?l) 0)
                        (= (time ?m) 10)
                    ) 
        :effect (and (assign (time ?m) (/(*(distance_cl ?c ?l)(weight_crate ?c)) 100)))
    )
    
    ; The mover reached the loading bay with the crate
    (:event reached_loading_bay
        :parameters (?m ?c ?l)
        :precondition (and (crate ?c) (location ?l) (mover ?m)
                        (= (distance_cl ?c ?l) 0)
                        (> (time ?m) 0)
                    ) 
        :effect (and (assign (time ?m) 0))
    )
    
    ; The loading bay is full
    (:event start_loader
        :parameters (?load ?l)
        :precondition (and (loader ?load) (location ?l) 
                        (not(empty ?l)) (= (time ?load) 0)
                    )
        :effect (and (assign (time ?load) 4))
    )
    
    ; --- PROCESSES --- ;
    
    ; The mover moves against the crate 
    (:process move_empty
        :parameters (?m ?c)
        :precondition (and (crate ?c) (mover ?m) 
                        (empty ?m) (is_pointed ?c ?m)
                        (> (distance_cr ?c ?m) 0)
                        (< (weight_crate ?c) 50)
                        (> (time ?m) 0)
                    )  
        :effect (and (decrease (distance_cr ?c ?m) (* #t (time))))
    )
    
    ; After the pick_up, the robot start to move against the loading bay
    (:process move_full
        :parameters (?m ?c ?l)
        :precondition (and (crate ?c) (mover ?m) (location ?l)
                        (not(empty ?m)) 
                        (> (distance_cl ?c ?l) 0)
                        (> (time ?m) 0)
                    )
        :effect (and (decrease (distance_cl ?c ?l) (* #t (time ?m))))
    )
    
    ; The loader moves the crate from the loading bay to the conveyor belt
    (:process move_loader
        :parameters (?load ?l)
        :precondition (and (loader ?load) (location ?l)
                        (> (time ?m) 0)
                    )
        :effect (and (decrease (time ?load) (* #t 1)))
    )
)