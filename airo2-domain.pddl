(define (domain airo2_group_k_domain)

    (:requirements
        :adl
        :typing
        :fluents
    )

    (:types 
		obj - Object ; general type
	)

    (:predicates
        ;(heavy ?c)

        (mover ?r - obj)
        (loader ?r - obj)
        (crate ?c - obj) 
        (location ?l - obj)
        
        (on_load ?c) ; the crate is on the loading bay
        (at_location ?c - obj) ; crate c is at location 
        (is_pointed ?c - obj ?r - obj) ; crate c is pointed by robot r
        (is_busy ?r - obj) ; robot r is busy 
        (is_empty ?rb - obj) ; robot r and/or loading bay b is empty 
    )

    (:functions
        (weight_crate ?c - obj) - number
        (timer ?r - obj) - number
        (distance_cl ?c - obj ?lb - obj) - number; distance between the crate and the loading bay
        (distance_cr ?c - obj ?r - obj) - number; distance between the crate and the robot
    )

    ; --- SINGLE MOVER AND LIGHT CRATE --- ; 
    
    ; The mover points to a light crate
    (:action pointing_light
        :parameters (?m1 - obj ?m2 - obj ?c - obj)
        :precondition (and (crate ?c) (mover ?m1) (mover ?m2)
                        (not(= ?m1 ?m2)) ; the movers are different
                        ;(not(heavy ?c))
                        (is_empty ?m1) 
                        (not(is_busy ?m1))
                        (not(is_pointed ?c ?m1)) 
                        (> (distance_cr ?c ?m1) 0)
                        (> (distance_cr ?c ?m2) 0) ; the other mover is not going against the same crate
                        (< (weight_crate ?c) 50) ; light crate
                        (= (timer ?m1) 0)
                    ) 
        :effect (and (is_busy ?m1) (is_pointed ?c ?m1) (assign (timer ?m1) 10))
    )

    ; EVENT TO SET THE TIMER
    
    ; The mover moves against the crate 
    (:process move_empty
        :parameters (?m - obj ?c - obj)
        :precondition (and (crate ?c) (mover ?m) 
                        (is_pointed ?c ?m) (is_busy ?m) ; action pointing_light
                        (> (distance_cr ?c ?m) 0) ; event set_timer
                        (= (timer ?m) 10)
                    )  
        :effect (and (decrease (distance_cr ?c ?m) (* (timer ?m) #t)))
    )

    ; The mover picks up the light crate when it has reached it
    (:action pick_up
        :parameters (?m - obj ?c - obj ?loc - obj)
        :precondition (and (mover ?m) (crate ?c) (location ?loc)
                        ;(not(heavy ?c))
                        (is_pointed ?c ?m) (is_busy ?m) (is_empty ?m)
                        (= (distance_cr ?c ?m) 0)
                    )
        :effect (and (not(is_empty ?m)) (assign (timer ?m) (/ (* (distance_cl ?c ?loc) (weight_crate ?c)) 100)))
    )

    ; EVENT TO SET THE TIMER
    
    ; After the pick_up, the robot start to move against the loading bay
    (:process move_full
        :parameters (?m - obj ?c - obj ?loc - obj)
        :precondition (and (crate ?c) (mover ?m) (location ?loc)
                        (not(is_empty ?m)) 
                        (> (distance_cl ?c ?loc) 0)
                        (> (timer ?m) 0)
                    )
        :effect (and (decrease (distance_cl ?c ?loc) (* (timer ?m) #t)))
    )

    ; If the loading bay is free, the mover puts down the light crate
    (:action put_down
        :parameters (?m - obj ?l - obj ?c - obj ?loc - obj)
        :precondition (and (mover ?m) (loader ?l) (crate ?c) (location ?loc)
                        (is_pointed ?c ?m) (not(is_empty ?m)) (is_busy ?m)
                        (is_empty ?loc) 
                        (is_empty ?l)
                        (= (distance_cl ?c ?loc) 0)
                    )
        :effect (and (is_empty ?m) (not(is_busy ?m)) (not(is_pointed ?c ?m)) (on_load ?c) (not(is_empty ?loc))
                    (assign (timer ?m) 0))
    )

    ; The loader pick up the crate from the loading bay
    (:action load
        :parameters (?c - obj ?l - obj ?loc - obj)
        :precondition (and (crate ?c) (loader ?l) (location ?loc)
                        (on_load ?c) 
                        (not(is_empty ?loc)) 
                        (not(is_pointed ?c ?l)) (is_empty ?l)
                        (= (timer ?l) 0)
                    )
        :effect (and (not(on_load ?c)) (is_empty ?loc) (not(is_empty ?l)) (is_pointed ?c ?l) (assign (timer ?l) 4))
    )

    ; EVENT TO SET THE TIMER
    
    ; The loader moves the crate from the loading bay to the conveyor belt
    (:process move_loader
        :parameters (?l - obj)
        :precondition (and (loader ?l) 
                        (not(is_empty ?l))
                        (> (timer ?l) 0)
                    )
        :effect (and (decrease (timer ?l) #t))
    )

    ; The loader put down the crate on the conveyor belt
    (:action unload
        :parameters (?l - obj ?c - obj)
        :precondition (and (loader ?l) (crate ?c)
                        (is_pointed ?c ?l) 
                        (not(is_empty ?l)) 
                        (= (timer ?l) 0)
                    )
        :effect (and (is_empty ?l) (not(is_pointed ?c ?l)) (at_location ?c))
    )

    ; --- HEAVY CRATE --- ;

    ; The mover points to a heavy crate ONLY IF also the other mover is free
    (:action pointing_heavy
        :parameters (?m1 - obj ?m2 - obj ?c - obj)
        :precondition (and (crate ?c) (mover ?m1) (mover ?m2)
                        (not(= ?m1 ?m2)) ; the movers are different
                        (is_empty ?m1) (not(is_busy ?m1)) (not(is_pointed ?c ?m1))
                        (is_empty ?m2) (not(is_busy ?m2)) (not(is_pointed ?c ?m2))
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

    ; EVENT TO SET THE TIMER

    ; PROCESS MOVE EMPTY TOGETHER

    ; The movers picks up the light/heavy crate when it has reached it
    (:action pick_up_together
        :parameters (?m1 - obj ?m2 - obj ?c - obj ?loc - obj)
        :precondition (and (crate ?c) (mover ?m1) (mover ?m2) (location ?loc)
                        (not (= ?m1 ?m2)) ; the movers are different
                        (is_empty ?m1) (is_empty ?m2)
                        (is_pointed ?c ?m1) (is_pointed ?c ?m2)
                        (is_busy ?m1) (is_busy ?m2)
                        (= (distance_cr ?c ?m1) 0) (= (distance_cr ?c ?m2) 0)
                    )
        :effect (and (not(is_empty ?m1)) (not(is_empty ?m2))
                    (assign (timer ?m1) (/(*(distance_cl ?c ?loc)(weight_crate ?c)) 150))
                    (assign (timer ?m2) (/(*(distance_cl ?c ?loc)(weight_crate ?c)) 150)))
    )

    ; EVENT TO SET THE TIMER
    
    ; PROCESS MOVE FULL TOGETHER
    (:process move_full_together
        :parameters (?m1 - obj ?m2 - obj ?c - obj ?loc - obj)
        :precondition (and (crate ?c) (mover ?m1) (mover ?m2) (location ?loc)
                        (not(= ?m1 ?m2)) ; the movers are different
                        (not(is_empty ?m1)) (is_pointed ?c ?m1) (is_busy ?m1)
                        (not(is_empty ?m2)) (is_pointed ?c ?m2) (is_busy ?m2)
                        (> (distance_cl ?c ?loc) 0)
                        (> (timer ?m1) 0)
                        (> (timer ?m2) 0)
                    )
        :effect (and (decrease (distance_cl ?c ?loc) (* (timer ?m1) #t)))
    )

    ; If the loading bay is free, the movers put down the light/heavy crate
    (:action put_down_together
        :parameters (?m1 - obj ?m2 - obj ?l - obj ?c - obj ?loc - obj)
        :precondition (and (mover ?m1) (mover ?m2) (loader ?l) (crate ?c) (location ?loc)
                        (not(= ?m1 ?m2)) 
                        (not(is_empty ?m1)) (not(is_empty ?m2))
                        (is_pointed ?c ?m1) (is_pointed ?c ?m2)
                        (is_busy ?m1) (is_busy ?m2)
                        (is_empty ?loc) (is_empty ?l)
                        (not(on_load ?c))
                        (= (distance_cl ?c ?loc) 0)
                    )
        :effect (and (on_load ?c) (is_empty ?m1) (is_empty ?m2) (not(is_busy ?m1)) (not(is_busy ?m2))
                        (not(is_pointed ?c ?m1)) (not(is_pointed ?c ?m2)) (not(is_empty ?loc)))
    )

    ; LOADER PART
)