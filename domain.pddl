
(define (domain airo2_group_k_domain)
    
    (:requirements :equality :time :typing :adl :fluents :derived-predicates :negative-preconditions  
    )

    (:types
        location crate group mover loader - object
        weak_loader strong_loader - loader
        loading_bay - location
        conveyor_belt - location
        
    )


    (:predicates
       
        (mover_busy ?m - mover) ; robot r is busy 
        (equal ?m1 - mover ?m2 - mover)
        (different_crate ?c1 - crate ?c2 - crate)

        ;---- IT COULD BE USEFULL WHEN A MOVER HAS REACHED A ---;
        ;---- CRATE BUT THE OTHER IS STILL BUSY WITH AN OTHER CRATE-----;
        ;   When a mover is reaching a heavy crate alone it needs help while
        ;   when it has reached the heavy crate alone it is waiting for help
        ;   I need two parameters because when the robot is waiting the help it doesn't consume battery
        ;   but when it is approching the crate the other mover has to see that its friend need help and can start moving towards the 
        ;   same crate without waiting for the other robot having reached it

        (mover_need_help ?c - crate ?m - mover)
        (mover_waiting_for_help ?c - crate ?m - mover ) 

        ;--- USEFULL WHEN A MOVER IS HOLDING A CRATE BUT THE LOADING BAY IS FULL---;
        ;--- IN THIS CASE THE BATTERY LEVEL DOESN'T DECREASEM----;
        
        (mover_waiting_for_free_loadingbay ?m - mover)
        

        (loader_free ?l - loader)
        ;(weak_loader ?l - loader) maybe I need only the strong characteristic
        (strong_loader ?l - loader)
        
        (crate_light_reached ?c - crate ?m - mover)
        (crate_light_pointed ?c - crate ?m - mover)
        (crate_light_delivering ?c -crate ?m - mover)
        (crate_light_delivered ?m - mover)

        (crate_heavy_reached ?c - crate ?m - mover)
        (crate_heavy_pointed ?c - crate ?m - mover)
        (crate_heavy_delivering ?c -crate ?m - mover)
        (crate_heavy_delivered ?m - mover)
        
        (crate_has_two_movers ?c)
        
        (at-destination-crate ?c - crate) ; crate c is at conveyor_belt 
        
        
    )

    (:functions
        (weight_crate ?c - crate) - number ; the weight of a certain crate
        (fl-fragile-crate ?c - crate) - number ; this can be 0 or 1 for not fragile or fragile crates respectively
        (distance_cl  ?c - crate) - number ; distance between the crate and the loading bay
        (battery_level ?m - mover) - number
        
        
        (timer_approaching_crate ?m - mover) - number
        (timer_bringing_crate ?m - mover) - number
        (timer_loading_crate ?c - crate ?l - loader) - number
        (timer_waiting_for_free_loadingbay ?m - mover) - number 

        (loading_has_crate ?l - loading_bay) - number ; counter for light crates on the loading bay
    )
    
    ; --- INSTANTANEOUS CHARGING --- ;
    ; If the mover points a certain crate and sees that its battery is not sufficient to drive towards the crate and bringing it back to 
    ; the loading_bay, decides to recharge.

    (:action activate-charger-light
        :parameters (?m - mover ?c - crate)
        :precondition (and  (not(mover_busy ?m))
                             (crate_light_pointed ?c ?m)
                             (< (battery_level ?m) (+(/(distance_cl ?c) 10) (/(*(distance_cl ?c) (weight_crate ?c)) (+ (*(fl-fragile-crate ?c) 50 ) 100))))
        )
        ;refill battery_level at maximum        
        :effect (and(assign (battery_level ?m) 20))
    )

    (:action activate-charger-heavy
        :parameters (?m - mover ?c - crate)
        :precondition (and  (not(mover_busy ?m))
                            (crate_heavy_pointed ?c ?m) 
                            (< (battery_level ?m) (+(/(distance_cl ?c) 10) (/(*(distance_cl ?c) (weight_crate ?c)) (+ (*(fl-fragile-crate ?c) 50 ) 100 ))))
        )
        ;refill battery_level at maximum        
        :effect (and(assign (battery_level ?m) 20))
    )

    
    ;----- PROCESS FOR DECREASING BATTERY LEVEL--------;
    (:process battery_level_decreasing
        :parameters (?m - mover ?c - crate)
        :precondition (and 
                        (not(mover_waiting_for_free_loadingbay ?m))
                        (not(mover_waiting_for_help ?c ?m))
                        (mover_busy ?m)
                    )  
        :effect (and (decrease (battery_level ?m) #t))
    )


    ; --- STARTING MOVER FOR LIGHT--- ;
    
    (:action pointing_light_crate
        :parameters (?m -mover ?m2 -mover ?c -crate)
        :precondition (and (not(mover_busy ?m))
                            (< (weight_crate ?c) 50)
                            (not (at-destination-crate ?c))
                            (not(crate_light_delivered ?c))
                            (not (crate_light_reached ?c ?m))
                            (not (crate_light_pointed ?c ?m))
                             (not (crate_light_pointed ?c ?m2))
                             (not(equal ?m ?m2))
                            (>= (battery_level ?m) (+(/(distance_cl ?c) 10) (/(*(distance_cl ?c) (weight_crate ?c)) (+ (*(fl-fragile-crate ?c) 50 ) 100 ))))
                    )
        :effect (and (mover_busy ?m) (crate_light_pointed ?c ?m) )
    )
    
    


    ; The mover moves against the crate for a light and for an heavy
    (:process move_empty_mover_for_light
        :parameters (?m - mover ?c - crate)
        :precondition (and 
                        (crate_light_pointed ?c ?m)
                        (mover_busy ?m)
                        (= (timer_approaching_crate ?m) 0)
                        
                        ;(> (distance_cr ?c ?m) 0)
                        
                    )  
        :effect (and (increase (timer_approaching_crate ?m) #t))
    )
    
    (:event e_reached_light_crate
        :parameters (?m - mover ?c - crate )
        :precondition (and 
                        (not(crate_light_reached ?c ?m))
                        (crate_light_pointed ?c ?m)
                        (= (timer_approaching_crate ?m) (/ (distance_cl ?c) 10))
                        
                    ) 
        :effect (and (crate_light_reached ?c ?m)    
                (assign (timer_approaching_crate ?m) 0)
                )
    )
    
    ; --- STARTING SINGLE MOVER FOR HEAVY --- ;
    ; a single mover can point an heavy crate but it has to control that an other mover has reached/ or pointed
    
    (:action pointing_heavy_crate_single
        :parameters (?m1 -mover ?m2 -mover ?c -crate ?c2 - crate)
        :precondition (and  
                            (>= (weight_crate ?c) 50)
                            
                            (not(equal ?m1 ?m2))
                            (different_crate ?c ?c2)
                            (not(crate_heavy_delivered ?c))
                            
                            (not (crate_heavy_reached ?c ?m1))
                            (not (crate_heavy_pointed ?c ?m1))
                            (not(mover_need_help ?c ?m1))
			     (not(mover_busy ?m1))
                            
                            (mover_busy ?m2)
                            (not (crate_heavy_reached ?c ?m2))
                            (not (crate_heavy_pointed ?c ?m2))
                            
                            (not(mover_need_help ?c2 ?m2)) ; chaeck if the other mover need help for an other crate
                            
                            (>= (battery_level ?m1) (+(/(distance_cl ?c) 10) (/(*(distance_cl ?c) (weight_crate ?c)) (+ (*(fl-fragile-crate ?c) 50 ) 100 ))))

                            
                    )
        :effect (and (mover_busy ?m1) (crate_heavy_pointed ?c ?m1) (mover_need_help ?c ?m1))
    )

    ; The mover moves against the heavy crate 
    (:process move_empty_mover_for_heavy
        :parameters (?m - mover ?c - crate)
        :precondition (and 
                        (crate_heavy_pointed ?c ?m)
                        (mover_busy ?m)
                        (= (timer_approaching_crate ?m) 0)
                        (mover_need_help ?c ?m)
                        
                        
                    )  
        :effect (and (increase (timer_approaching_crate ?m) #t))
    )

    (:event e_reached_heavy_crate
        :parameters (?m1 - mover  ?c - crate )
        :precondition (and (crate_heavy_pointed ?c ?m1)
                        (not(crate_heavy_reached ?c ?m1))
                        (mover_need_help ?c ?m1)
                        (>= (timer_approaching_crate ?m1) (/(distance_cl ?c) 10))
                        
                    ) 
        :effect (and (crate_heavy_reached ?c ?m1)
                (mover_waiting_for_help ?c ?m1)
                (assign (timer_approaching_crate ?m1) 0) 
                )
    )

    ; --- STARTING SINGLE MOVER FOR HELP THE OTHER MOVER WITH A HEAVY CRATE --- ;

     ; we need this for helping a mover that has pointed a heavy crate alone
    (:action pointing_heavy_crate_single_for_help
        :parameters (?m1 -mover ?m2 -mover ?c -crate)
        :precondition (and (>= (weight_crate ?c) 50)
                            (mover_busy ?m1)
                            (mover_need_help ?c ?m1)
                            (crate_heavy_pointed ?c ?m1)
                            (not(crate_heavy_delivering ?c ?m1))
                            (not(crate_heavy_delivered ?c))
                            
                            (not(equal ?m1 ?m2))
                            (not(mover_busy ?m2))
                            (not (crate_heavy_reached ?c ?m2))
                            (not (crate_heavy_pointed ?c ?m2))
                            
                            (>= (battery_level ?m2) (+ (/ (distance_cl ?c) 10) (/(*(distance_cl ?c) (weight_crate ?c)) (+ (*(fl-fragile-crate ?c) 50 ) 100 ))))

                            
                            
                    )
        :effect (and (mover_busy ?m2) (crate_heavy_pointed ?c ?m2))
    )
    
    ; The mover moves against the crate for HELP 
    (:process move_empty_mover_for_heavy_for_help
        :parameters (?m1 - mover ?m2 - mover ?c - crate)
        :precondition (and 
                        (mover_busy ?m1)
                        (mover_busy ?m2)
                        (not(equal ?m1 ?m2))
                        (crate_heavy_pointed ?c ?m1)
                        (crate_heavy_pointed ?c ?m2)

                        (mover_need_help ?c ?m1)
                        (= (timer_approaching_crate ?m2) 0)
                    )  
        :effect (and (increase (timer_approaching_crate ?m2) #t)
                     )
    )

    (:event e_reached_heavy_crate_for_help
        :parameters (?m1 - mover ?m2 - mover ?c - crate )
        :precondition (and 
        		
        		 (not(equal ?m1 ?m2))
                        (crate_heavy_pointed ?c ?m1)
                        (crate_heavy_reached ?c ?m1)
                        (mover_need_help ?c ?m1)
                        
                        (crate_heavy_pointed ?c ?m2)
                        (not(crate_heavy_reached ?c ?m2))
                        (>= (timer_approaching_crate ?m2) (/(distance_cl ?c) 10))
                        
                    ) 
        :effect (and (crate_heavy_reached ?c ?m2) 
                     (assign (timer_approaching_crate ?m2) 0) 
                     (crate_has_two_movers ?c) 
                     (not(mover_need_help ?c ?m1))
                     (not(mover_waiting_for_help ?c ?m1))
                )
    )
     
    
    
    ; --- STARTING TWO MOVERS FOR HEAVY --- ;
    (:action pointing_heavy_crate_two_movers
        :parameters (?m1 - mover ?m2 - mover ?c - crate)
        :precondition (and (not(mover_busy ?m1))
                            (not(mover_busy ?m2))
                             (not(equal ?m1 ?m2))
                            (>= (weight_crate ?c) 50)
                            (not (crate_heavy_reached ?c ?m1))
                            (not (crate_heavy_pointed ?c ?m1))
                            (not (crate_heavy_reached ?c ?m2))
                            (not (crate_heavy_pointed ?c ?m2))
                            (not(crate_heavy_delivered ?c))
                    )
        :effect (and (mover_busy ?m1) (crate_heavy_pointed ?c ?m1)
                        (mover_busy ?m2) (crate_heavy_pointed ?c ?m2))
    )
    
    (:process move_empty_movers_for_heavy
        :parameters (?m1 - mover ?m2 - mover ?c - crate)
        :precondition (and 
                        (crate_heavy_pointed ?c ?m1)
                        (crate_heavy_pointed ?c ?m2)
                        (not (crate_heavy_reached ?c ?m1))
                        (not (crate_heavy_reached ?c ?m2))
                        (not(crate_heavy_delivered ?c))
                        
                        (not(equal ?m1 ?m2))
                        (mover_busy ?m1)
                        (mover_busy ?m2)
                        
                        (= (timer_approaching_crate ?m1) 0)
                        (= (timer_approaching_crate ?m2) 0)
                        
                    )  
        :effect (and (increase (timer_approaching_crate ?m1) #t)
                     (increase (timer_approaching_crate ?m2) #t))
    )
    
    
    (:event e_reached_heavy_crate_two_movers
        :parameters (?m1 - mover ?m2 - mover ?c - crate )
        :precondition (and 
                        (crate_heavy_pointed ?c ?m1)
                        (not(crate_heavy_reached ?c ?m1))
                        
                        
                        (crate_heavy_pointed ?c ?m2)
                        (not(crate_heavy_reached ?c ?m2))
                        (not(crate_heavy_delivered ?c))
                        (not(equal ?m1 ?m2))
                        (mover_busy ?m1)
                        (mover_busy ?m2)
                        ; MAYBE THIS IS WRONG BECAUSE THEY CANNOT BE SIMULTANEOUSLY = dist.....
                        (= (timer_approaching_crate ?m2) (/(distance_cl ?c) 10))
                        (= (timer_approaching_crate ?m2) (/(distance_cl ?c) 10))
                        
                    ) 
        :effect (and (crate_heavy_reached ?c ?m1) 
                    (crate_heavy_reached ?c ?m2) 
                     (assign (timer_approaching_crate ?m1) 0) 
                     (assign (timer_approaching_crate ?m2) 0) 
                     (crate_has_two_movers ?c) 
                     
                )
    )
    
    

    ;;;;;;;;;;;; TAKING LIGHT CRATE TO LOADING BAY;;;;;;;;;;;;;;;;
    
    (:action pick_light_crate
        :parameters (?m -mover ?c -crate)
        :precondition (and (crate_light_reached ?c ?m)
                           (not (crate_light_delivering ?c ?m))
                           (not (crate_light_delivered ?c))
                           (= (timer_bringing_crate ?m) 0)
                    )
        :effect (and (crate_light_delivering ?c ?m))  
    )
    
    
    
    ; The mover moves against the crate (I CAN MAYBE NEED ONLY ONE FUNCTION OF THIS)
    (:process bringing_light_crate
        :parameters (?m - mover ?c - crate )
        :precondition (and 
                        (crate_light_delivering ?c ?m)
                        (> (distance_cl ?c ) 0)
                        (> (weight_crate ?c) 0)
                        (= (timer_bringing_crate ?m) 0)
                    )  
        :effect (and (increase (timer_bringing_crate ?m) #t))
    )
    
    (:event end_bringing_light_crate
        :parameters (?m - mover ?c - crate )
        :precondition (and 
                        (crate_light_delivering ?c ?m)
                        (= (timer_bringing_crate ?m) (/(*(distance_cl ?c) (weight_crate ?c)) (+ (*(fl-fragile-crate ?c) 50 ) 100 )))
                        
                    ) 
        :effect (and (mover_waiting_for_free_loadingbay ?m) ; since I've put this the battery level doesn't decrease anymore
                    (assign (timer_bringing_crate ?m) 0)
                )
    )
    

    ;;;;;;;;;;;; TAKING HEAVY CRATE TO LOADING BAY;;;;;;;;;;;;;;;;

    (:action pick_heavy_crate
        :parameters (?m1 - mover ?m2 - mover ?c - crate)
        :precondition (and 
                           (crate_heavy_reached ?c ?m1)
                           (crate_has_two_movers ?c)
                           (not (crate_heavy_delivering ?c ?m1))
                           (not (crate_heavy_delivering ?c ?m2))
                           (not (crate_heavy_delivered ?c))
                           
                          
                           (= (timer_bringing_crate ?m1) 0)
                           (= (timer_bringing_crate ?m2) 0)
                    )
        :effect (and (crate_heavy_delivering ?c ?m1) (crate_heavy_delivering ?c ?m2) )
    )

    (:process bringing_heavy_crate
        :parameters (?m1 - mover ?m2 - mover ?c - crate )
        :precondition (and 
                        (crate_heavy_delivering ?c ?m1)
                        (crate_heavy_delivering ?c ?m2)
                        (> (weight_crate ?c) 0) ; I think it is redundant
                        (= (timer_bringing_crate ?m1) 0)
                        (= (timer_bringing_crate ?m2) 0)
                    )  
        :effect (and (increase (timer_bringing_crate ?m1) #t)
                     (increase (timer_bringing_crate ?m2) #t)
        )
    )
    
    (:event end_bringing_heavy_crate
        :parameters (?m1 - mover ?m2 - mover ?c - crate )
        :precondition (and 
                        (crate_heavy_delivering ?c ?m1)
                        (crate_heavy_delivering ?c ?m2)
                        (= (timer_bringing_crate ?m1) (/(*(distance_cl ?c) (weight_crate ?c)) (+ (*(fl-fragile-crate ?c) 50 ) 100 )))
                        (= (timer_bringing_crate ?m2) (/(*(distance_cl ?c) (weight_crate ?c)) (+ (*(fl-fragile-crate ?c) 50 ) 100 )))
                        
                    ) 
        :effect (and 
                        (not(crate_heavy_delivering ?c ?m1))
                        (not(crate_heavy_delivering ?c ?m2))
                        (mover_waiting_for_free_loadingbay ?m1) ; since I've put this the battery level doesn't decrease anymore
                     (mover_waiting_for_free_loadingbay ?m2)
                     (assign (timer_bringing_crate ?m1) 0)
                     (assign (timer_bringing_crate ?m2) 0)
                )
    )
  
    ;---- AT THE END I WANT TO MINIMIZE THIS WAITING TIMER
    (:process increasing_mover_waiting_time
        :parameters (?m - mover  ?c - crate )
        :precondition (and 
                        (crate_light_delivering ?c ?m)
                        (mover_waiting_for_free_loadingbay ?m)
                        
                        (= (timer_waiting_for_free_loadingbay ?m) 0)
                        
                    )  
        :effect (and (increase (timer_waiting_for_free_loadingbay ?m) #t))
    )
   
    ; PUTTING DOWN THE CRATE IF LOADING BAY HAS ONE FREE SPOT
    ; If the loading bay is free, the mover puts down the crate

    (:action put_down_light
        :parameters (?m - mover ?load - loader ?load2 - loader ?c - crate  ?l - loading_bay)
        :precondition (and 
                        ; I have put two loader-free because the problem says that the mover can't put anything in the loading bay until
                        ; the loader has finisched its task. I imagined this reasonment for two loader.
                        (loader_free ?load) 
                        
                        (crate_light_delivering ?c ?m)
                        (mover_waiting_for_free_loadingbay ?m)
                        ( = (loading_has_crate ?l) 0) ; if it is full the mover has to wait till this condition is verified
                    )
        :effect (and  (crate_light_delivered ?c) 
                      (increase (loading_has_crate ?l) 1) 
                      (not(mover_busy ?m)) 
                      (not(mover_waiting_for_free_loadingbay ?m)) 
                      ( assign (timer_waiting_for_free_loadingbay ?m) 0)
                    )
    )

    (:action put_down_heavy
        :parameters (?m1 - mover ?m2 - mover ?load - loader ?c - crate ?l - loading_bay)
        :precondition (and 
                         ; -----It is enough that only one loader is free for putting a crate on the loading_bay ? -----;
                        (loader_free ?load) 
                        
                        (crate_heavy_delivering ?c ?m2)
                        (crate_heavy_delivering ?c ?m1)
                        (mover_waiting_for_free_loadingbay ?m1)
                        (mover_waiting_for_free_loadingbay ?m2)
                        
                        ; probably I don't need ?l in this parameter
                        ( < (loading_has_crate ?l) 2)
                    )
        :effect (and (crate_heavy_delivered ?c) 
                    (increase (loading_has_crate ?l) 1) 
                    (not(mover_busy ?m1)) (not(mover_busy ?m2)) 
                    (not(mover_waiting_for_free_loadingbay ?m1)) 
                    (not(mover_waiting_for_free_loadingbay ?m2)) ; MAYBE I NEED ONLY ONE PUT DOWN
                    (assign (timer_waiting_for_free_loadingbay ?m1) 0)
                    (assign (timer_waiting_for_free_loadingbay ?m2) 0)
                 )
    )
    
    ;---------- LOADERS -----------;

    ; The loader pick up the crate from the loading bay
    (:action load_light
        :parameters (?load - loader ?c - crate ?l - loading_bay)
        :precondition (and 
                        
                        (loader_free ?load)
                        (crate_light_delivered ?c)
                        (= (timer_loading_crate ?c ?load) 0)
                        
                        (<(weight_crate ?c) 50)
                    )
        :effect (and   (not(loader_free ?load))
                        (decrease (loading_has_crate ?l) 1)
                )
    )

    (:action load_haevy
        :parameters (?load - strong_loader   ?c - crate ?l - loading_bay)
        :precondition (and (loader_free ?load)
                           (= (timer_loading_crate ?c ?load) 0)
                           (crate_heavy_delivered ?c)
                           (>=(weight_crate ?c) 50)
                    )
        :effect (and (not(loader_free ?load))
                    (decrease (loading_has_crate ?l) 1)
                    )
    )
    
    ;PROCESS FOR MOVING THE CRATE ON THE CONVEYOR belt
    (:process p-unload-light-crate
        :parameters (?load - loader ?c - crate )
        :precondition (and 
                        (crate_light_delivered ?c )
                        (not(loader_free ?load))
                        
                        (< (weight_crate ?c) 50)
                        (= (timer_loading_crate ?c ?load) 0)
                    )  
        :effect (and (increase (timer_loading_crate ?c ?load) #t))
    )

     ;PROCESS FOR MOVING THE CRATE ON THE CONVEYOR belt
    (:process p-unload-heavy-crate
        :parameters (?load - strong_loader ?c - crate )
        :precondition (and 
                        (crate_heavy_delivered ?c )
                        (not(loader_free ?load))
                        
                        
                        (> (weight_crate ?c) 50)
                        (= (timer_loading_crate ?c ?load) 0)
                    )  
        :effect (and (increase (timer_loading_crate ?c ?load) #t))
    )
    

    ; The loader put down the crate on the conveyor belt
    (:event e-unload-light-crate
        :parameters (?load - loader  ?c - crate)
        :precondition (and(not(loader_free ?load))
                      (>= (timer_loading_crate ?c ?load) 4)
                    )
        :effect (and                                                                ; NB I have put this right now beceause in this way the mover sees an free spot 
                    (loader_free ?load)                                         ;only when a loader has finisched its task!!!!!! 
                    (at-destination-crate ?c) ; I need this for the final goal
                    (assign (timer_loading_crate ?c ?load) 0)
        )
    )

    ; The loader put down the crate on the conveyor belt
    (:event e-unload-heavy-crate
        :parameters (?load - loader  ?c - crate)
        :precondition (and (not(loader_free ?load))
                            (=(timer_loading_crate ?c ?load) 4)
                    )
        :effect (and 
                    (loader_free ?load)  
                    (at-destination-crate ?c) ; I need this for the final goal
                    (assign (timer_loading_crate ?c ?load) 0)
    )
   )
)
