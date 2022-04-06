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
     (empty ?bay_robot)
     (at_location ?c)
     (isPointed ?c ?r)
     (is_busy ?r)
    )

    (:functions
        (weight_crate) - number
        (battery_level) - number
        (time ?r) - number
        (distance_cl  ?crate ?loading_bay) - number
        (distance_cr  ?crate ?robot) - number
        
    )
    
    ; il mover prende la cassa dalla posizione iniziale , la distanza del cassa dal robot deve essere 0
    (:action pick_up
        :parameters (?m ?c)
        :precondition (and (crate ?c)
                            (mover ?m) (empty ?m) 
                            (= (distance_cr ?c ?m) 0))
                            
        :effect (and
            (not (empty ?m)))
        )
        
    
    ; il mover mette la cassa sulla loading bay, la distanza della cassa dalla loading_bay deve essere 0
   
    (:action put_down
        :parameters (?m ?c ?l)
        :precondition (and (mover ?m) (not(empty ?m))
                        (crate ?c)
                        (location ?l) (= (distance_cl ?c ?l) 0)
                          
                            )
        :effect (and
            (empty ?m)
        )
    )
    
   
    
    ; evento che parte quando il robot è vuoto e la distanza della cassa dalla loading bay è zero (occhio a putdown)
    ; EVENTO che assegna al tempo una costante = 10 perchè si muove senza carico
    (:event event_empty_light
        :parameters (?m ?c ?l)
        :precondition (and (crate ?c) (location ?l)
                            (mover ?m)(empty ?m) (not(is_busy ?m))
                            (> (distance_cr ?c ?r) 0)
                            (< (weight_crate) 50)
                            (= (time ?m) 0)
                            ) 
                            
        :effect (and (assign (time ?m) 10) (is_busy ?m))
    )
    (:event event_empty_heavy
        :parameters (?m1 ?m2 ?c ?l)
        :precondition (and (crate ?c) (location ?l)
                            (mover ?m1)(empty ?m1) (not(is_busy ?m1))
                            (mover ?m2)(empty ?m2) (not(is_busy ?m2))
                            (> (distance_cr ?c ?m1) 0)
                            (> (distance_cr ?c ?m2) 0)
                            (>= (weight_crate) 50)
                            (= (time ?m1) 0)
                            (= (time ?m2) 0)
                            ) 
                            
        :effect (and (assign (time ?m) 10) (is_busy ?m1) (is_busy ?m2))
    )
    ; Assegno il tempo a zero quando arrivo alla cassa. Cassa non ancora presa 
    (:event event_zero_time
        :parameters (?m ?c )
        :precondition (and (crate ?c) 
                            (mover ?m) (empty ?m)
                            (= (distance_cr ?c ?r) 0)
                            (> (time ?m) 0)
                            ) 
                            
        :effect (and (assign (time ?m) 0))
    )
    
    ; evento che parte quando il robot è dove ci sono le casse e serve dopo che la cassa è stata presa (riassegno la varibile tempo sapendo che cassa devo prendere)
    (:event event_crate_light
        :parameters (?m ?c ?l)
        :precondition (and (crate ?c) (location ?l) (not(isPointed ?c ?m)
                            (mover ?m)(not(empty ?m)) 
                            (= (distance_cr ?c ?r) 0)
                            (>(distance_cl ?c ?l) 0)
                            (= (time ?m) 0)
                            ) 
                            
        :effect (and (assign (time ?m) (/(*(distance_cl ?c ?l)(weight_crate ?c)) 100 )) (isPointed ?c ?m) )
    )
    
    (:event event_crate_heavy
        :parameters (?m ?c ?l)
        :precondition (and (crate ?c) (location ?l) (not(isPointed ?c ?m)
                            (mover ?m)(not(empty ?m)) (not(is_busy ?m))
                            (= (distance_cr ?c ?r) 0)
                            (>(distance_cl ?c ?l) 0)
                            (= (time ?m) 0)
                            ) 
                            
        :effect (and (assign (time ?m) (/(*(distance_cl ?c ?l)(weight_crate ?c)) 150 )) (isPointed ?c ?m))
    )
    
     ; il mover si sposta senza nulla in mano
    (:process move_empty_light
        :parameters (?m ?c)
        :precondition (and (crate ?c) 
                            (mover ?m)(empty ?m) 
                            (> (distance_cr ?c ?m) 0)
                            (<(weight_crate ?c) 50)
                            (> (time ?m) 0)
                          )  
                            
        :effect (and (decrease (distance_cr ?c ?m) (* #t (time))) (isPointed ?c))
    )
    
    (:process move_empty_heavy
        :parameters (?m1 ?m2 ?c)
        :precondition (and (crate ?c) (not(isPointed ?c ?m1) (not(isPointed ?c ?m2))
                            (mover ?m1)(empty ?m1) 
                            (mover ?m2)(empty ?m2) 
                            (> (distance_cr ?c ?m1) 0)
                            (> (distance_cr ?c ?m2) 0)
                            (>= (weight_crate ?c) 50) 
                            (> (time) 0)
                            
                            
        :effect (and (decrease (distance_cr ?c ?m1) (* #t (time))) 
                     (decrease (distance_cr ?c ?m2) (* #t (time)))
                         (isPointed ?c ?m1) (isPointed ?c ?m2))
    )
    
    
    (:process move_light
        :parameters (?m ?c ?l)
        :precondition (and (crate ?c) (mover ?m)(location ?l)
                            (not(empty ?m)) 
                            (> (distance_cl ?c ?l) 0)
                            (assign (time) (/(*(distance_cl ?c ?l)(weight_crate ?c)) 100 )))
                            
        :effect (and (decrease (distance_cl ?c ?l) (*#t (time))))
    )
    
    (:process move_heavy
        :parameters (?r - foo)
        :precondition (and (foo) (fuu))
        :effect (and (fii) (fee))
    )
)