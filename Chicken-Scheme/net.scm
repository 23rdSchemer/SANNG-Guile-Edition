;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                :TANNG:                ;;
;;The Artificial Neural Network Generator;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Copyright (C) 2014-15 Sam Findler

;This program is free software; you can redistribute it and/or
;modify it under the terms of the GNU General Public License
;as published by the Free Software Foundation; either version 2
;of the license, or (at your option) any later version.

;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.

;You should have received a copy of the GNU General Public License
;along with this program; if not, write to the Free Software
;Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-13101, USA.

(module S.A.N.N.G.
	

;;These Functions build the ANN. Ultimately only make-net/n should be used where the arity n is the number of layers and each input is the number of nodes in the layer.
(define-syntax make-nodes
	(syntax-rules ()
		[(_ a b ...) (list (make-vector a 0) (make-vector b 0) ...)]))
(define (make-connections net)
	(let rec ((temp-net net) 
			(connections '()))
		(if (eq? (cdr temp-net) '()) (reverse connections)
			(rec (cdr temp-net) (cons (connect-row (car temp-net) (cadr temp-net)) connections)))))
(define (connect-row input output)
	(let rec ((in input) (connections '()) (count 0) (len (vector-length output)))
		(if (eq? len count) (reverse connections)
			(rec  in (cons (connect-node in) connections) (+ count 1) len))))
(define (connect-node input)
	(let rec ((vec (make-vector (vector-length input) 0)) (count 0) (len (vector-length input)))
		(if (eq? count len) vec
			(begin (vector-set! vec count (random))
				(rec vec (+ count 1) len)))))
(define-syntax make-net
	(syntax-rules ()
	 [(_ a b ...) 
			(let ((x (make-nodes a b ...)))
				(vector x (make-connections x)))]))


;;These functions activate the ANN.  Only initialize-net/2 should be used.  It's input is an empty ANN (produced by make-net/n) and an input vector.
(define (initialize-net network input)
	(let rec ((nodes (cons input (cdr (vector-ref network 0)))) (connections (vector-ref network 1)) (activated-nodes (cons input '())))
		(if (eq? (cdr nodes) '()) (vector (reverse activated-nodes) (vector-ref network 1))
			(rec (cdr nodes) (cdr connections) (cons (activate-row (car nodes) (cadr nodes) (car connections)) activated-nodes)))))
(define (activate-row input output connections)
	(let rec ((in input) (newout output) (connect connections) (count 0))
		(if (eq? count (vector-length output)) newout
			(begin  (vector-set! newout count (activate-node input (car connect)))
				(rec in newout (cdr connect) (+ count 1))))))
(define (activate-node input connections)
	(let rec ((count 0) (in input) (connect connections) (num 0))
		(if (eq? (vector-length input) count) num
				(rec (+ count 1) in connect (+ num (* (vector-ref in count) (vector-ref connect count)))))))


;;These functions are utilities for calculating errors and sigmoids.  Mean Square Error (MSE) is used here, but it can easily be changed to RMS or another error calculation.
(define (output network)
	(let rec ((net network))
		(if (eq? (cdr net) '()) (car net)
			(rec (cdr net)))))
(define (MSE network ideal-output)
	(let rec ((out (output network)) (errsum 0) (count 0))
		(if (eq? count (vector-length out)) (/ errsum (vector-length out))
			(begin (set! errsum (+ errsum (expt (- (vector-ref ideal-output count) (vector-ref out count)) 2)))
				(rec out errsum (+ count 1))))))
(define (sigmoid x)
	(/ 1.0 (+ 1.0 (exp x))))
(define (sigmoid-prime x)
	(* (sigmoid x) (- 1.0 (sigmoid x))))


;;These functions are utilities for calculating output-deltas.
(define (output-delta weights-sum error)
	(* (- error) (sigmoid-prime weights-sum)))
(define (output-deltas connections nodes ideal)
	(let rec ((count 0) (connect connections) (n nodes) (deltas (make-vector (vector-length nodes))))
		(if (eq? count (vector-length nodes)) deltas
			(begin (vector-set! deltas count (output-delta (sum-weights (car connect)) (- (vector-ref ideal count) (vector-ref n count))))
				(rec (+ count 1) (cdr connect) n deltas)))))
(define (sum-weights vec)
	(let rec ((count 0) (sum 0))
		(if (eq? count (vector-length vec)) sum
				(rec (+ count 1) (+ sum (vector-ref vec count))))))
(define (calculate-deltas network ideal)
	(let rec ((connections (reverse (vector-ref network 1)))(nodes (reverse (vector-ref network 0)))(deltas '()))
		(cond ((eq? deltas '()) (begin (set! deltas (cons (output-deltas (car connections) (car nodes) ideal) deltas))
							(rec connections (cdr nodes) deltas)))
			((eq? (cdr connections) '()) deltas)
			(else (begin (set! deltas (cons  (interior-delta-row (car connections) (cadr connections) (car nodes) (car deltas)) deltas))
					(rec (cdr connections) (cdr nodes) deltas)))))) 
(define (interior-delta-row connections-out connections-in nodes last-deltas)
	(let rec ((count 0) (connect connections-in) (n nodes) (deltas (make-vector (vector-length nodes))))
		(if (eq? count (vector-length n)) deltas
			(begin (vector-set! deltas count (interior-delta (sum-weights (car connect))  connections-out last-deltas))
				(rec (+ count 1) (cdr connect) n deltas)))))
(define (interior-delta sum connections-out last-deltas)
	(* (sigmoid-prime sum) 
		(let rec ((count 0) (del last-deltas) (x 0)(connect connections-out))
			(if (eq? count (vector-length del)) x
				(begin (set! x (+ x (* (vector-ref del count) (vector-ref (car connect) count))))
					(rec (+ count 1) del x (cdr connect)))))))


;;These functions are utilities for calculating gradients.  Notice that two global variables are used to specify the learning-rate and momentum, this could be changed and made a parameter of the functions.
(define (calculate-gradients activated-network deltas)
	(let rec ((temp-net (vector-ref activated-network 0)) (d deltas)
			(gradients '()))
		(if (eq? (cdr temp-net) '()) (reverse gradients)
			(rec (cdr temp-net) (cdr d) (cons (gradient-row (car temp-net) (cadr temp-net) (car d)) gradients)))))
(define (gradient-row input output deltas)
	(let rec ((in input) (gradients '()) (count 0) (len (vector-length output)))
		(if (eq? len count) (reverse gradients)
			(rec  in (cons (node-gradients in (vector-ref deltas count)) gradients) (+ count 1) len))))
(define (node-gradients input delta)
	(let rec ((in input) (count 0) (len (vector-length input)) (gradients (make-vector (vector-length input))))
		(if (eq? count len) gradients
			(begin (vector-set! gradients count (* delta (vector-ref input count)))
				(rec in (+ count 1) len gradients)))))
(define (adjustments gradients previous-adj)
	(let rec ((grad gradients) (p previous-adj) (adj '()))
		(if (eq? grad '()) (reverse adj)
			(rec (cdr grad) (cdr p) (cons (adjust-row (car grad) (car p)) adj)))))
(define (adjust-row gradients previous-adj)
	(let rec ((grad gradients) (p previous-adj) (adj '()))
		(if (eq? grad '()) (reverse adj)
			(rec (cdr grad) (cdr p) (cons (adjust-one (car grad) (car p)) adj)))))

;;Important Note: fn uses global variables *leraning-rate* and *momentum*!
;;They default to 0.5 and 0.5, but you can change them with set!.
(define (adjust-one gradients previous-adj)
	(let rec ((grad gradients) (p previous-adj) (count 0) (vec (make-vector (vector-length previous-adj))))
		(if (eq? count (vector-length gradients)) vec
			(begin (vector-set! vec count (+ (* (vector-ref grad count) *learning-rate*) (* (vector-ref p count) *momentum*)))
				(rec grad p (+ count 1) vec)))))




;;These functions train the neural net by back-propogation.  Only train-net/4 should be used.  It's inputs are:
;; 1. the neural net to be trained;
;; 2. the input to the neural net;
;; 3. the ideal-output of the neural-network; and
;; 4. the ideal MSE of the neural-network.
;;If you change from MSE to RMS, be sure to change the function here.  It only occurs once.
(define (train-net net input ideal-out ideal-MSE)
	(begin (set! *previous-adj* (padj (vector-ref net 1)))
		(let ((test (train net input ideal-out ideal-MSE 30)))
			(if test test
				net))))

;does error-checking, if net does not converge in 30 iterations it will probably diverge, so in such a case, the net returns #f and the original net is returned
(define (train net input ideal-out ideal-MSE count)
	(let* ((i-net (initialize-net net input)) (err (MSE (vector-ref i-net 0) ideal-out)))
		(if (eq? count 0) #f
				(begin  (display err) (newline)
					(if (< err ideal-MSE) i-net
					(train (iterate i-net ideal-out) input ideal-out ideal-MSE (- count 1)))))))
(define (iterate net ideal)
	(let ((adjs (adjustments (calculate-gradients net (calculate-deltas net ideal)) *previous-adj*)))
		(begin (vector-set! net 1 (change-weights (vector-ref net 1) adjs))
			(set! *previous-adj* adjs)
			net)))
(define (change-weights connects adjs)
	(let rec ((c connects) (a adjs) (d '()))
		(if (eq? c '()) (reverse d)
			(rec (cdr c) (cdr a) (cons (ch-weights (car c) (car a)) d)))))
(define (ch-weights conn adj)
	(let rec ((c conn) (a adj) (d '()))
		(if (eq? c '()) (reverse d)
			(rec (cdr c) (cdr a) (cons (ch (car c) (car a)) d)))))
(define (ch co ad)
	(let rec ((c co) (a ad) (count 0) (d (make-vector (vector-length co))))
		(if (eq? count (vector-length co)) d
			(begin (vector-set! d count (- (vector-ref c count) (vector-ref a count)))
				(rec c a (+ count 1) d)))))


;;utility for retrieving the output of a neural network
(define (out net)
	(let rec ((net (vector-ref net 0)))
		(if (eq? (cdr net) '()) (car net)
			(rec (cdr net)))))


;;These functions set the initial *previous-adjs* global var to 0
(define (padj connections)
	(let rec ((c connections) (p '()))
		(if (eq? c '()) (reverse p)
			(rec (cdr c) (cons (pad (car c)) p)))))
(define (pad con)
	(let rec ((c con) (p '()))
		(if (eq? c '()) (reverse p)
			(rec (cdr c) (cons (make-vector (vector-length (car c)) 0) p))))) 


;;Function for running though lists of inputs and outputs, gradually reduces ideal-MSE for each input output-pair
(define (run-net input-list output-list network initial-ideal-MSE)
	(let rec ((in input-list) (out output-list) (net network) (ideal-MSE initial-ideal-MSE) (count 0) (count2 0))
		(let ((trained (train-net net (car in) (car out) ideal-MSE)))
			(cond ((eq? (cdr in) '()) trained)
				((and (eq? count2 0) (eq? (vector-ref trained 0) (vector-ref network 0)) (eq? count 10)) (display "Error, current network configuration will not converge"))
				((and (eq? count2 0) (eq? (vector-ref trained 0) (vector-ref network 0))) (rec in out (randomize-connects net) ideal-MSE (+ count 1) 0))
				(else (rec (cdr in) (cdr out) trained (- ideal-MSE *step-down*) count 1))))))

;;if net does not converge on first runthrough, the connections are randomized again, to see if the new configuration will work
(define (randomize-connects net)
	(let ((nodes (vector-ref net 0)))
		(vector nodes (make-connections nodes))))


;;utilities for normalizing input/ideal output data
(define (normalize x datamax datamin rangemax rangemin)
	(if (eq? datamax datamin) (/ (- rangemax rangemin) x)
		(+ (/ (* (- x datamin) (- rangemax rangemin)) (- datamax datamin)) rangemin)))
(define (denormalize x datamax datamin rangemax rangemin)
	(if (eq? datamax datamin) (/ (- rangemax rangemin) x)
		(/ (+ (- (* (- datamin datamax) x) (* datamin rangemax)) (* datamax rangemin)) (- rangemin rangemax))))
(define (normalize-vec-list lst)
	(let rec ((lst lst) (catcher '()))
		(if (eq? lst '()) (reverse catcher)
			(rec (cdr lst) (cons (normalize-vec (car lst)) catcher)))))
(define (normalize-vec vec)
	(vector-map (lambda (x) (normalize x (apply max (vector->list vec)) (apply min (vector->list vec)) 1 0)) vec))
(define (denormalize-vec-list lst datamax datamin)
	(let rec ((lst lst) (catcher '()))
		(if (eq? lst '()) (reverse catcher)
			(rec (cdr lst) (cons denormalize-vec (car lst) datamax datamin) catcher))))
(define (denormalize-vec vec datamax datamin)
	(vector-map (lambda (x) (denormalize x datamax datamin 1 0)) vec))
(define (run-normalized input-list output-list network initial-ideal-MSE) 
	(run-net (normalize-vec-list input-list) (normalize-vec-list output-list) network initial-ideal-MSE))



;;ngo is a function that takes a training-set (a list containing a list of inputs followed by a list of ideal-outputs), a network (i.e. nodes + connections), an initial ideal MSE and an input to use with the trained net.
;;it normalizes/trains the net with the training set, gradually decreasing the ideal-MSE by *step-down*, and outputs a vector with the denormalized predicted output of the vector
;;it will normally look something like:  (ngo '(list-of-inputs list-of-outputs) (make-net ...) (number between 0.2 and 0.5) input-vector) 
;;if your output is already between 0 and 1 or -1 and 1, use go instead
(define (ngo training-set network ideal-MSE input) 
			(let ([x (run-normalized (car training-set) (cadr training-set) network ideal-MSE)])
				(dno x input)))

;;dno (denormalized-output is a way to get the denormalized output of a net run through with one input.
(define dno (network input)
	(let   ([maximum (apply max (vector->list input))]
		[minimum (apply min (vector->list input))]
		[output (out (initialize-net network (normalize-vec input)))])
		(denormalize-vec output maximum minimum)))


;;note:  run-normalized is useful if you want to save a neural net for future updates and outputs:
;;For example:
;;for some training-set and network, we could declare 
;;(define network_2 (run-normalized (car training-set) (cadr training-set) network ideal-MSE))
;;then later call (run-normalized (car training-set-2) (cadr training-set-2) network_2 ideal-MSE) and train the net some more

;;We can then combine run-normalized with dno and get a sort of delayed and reusable ngo
;;for example if we run (de-normalized-output network_2 input) for some input, it would be as if we initially ran
;;(ngo training-set network ideal-MSE input), but it can be useful to split these processes up and to be able to save a trained neural network


;;Default starting values for global variables
(define *learning-rate* 0.5) ;used in back-propagation
(define *momentum* 0.7) ;used in back-propagation
(define *previous-adj* 0) ;this is actually calculated, but it must first be declared
(define *step-down* 0) ;this is how much the ideal-MSE is stepped down after each input training, as your training set grows, this should decrease, or else it will go bellow zero. 
				;for extremely large training sets, this should be set to zero.
)
