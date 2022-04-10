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
        location crate mover loader - object
        loading_bay - location
        conveyor_belt - location
        
    )


    (:predicates
        (at-mover ?m - mover ?t - location)
        (start_moving_to ?m - mover ?to - location)
        
        
        (mover_busy ?m - mover) ; robot r is busy 
        
        
        
        (loading_empty ?load - loading_bay)
        (loader_free ?l - loader)
        
        (is_pointed ?c - crate ?m- mover) ; crate c is pointed by robot r
        
        (crate_reached ?c - crate)
        (crate_pointed ?c - crate ?m - mover)
        (crate_delivering ?c -crate ?m - mover)
        (crate_delivered ?c - crate ?m - mover)
        
        (at-destination-crate ?c - crate ?b - conveyor_belt) ; crate c is at location 
        
        
    )

    (:functions
        (weight_crate ?c - crate) - number 
        (battery_level  ) - number
        (timer_approaching_crate ?m - mover) - number
        (timer_bringing_crate ?m - mover) - number
        (has_mover ?c - crate) - number
        
        
        (distance_crate_loadingbay  ?c ) - number ; distance between the crate and the loading bay
    
    )
    
    ; --- STARTING MOVER --- ;
    

    (:action pointing_crate
        :parameters (?m -mover ?c -crate)
        :precondition (and (not(mover_busy ?m))
                            (not (crate_reached ?c))
                            (not (crate_pointed ?c))
                    )
        :effect (and (mover_busy ?m) (crate_pointed ?c ?m) )
    )
    
    ; The mover moves against the crate 
    (:process move_empty
        :parameters (?m - mover ?c - crate)
        :precondition (and 
                        (crate_pointed ?c ?m)
                        (> (distance_cr ?c ?m) 0)
                        (= (time_approaching_crate ?m) 0)
                    )  
        :effect (and (increase (time_approaching_crate ?m) #t))
    )
    
    (:event reaching-crate
        :parameters (?m - mover ?c- crate )
        :precondition (and 
                        (crate_pointed ?c ?m)
                        (= (time_approaching_crate ?m) 10)
                        
                    ) 
        :effect (and (crate_reached ?c) (increase (has_mover ?c) 1) (assign (time_approaching_crate ?m) 0)
                )
    )
    
    
    ;;;;;;;;;;;; TAKING CRATE TO LOADING BAY;;;;;;;;;;;;;;;;
    
    (:action pick_light_crate
        :parameters (?m -mover ?c -crate)
        :precondition (and (crate_reached ?c)
                           (crate_pointed ?c ?m)
                           (not (crate_delivering ?c))
                           (not (crate_delivered ?c))
                           (= (has_mover ?c) 1)
                           (= (timer_bringing_crate ?m) 0)
                    )
        :effect (and (crate_delivering ?c))  
    )
    
    (:action pick_heavy_crate
        :parameters (?m1 - mover ?m2 - mover ?c - crate)
        :precondition (and (crate_reached ?c)
                           (crate_pointed ?c ?m1)
                           (crate_pointed ?c ?m2)
                           (not (crate_delivering ?c))
                           (not (crate_delivered ?c))
                           (= (has_mover ?c) 2)
                           (= (timer_bringing_crate ?m1) 0)
                           (= (timer_bringing_crate ?m2) 0)
                    )
        :effect (and (crate_delivering ?c)) )
    )
    
    ; The mover moves against the crate 
    (:process moving_crate
        :parameters (?m - mover ?c - crate )
        :precondition (and 
                        (crate_delivering ?c ?m)
                        (> (distance_crate_loadingbay ?c ) 0)
                        (> (weight_crate ?c) 0)
                        (= (timer_bringing_crate ?m) 0)
                    )  
        :effect (and (increase (timer_bringing_crate ?m) (/(*(distance_crate_loadingbay ?c)(weight_crate ?c) 100) #t))
    )
    
    (:event end_moving_crate
        :parameters (?m - mover ?c- crate )
        :precondition (and 
                        (crate_delivering ?c ?m)
                        (= (timer_bringing_crate ?m) (/(*(distance_crate_loadingbay ?c)(weight_crate ?c) 100))
                        
                    ) 
        :effect (and (not(crate_delivering ?c)) (crate_delivered ?c) (not(mover_busy))
                    (assign (timer_bringing_crate ?m) 0)
                )
    )
    ;;;;;;;;;;;;; PICKING UP ;;;;;;;;;;;;;;;
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