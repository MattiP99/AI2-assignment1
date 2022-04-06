(define (domain domainName)

    (:requirements
        :durative-actions
        :equality
        :negative-preconditions
        :numeric-fluents
        :object-fluents
        :typing
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
        :precondition (and (mover ?m)
                            (crate ?c) (empty ?m) (= (distance_cr ?c ?r) 0))
        :effect (and
            (not (empty ?m)))
        )
    
    ; il mover mette la cassa sulla loading bay, la distanza della cassa dalla loading_bay deve essere 0
   
    (:action put_down
        :parameters (?m ?c ?l)
        :precondition (and (mover ?m) (location ?l)
                            (crate ?c) (not(empty ?m)) (= (distance_cl ?c ?l) 0)
                            )
        :effect (and
            (empty ?m)
        )
    )
    
    ; il mover si sposta senza nulla in mano
    (:process move_empty
        :parameters (?m ?c)
        :precondition (and (crate ?c)
                            (mover ?m)(empty ?m) 
                            (> (distance_cr ?c ?r) 0)) 
                            
                            
        :effect (and (decrease (distance_cr ?c ?m) (* #t 10))
    )
    
    ; evento che parte quando il robot è vuoto e la distanza della cassa dalla loading bay è zero (occhio a putdown)
    ;PERCHè mi serve una variabile tempo QUA? IN REALTA non possiamo solo considerarla quando il robot sta tenendo qualcosa e 
    ; la distanza della cassa da robot è zero e la distanza della cassa dalla loading bay è massima (posizione della cassa)
    
    (:event event_empty
        :parameters (?m ?c)
        :precondition (and (crate ?c) (location ?l)
                            (mover ?m)(not(empty ?m))
                            (= (distance_cr ?c ?r) 0)
                            (>(distance_cl ?c ?l) 0)
                            (= (time ?m) 0)
                            ) 
                            
        :effect (and (assign (time) (/(*(distance_cl ?c ?l)(weight_crate ?c)) 100 )))
    )
    
    ; evento che parte quando il robot è dove ci sono le casse (riassegno la varibile tempo sapendo che cassa devo prendere)
    (:event event_crate
        :parameters (?m ?c)
        :precondition (and (crate ?c) (location ?l)
                            (mover ?m)(not(empty ?m))
                            (= (distance_cr ?c ?r) 0)
                            (>(distance_cl ?c ?l) 0)
                            (= (time ?m) 0)
                            ) 
                            
        :effect (and (assign (time) (/(*(distance_cl ?c ?l)(weight_crate ?c)) 100 )))
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